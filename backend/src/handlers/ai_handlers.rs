use axum::{extract::State, http::StatusCode, Json};
use std::sync::Arc;

use crate::{
    handlers::AiState,
    models::{
        AiCommandRequest, AiCommandResponse, VariantConfirmationRequest, VariantSelectionActionData,
    },
    services::CommandExecutor,
};

/// Process AI Command
/// POST /api/ai/command
pub async fn process_ai_command(
    State(ai_state): State<Arc<AiState>>,
    Json(payload): Json<AiCommandRequest>,
) -> Result<Json<AiCommandResponse>, StatusCode> {
    // tracing::info!("AI Command: '{}'", payload.prompt);

    // Step 1: Parse user command using Local LLM
    let command = match ai_state
        .ai_service
        .parse_user_command(&payload.prompt)
        .await
    {
        Ok(cmd) => cmd,
        Err(e) => {
            tracing::error!("Failed to parse command: {}", e);

            // Check if this is a simple greeting and provide a friendly response
            let lower_prompt = payload.prompt.to_lowercase();
            if lower_prompt.contains("hello")
                || lower_prompt.contains("hi")
                || lower_prompt.contains("hey")
            {
                let greeting_response = AiCommandResponse {
                    success: true,
                    message: "Hello! I'm here to help you with your order. You can ask me to add items to your cart, show the menu, or help with anything else!".to_string(),
                    actions_executed: vec!["greeting_response".to_string()],
                    error: None,
                    emotion: "happy".to_string(),
                };
                return Ok(Json(greeting_response));
            }

            let error_response = AiCommandResponse {
                success: false,
                message: "Sorry, I couldn't understand that command. Try saying something like 'show menu' or 'add pizza to cart'.".to_string(),
                actions_executed: Vec::new(),
                error: Some(e),
                emotion: "upset".to_string(),
            };
            return Ok(Json(error_response));
        }
    };

    // Step 2: Execute the command (with queue-based processing)
    let executor = CommandExecutor::new(ai_state.db.clone(), ai_state.queue_service.clone());
    let result = executor
        .execute_command(command, payload.session_id.as_deref(), payload.customer_id)
        .await;

    if !result.success {
        tracing::error!("Command execution failed: {}", result.message);
        return Ok(Json(AiCommandResponse {
            success: false,
            message: result.message.clone(),
            actions_executed: result.actions_executed,
            error: Some("Command execution failed".to_string()),
            emotion: "upset".to_string(),
        }));
    }

    // Check if there are pending variant selections
    if !result.pending_variant_selections.is_empty() {
        println!(
            "[INFO] {} variant selections pending",
            result.pending_variant_selections.len()
        );

        // SEQUENTIAL ORCHESTRATION: Always return only the FIRST product
        // The command_executor has already queued the remaining products
        let first_variant_response = &result.pending_variant_selections[0];

        // Check if this is a sequential selection (has queue_info)
        let has_queue_info = if let Some(data) = &first_variant_response.data {
            if let Ok(selection_data) =
                serde_json::from_value::<VariantSelectionActionData>(data.clone())
            {
                selection_data.queue_info.is_some()
            } else {
                false
            }
        } else {
            false
        };

        if has_queue_info {
            println!("[INFO] Sequential orchestration detected - returning first product with queue info");
        } else {
            println!("[INFO] Single product variant selection");
        }

        // Return the first (or only) variant selection
        let variant_response = AiCommandResponse {
            success: true,
            message: first_variant_response.message.clone(),
            actions_executed: vec![
                serde_json::to_string(first_variant_response).unwrap_or_default()
            ],
            error: None,
            emotion: "normal".to_string(),
        };

        return Ok(Json(variant_response));
    }

    // Step 3: Generate confirmation message using Local LLM (only if no variant selections)
    let confirmation = match ai_state
        .ai_service
        .generate_confirmation_message(&result.actions_executed, &payload.prompt)
        .await
    {
        Ok(msg) => msg,
        Err(e) => {
            tracing::warn!("Failed to generate confirmation: {}", e);
            // Fallback to a simple confirmation
            format!("Done! {}", result.actions_executed.join(", "))
        }
    };

    println!(
        "[OK ] Command executed: {} actions, confirmation: '{}'",
        result.actions_executed.len(),
        confirmation
    );

    let success_response = AiCommandResponse {
        success: true,
        message: confirmation,
        actions_executed: result.actions_executed,
        error: None,
        emotion: "happy".to_string(),
    };

    Ok(Json(success_response))
}

/// Variant Confirmation Endpoint - Handle frontend confirmations
/// POST /api/ai/variant-confirm
pub async fn confirm_variant_selection(
    State(ai_state): State<Arc<AiState>>,
    Json(payload): Json<VariantConfirmationRequest>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    let queue_id = format!(
        "{}_{}",
        payload.session_id.as_deref().unwrap_or("anonymous"),
        payload.customer_id.unwrap_or(0)
    );

    // Check if queue exists and is locked
    let is_locked = ai_state.queue_service.is_locked(&queue_id).unwrap_or(false);
    let has_pending = ai_state
        .queue_service
        .has_pending(&queue_id)
        .unwrap_or(false);
    let _pending_count = ai_state.queue_service.pending_count(&queue_id).unwrap_or(0);

    if !is_locked && !has_pending {
        return Ok(Json(serde_json::json!({
            "success": false,
            "message": "No active queue found",
            "has_more": false,
            "error": "Queue not found or expired"
        })));
    }

    match payload.status.as_str() {
        "success" => {
            // 1. Validate the confirmation (frontend handles cart addition like single variant)
            if payload.variant_id.is_none() {
                println!("[ERROR] No variant_id provided in confirmation");
                return Ok(Json(serde_json::json!({
                    "success": false,
                    "message": "No variant selected",
                    "has_more": false,
                    "error": "Missing variant_id"
                })));
            }

            println!(
                "[INFO] Confirmed variant {} for {} - frontend will add to cart",
                payload.variant_id.unwrap(),
                payload.product_name
            );

            // 2. Clear current action
            ai_state
                .queue_service
                .clear_current_action(&queue_id)
                .unwrap_or_default();

            // 3. Check if more items in queue
            if let Some(next_queued_action) = ai_state
                .queue_service
                .pop_next_action(&queue_id)
                .unwrap_or(None)
            {
                // 4. Fetch variants for next product
                println!(
                    "[INFO] Next product in queue: {}",
                    next_queued_action.product_name
                );

                // Get product ID by name using search
                println!(
                    "[DEBUG] Searching for product: '{}'",
                    next_queued_action.product_name
                );
                let search_results = match ai_state
                    .db
                    .products()
                    .search_products(&next_queued_action.product_name, 0, 1)
                    .await
                {
                    Ok(products) => {
                        println!("[DEBUG] Search returned {} products", products.len());
                        products
                    }
                    Err(e) => {
                        println!("[ERROR] Search failed: {}", e);
                        return Ok(Json(serde_json::json!({
                            "success": false,
                            "message": format!("Error finding product: {}", e),
                            "has_more": false,
                            "error": "Database error"
                        })));
                    }
                };

                let product_id = match search_results.first() {
                    Some(product) => product.product_id,
                    None => {
                        return Ok(Json(serde_json::json!({
                            "success": false,
                            "message": format!(
                                "Product '{}' not found",
                                next_queued_action.product_name
                            ),
                            "has_more": false,
                            "error": "Product not found"
                        })));
                    }
                };

                // Fetch product variations
                println!("[DEBUG] Fetching variations for product_id: {}", product_id);
                let variations = match ai_state
                    .db
                    .products()
                    .fetch_product_variations(product_id)
                    .await
                {
                    Ok(variants) => {
                        println!("[DEBUG] Found {} variations", variants.len());
                        for (i, variant) in variants.iter().enumerate() {
                            println!(
                                "[DEBUG] Variant {}: id={}, name='{}', price={}",
                                i, variant.variant_id, variant.variant_name, variant.sell_price
                            );
                        }
                        variants
                    }
                    Err(e) => {
                        println!("[ERROR] Failed to fetch variations: {}", e);
                        return Ok(Json(serde_json::json!({
                            "success": false,
                            "message": format!("Error fetching variants: {}", e),
                            "has_more": false,
                            "error": "Variant fetch error"
                        })));
                    }
                };

                // 5. Create next variant selection response
                let remaining_count = ai_state.queue_service.pending_count(&queue_id).unwrap_or(0);
                let current_position = remaining_count + 2; // +2 because we're now on the next item

                // Convert variations to ProductVariant format
                println!(
                    "[DEBUG] Converting {} variations to ProductVariant format",
                    variations.len()
                );
                let available_variants: Vec<crate::models::ProductVariant> = variations
                    .into_iter()
                    .map(|v| {
                        let variant = crate::models::ProductVariant {
                            variant_id: v.variant_id,
                            variant_name: v.variant_name,
                            sell_price: v.sell_price.to_string().parse::<f64>().unwrap_or(0.0),
                            stock: v.stock,
                            attributes: None, // ProductVariation doesn't have attributes field
                        };
                        println!(
                            "[DEBUG] Converted variant: id={}, name='{}', price={}, stock={}",
                            variant.variant_id,
                            variant.variant_name,
                            variant.sell_price,
                            variant.stock
                        );
                        variant
                    })
                    .collect();

                println!(
                    "[DEBUG] Created {} available_variants",
                    available_variants.len()
                );

                // Create the variant selection data with queue info
                println!(
                    "[DEBUG] Creating VariantSelectionActionData with {} variants",
                    available_variants.len()
                );
                let variant_data = VariantSelectionActionData {
                    product_id,
                    product_name: next_queued_action.product_name.clone(),
                    quantity: next_queued_action.quantity,
                    session_id: next_queued_action.session_id.clone(),
                    customer_id: next_queued_action.customer_id,
                    available_variants,
                    queue_info: Some(serde_json::json!({
                        "position": current_position,
                        "total": remaining_count + 1,
                        "remaining": ai_state.queue_service.get_remaining_products(&queue_id).unwrap_or_default()
                    })),
                };

                println!("[DEBUG] Created variant_data: product_id={}, product_name='{}', variants_count={}", 
                    variant_data.product_id, variant_data.product_name, variant_data.available_variants.len());

                // Create the exact format expected by frontend (matching command_executor.rs)
                let next_action = serde_json::json!({
                    "action_type": "variant_selection",
                    "data": variant_data
                });

                let action_string = serde_json::to_string(&next_action).unwrap_or_default();
                println!(
                    "[DEBUG] Serialized action string length: {}",
                    action_string.len()
                );
                println!(
                    "[DEBUG] FULL JSON being sent to frontend: {}",
                    action_string
                );

                // Create the response in the format frontend expects
                // Frontend looks for: has_more, next_action, message, success
                let response_json = serde_json::json!({
                    "success": true,
                    "message": format!(
                        "{} added! Now select variant for {} ({} of {} items)",
                        payload.product_name,
                        next_queued_action.product_name,
                        current_position,
                        remaining_count + 1
                    ),
                    "has_more": true,
                    "next_action": next_action
                });

                println!(
                    "[DEBUG] Final response: has_more=true, message='{}'",
                    response_json.get("message").unwrap().as_str().unwrap()
                );

                return Ok(Json(response_json));
            } else {
                // Queue empty - all done!
                ai_state
                    .queue_service
                    .clear_queue(&queue_id)
                    .unwrap_or_default();

                return Ok(Json(serde_json::json!({
                    "success": true,
                    "message": "All items added to cart successfully!",
                    "has_more": false
                })));
            }
        }

        "cancel" | "timeout" => {
            // User cancelled - clear entire queue
            ai_state
                .queue_service
                .clear_queue(&queue_id)
                .unwrap_or_default();

            return Ok(Json(serde_json::json!({
                "success": false,
                "message": "Action cancelled. Queue cleared.",
                "has_more": false,
                "error": "User cancelled"
            })));
        }

        _ => {
            return Ok(Json(serde_json::json!({
                "success": false,
                "message": "Invalid status",
                "has_more": false,
                "error": "Invalid status value"
            })));
        }
    }
}

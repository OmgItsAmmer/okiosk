use crate::{
    database::Database,
    models::{
        Action, ActionResponse, CartActionData, CartSummaryActionData, CheckoutCartItem, Command,
        CommandResult, MenuActionData, OrderTotals, ProductSearchActionData, ProductSearchResult,
        ProductVariant, QueuedAction, VariantSelectionActionData,
    },
    services::QueueService,
};
use rust_decimal::Decimal;
use serde_json::json;
use sha2::{Digest, Sha256};
use sqlx::Row;
use std::sync::Arc;

/// Command Executor - Executes parsed commands
pub struct CommandExecutor {
    db: Arc<Database>,
    queue_service: Arc<QueueService>,
}

impl CommandExecutor {
    pub fn new(db: Arc<Database>, queue_service: Arc<QueueService>) -> Self {
        Self { db, queue_service }
    }

    /// Execute a command with multiple actions (Sequential Queue Orchestration)
    pub async fn execute_command(
        &self,
        command: Command,
        session_id: Option<&str>,
        customer_id: Option<i32>,
    ) -> CommandResult {
        let mut result = CommandResult::default();
        let mut completed_actions: Vec<String> = Vec::new();
        let mut variant_selections: Vec<ActionResponse> = Vec::new();

        // When user sends a new add_to_cart, clear any pending variant queue (user moved on)
        let has_add_to_cart = command.actions.iter().any(|a| {
            matches!(a, Action::AddToCart { .. })
        });
        if has_add_to_cart {
            let queue_id = format!(
                "{}_{}",
                session_id.unwrap_or("anonymous"),
                customer_id.unwrap_or(0)
            );
            let _ = self.queue_service.clear_queue(&queue_id);
        }

        // Process all actions and separate them into completed vs variant selections
        for action in command.actions {
            match self.execute_action(action, session_id, customer_id).await {
                Ok(action_response_json) => {
                    // Deserialize to check if it's a variant selection
                    let action_response: ActionResponse =
                        match serde_json::from_str(&action_response_json) {
                            Ok(resp) => resp,
                            Err(e) => {
                                result.success = false;
                                result.message = format!("Failed to parse action response: {}", e);
                                return result;
                            }
                        };

                    // Check if this is a variant selection action
                    if action_response.action_type == Some("variant_selection".to_string()) {
                        variant_selections.push(action_response);
                    } else {
                        completed_actions.push(action_response_json);
                    }
                }
                Err(e) => {
                    result.success = false;
                    result.message = e;
                    return result;
                }
            }
        }

        // SEQUENTIAL ORCHESTRATION: Handle multiple variant selections differently
        if !variant_selections.is_empty() {
            if variant_selections.len() == 1 {
                // Single item - return immediately (existing behavior)
                result.success = true;
                result.pending_variant_selections = variant_selections;
                let completed_count = completed_actions.len();
                result.actions_executed = completed_actions;
                result.message = format!(
                    "{} action(s) completed. {} item(s) require variant selection.",
                    completed_count,
                    result.pending_variant_selections.len()
                );
            } else {
                // Multiple items - SEQUENTIAL ORCHESTRATION
                // Return ONLY the first product, queue the rest
                let first_variant = variant_selections[0].clone();

                // Create queued actions for remaining products
                let mut queued_actions = Vec::new();
                for i in 1..variant_selections.len() {
                    let variant_data = &variant_selections[i];
                    if let Some(data) = &variant_data.data {
                        if let Ok(selection_data) = serde_json::from_value::<
                            crate::models::VariantSelectionActionData,
                        >(data.clone())
                        {
                            let queued_action = QueuedAction {
                                action_type: "add_to_cart".to_string(),
                                product_name: selection_data.product_name.clone(),
                                quantity: selection_data.quantity,
                                session_id: session_id.map(|s| s.to_string()),
                                customer_id,
                                timestamp: std::time::SystemTime::now()
                                    .duration_since(std::time::UNIX_EPOCH)
                                    .unwrap()
                                    .as_secs() as i64,
                            };
                            queued_actions.push(queued_action);
                        }
                    }
                }

                // Store the queue for this user/session
                let queue_id = format!(
                    "{}_{}",
                    session_id.unwrap_or("anonymous"),
                    customer_id.unwrap_or(0)
                );

                // Create remaining product names list before moving queued_actions
                let remaining_products: Vec<String> = queued_actions
                    .iter()
                    .map(|a| a.product_name.clone())
                    .collect();

                if let Err(e) = self
                    .queue_service
                    .create_queue(queue_id.clone(), queued_actions)
                {
                    tracing::error!("Failed to create queue '{}': {}", queue_id, e);
                }

                // Add queue info to the first variant response
                let mut first_variant_with_queue = first_variant.clone();
                if let Some(data) = &mut first_variant_with_queue.data {
                    if let Ok(mut selection_data) = serde_json::from_value::<
                        crate::models::VariantSelectionActionData,
                    >(data.clone())
                    {
                        // Add queue information
                        let queue_info = serde_json::json!({
                            "position": 1,
                            "total": variant_selections.len(),
                            "remaining": remaining_products
                        });
                        selection_data.queue_info = Some(queue_info);

                        // Update the data in the response
                        *data = serde_json::to_value(&selection_data).unwrap_or_default();
                    }
                }

                // Return only the first variant with queue info
                result.success = true;
                result.pending_variant_selections = vec![first_variant_with_queue];
                let completed_count = completed_actions.len();
                result.actions_executed = completed_actions;
                result.message = format!(
                    "{} action(s) completed. Please select variant for {} (1 of {} items)",
                    completed_count,
                    if let Some(data) = &result.pending_variant_selections[0].data {
                        if let Ok(selection_data) = serde_json::from_value::<
                            crate::models::VariantSelectionActionData,
                        >(data.clone())
                        {
                            selection_data.product_name
                        } else {
                            "item".to_string()
                        }
                    } else {
                        "item".to_string()
                    },
                    variant_selections.len()
                );
            }
        } else {
            // All actions completed successfully
            result.success = true;
            result.actions_executed = completed_actions;
            result.message = "All actions validated successfully".to_string();
        }

        result
    }

    /// Execute a single action
    async fn execute_action(
        &self,
        action: Action,
        session_id: Option<&str>,
        customer_id: Option<i32>,
    ) -> Result<String, String> {
        let action_response = match action {
            Action::AddToCart {
                item,
                quantity,
                variant_id,
            } => {
                self.validate_add_to_cart(&item, quantity, variant_id, session_id, customer_id)
                    .await?
            }
            Action::RemoveFromCart { item, variant_id } => {
                self.validate_remove_from_cart(&item, variant_id, session_id, customer_id)
                    .await?
            }
            Action::ClearCart => self.validate_clear_cart(session_id, customer_id).await?,
            Action::GenerateBill => self.validate_generate_bill(session_id, customer_id).await?,
            Action::ShowMenu { category } => self.validate_show_menu(category).await?,
            Action::SearchProduct { query } => self.validate_search_product(&query).await?,
            Action::UpdateQuantity {
                item,
                quantity,
                variant_id,
            } => {
                self.validate_update_quantity(&item, quantity, variant_id, session_id, customer_id)
                    .await?
            }
            Action::ViewCart => self.validate_view_cart(session_id, customer_id).await?,
            Action::Checkout {
                payment_method,
                shipping_method,
            } => {
                self.validate_checkout(&payment_method, &shipping_method, session_id, customer_id)
                    .await?
            }
        };

        // Convert ActionResponse to JSON string
        serde_json::to_string(&action_response)
            .map_err(|e| format!("Failed to serialize action response: {}", e))
    }

    /// Validate add to cart action
    async fn validate_add_to_cart(
        &self,
        item: &str,
        quantity: i32,
        variant_id: Option<i32>,
        session_id: Option<&str>,
        customer_id: Option<i32>,
    ) -> Result<ActionResponse, String> {
        // If variant_id is provided, proceed with normal flow
        if let Some(id) = variant_id {
            return self
                .validate_add_to_cart_with_variant(id, quantity, session_id, customer_id)
                .await;
        }

        // Check if the item string contains variant information in format "Product Name (Variant Name)"
        if let Some((product_name, variant_name)) = self.parse_variant_from_item_name(item) {
            return self
                .validate_add_to_cart_with_variant_name(
                    &product_name,
                    &variant_name,
                    quantity,
                    session_id,
                    customer_id,
                )
                .await;
        }

        // If no variant_id provided and no variant parsing, search for product and return variants
        let products = self
            .db
            .products()
            .search_products(item, 0, 5)
            .await
            .map_err(|e| format!("Product search failed: {}", e))?;

        if products.is_empty() {
            return Ok(ActionResponse {
                action_type: Some("add_to_cart".to_string()),
                success: false,
                message: format!("Product '{}' not found", item),
                data: None,
                error: Some("Product not found".to_string()),
            });
        }

        // Get the first matching product TODO: if more products of same name?
        let product = &products[0];
        let product_id = product.product_id;

        // Fetch all variations for this product
        let variations = self
            .db
            .products()
            .fetch_product_variations(product_id)
            .await
            .map_err(|e| format!("Failed to fetch variations: {}", e))?;

        if variations.is_empty() {
            return Ok(ActionResponse {
                action_type: Some("add_to_cart".to_string()),
                success: false,
                message: format!("No variations available for '{}'", item),
                data: None,
                error: Some("No variations available".to_string()),
            });
        }

        // If only one variant, proceed with that variant automatically
        if variations.len() == 1 {
            let variant = &variations[0];
            return self
                .validate_add_to_cart_with_variant(
                    variant.variant_id,
                    quantity,
                    session_id,
                    customer_id,
                )
                .await;
        }

        // Multiple variants found - return variant selection response
        let available_variants: Vec<ProductVariant> = variations
            .into_iter()
            .map(|v| ProductVariant {
                variant_id: v.variant_id,
                variant_name: v.variant_name,
                sell_price: v.sell_price.to_string().parse::<f64>().unwrap_or(0.0),
                stock: v.stock,
                attributes: None, // Can be extended later for size, color, etc.
            })
            .collect();

        Ok(ActionResponse {
            action_type: Some("variant_selection".to_string()),
            success: true,
            message: format!(
                "Product '{}' has {} variants available. Please select a variant.",
                product.name,
                available_variants.len()
            ),
            data: Some(
                serde_json::to_value(VariantSelectionActionData {
                    product_id,
                    product_name: product.name.clone(),
                    quantity,
                    session_id: session_id.map(|s| s.to_string()),
                    customer_id,
                    available_variants,
                    queue_info: None, // Will be set later for sequential orchestration
                })
                .map_err(|e| format!("Failed to serialize variant selection data: {}", e))?,
            ),
            error: None,
        })
    }

    /// Validate and EXECUTE add to cart action with specific variant
    async fn validate_add_to_cart_with_variant(
        &self,
        variant_id: i32,
        quantity: i32,
        session_id: Option<&str>,
        customer_id: Option<i32>,
    ) -> Result<ActionResponse, String> {
        // Get product details for the response
        let (product_name, variant_name, sell_price, stock) = self
            .get_product_details(variant_id)
            .await
            .map_err(|e| format!("Failed to get product details: {}", e))?;

        // Check stock availability
        let can_add = self
            .db
            .cart()
            .can_add_to_cart(variant_id, quantity)
            .await
            .map_err(|e| format!("Stock check failed: {}", e))?;

        if !can_add {
            return Ok(ActionResponse {
                action_type: Some("add_to_cart".to_string()),
                success: false,
                message: format!(
                    "Insufficient stock for {}. Only {} available",
                    product_name, stock
                ),
                data: Some(
                    serde_json::to_value(CartActionData {
                        variant_id,
                        product_name: product_name.clone(),
                        variant_name: variant_name.clone(),
                        quantity,
                        available_stock: stock,
                        sell_price,
                        session_id: session_id.map(|s| s.to_string()),
                        customer_id,
                    })
                    .map_err(|e| format!("Failed to serialize cart data: {}", e))?,
                ),
                error: Some("Insufficient stock".to_string()),
            });
        }

        // PERFORM ACTUAL SAVING
        let is_guest = customer_id == Some(1);
        let save_result = if is_guest {
            // Save locally in guest cart
            let session_key = session_id.unwrap_or("guest_session");
            println!("[COMMAND_EXECUTOR] Guest detected (ID 1), saving to in-memory cart for session: {}", session_key);
            self.queue_service
                .add_to_guest_cart(session_key, variant_id, quantity)
        } else if let Some(cid) = customer_id {
            // Save to database for regular customers
            println!(
                "[COMMAND_EXECUTOR] Regular customer {}, saving to Supabase",
                cid
            );
            self.db
                .cart()
                .add_to_cart(cid, variant_id, quantity)
                .await
                .map(|_| ())
                .map_err(|e| format!("Database error: {}", e))
        } else {
            // No customer ID - fallback to kiosk cart or ignore
            println!("[COMMAND_EXECUTOR] No customer ID provided, skipping DB save");
            Ok(())
        };

        if let Err(e) = save_result {
            return Err(format!("Failed to save to cart: {}", e));
        }

        Ok(ActionResponse {
            action_type: Some("add_to_cart".to_string()),
            success: true,
            message: format!(
                "Successfully added {} {} to your cart",
                quantity, product_name
            ),
            data: Some(
                serde_json::to_value(CartActionData {
                    variant_id,
                    product_name,
                    variant_name,
                    quantity,
                    available_stock: stock,
                    sell_price,
                    session_id: session_id.map(|s| s.to_string()),
                    customer_id,
                })
                .map_err(|e| format!("Failed to serialize cart data: {}", e))?,
            ),
            error: None,
        })
    }

    /// Validate remove from cart action
    async fn validate_remove_from_cart(
        &self,
        item: &str,
        variant_id: Option<i32>,
        session_id: Option<&str>,
        customer_id: Option<i32>,
    ) -> Result<ActionResponse, String> {
        // Get variant_id if not provided
        let variant_id = if let Some(id) = variant_id {
            id
        } else {
            self.search_variant_id(item).await?
        };

        // Get product details for the response
        let (product_name, variant_name, sell_price, stock) = self
            .get_product_details(variant_id)
            .await
            .map_err(|e| format!("Failed to get product details: {}", e))?;

        Ok(ActionResponse {
            action_type: Some("remove_from_cart".to_string()),
            success: true,
            message: format!("Ready to remove {} from cart", product_name),
            data: Some(
                serde_json::to_value(CartActionData {
                    variant_id,
                    product_name,
                    variant_name,
                    quantity: 0, // Not relevant for removal
                    available_stock: stock,
                    sell_price,
                    session_id: session_id.map(|s| s.to_string()),
                    customer_id,
                })
                .map_err(|e| format!("Failed to serialize cart data: {}", e))?,
            ),
            error: None,
        })
    }

    /// Validate clear cart action
    async fn validate_clear_cart(
        &self,
        session_id: Option<&str>,
        customer_id: Option<i32>,
    ) -> Result<ActionResponse, String> {
        Ok(ActionResponse {
            action_type: Some("clear_cart".to_string()),
            success: true,
            message: "Ready to clear cart".to_string(),
            data: Some(
                serde_json::to_value(CartSummaryActionData {
                    session_id: session_id.map(|s| s.to_string()),
                    customer_id,
                    total_items: 0,
                    subtotal: 0.0,
                    items: vec![],
                })
                .map_err(|e| format!("Failed to serialize cart data: {}", e))?,
            ),
            error: None,
        })
    }

    /// Validate generate bill action
    async fn validate_generate_bill(
        &self,
        session_id: Option<&str>,
        customer_id: Option<i32>,
    ) -> Result<ActionResponse, String> {
        Ok(ActionResponse {
            action_type: Some("generate_bill".to_string()),
            success: true,
            message: "Ready to generate bill".to_string(),
            data: Some(
                serde_json::to_value(CartSummaryActionData {
                    session_id: session_id.map(|s| s.to_string()),
                    customer_id,
                    total_items: 0, // Will be calculated by frontend
                    subtotal: 0.0,  // Will be calculated by frontend
                    items: vec![],
                })
                .map_err(|e| format!("Failed to serialize cart data: {}", e))?,
            ),
            error: None,
        })
    }

    /// Validate show menu action
    async fn validate_show_menu(&self, category: Option<String>) -> Result<ActionResponse, String> {
        let products = self
            .db
            .products()
            .fetch_all_products_for_pos()
            .await
            .map_err(|e| format!("Failed to fetch products: {}", e))?;

        let product_results: Vec<ProductSearchResult> = products
            .into_iter()
            .map(|p| ProductSearchResult {
                product_id: p.product_id,
                product_name: p.name,
                variant_id: 0, // Default variant for POS products
                variant_name: "Default".to_string(),
                sell_price: p.sale_price.parse::<f64>().unwrap_or(0.0),
                stock: p.stock_quantity,
            })
            .collect();

        Ok(ActionResponse {
            action_type: Some("show_menu".to_string()),
            success: true,
            message: format!(
                "Menu displayed: {} products available",
                product_results.len()
            ),
            data: Some(
                serde_json::to_value(MenuActionData {
                    category,
                    products: product_results,
                })
                .map_err(|e| format!("Failed to serialize menu data: {}", e))?,
            ),
            error: None,
        })
    }

    /// Validate search product action
    async fn validate_search_product(&self, query: &str) -> Result<ActionResponse, String> {
        let products = self
            .db
            .products()
            .search_products(query, 0, 10)
            .await
            .map_err(|e| format!("Product search failed: {}", e))?;

        let product_results: Vec<ProductSearchResult> = products
            .into_iter()
            .map(|p| ProductSearchResult {
                product_id: p.product_id,
                product_name: p.name,
                variant_id: 0, // Default variant for POS products
                variant_name: "Default".to_string(),
                sell_price: p.sale_price.parse::<f64>().unwrap_or(0.0),
                stock: p.stock_quantity,
            })
            .collect();

        let message = if product_results.is_empty() {
            format!("No products found for '{}'", query)
        } else {
            format!(
                "Found {} products matching '{}'",
                product_results.len(),
                query
            )
        };

        Ok(ActionResponse {
            action_type: Some("search_product".to_string()),
            success: true,
            message,
            data: Some(
                serde_json::to_value(ProductSearchActionData {
                    query: query.to_string(),
                    results: product_results,
                })
                .map_err(|e| format!("Failed to serialize search data: {}", e))?,
            ),
            error: None,
        })
    }

    /// Validate update quantity action
    async fn validate_update_quantity(
        &self,
        item: &str,
        quantity: i32,
        variant_id: Option<i32>,
        session_id: Option<&str>,
        customer_id: Option<i32>,
    ) -> Result<ActionResponse, String> {
        // Get variant_id if not provided
        let variant_id = if let Some(id) = variant_id {
            id
        } else {
            self.search_variant_id(item).await?
        };

        // Get product details for the response
        let (product_name, variant_name, sell_price, stock) = self
            .get_product_details(variant_id)
            .await
            .map_err(|e| format!("Failed to get product details: {}", e))?;

        // Check stock availability
        let can_update = self
            .db
            .cart()
            .can_add_to_cart(variant_id, quantity)
            .await
            .map_err(|e| format!("Stock check failed: {}", e))?;

        if !can_update {
            return Ok(ActionResponse {
                action_type: Some("update_quantity".to_string()),
                success: false,
                message: format!(
                    "Insufficient stock for {}. Only {} available",
                    product_name, stock
                ),
                data: Some(
                    serde_json::to_value(CartActionData {
                        variant_id,
                        product_name: product_name.clone(),
                        variant_name: variant_name.clone(),
                        quantity,
                        available_stock: stock,
                        sell_price,
                        session_id: session_id.map(|s| s.to_string()),
                        customer_id,
                    })
                    .map_err(|e| format!("Failed to serialize cart data: {}", e))?,
                ),
                error: Some("Insufficient stock".to_string()),
            });
        }

        Ok(ActionResponse {
            action_type: Some("update_quantity".to_string()),
            success: true,
            message: format!("Ready to update {} quantity to {}", product_name, quantity),
            data: Some(
                serde_json::to_value(CartActionData {
                    variant_id,
                    product_name,
                    variant_name,
                    quantity,
                    available_stock: stock,
                    sell_price,
                    session_id: session_id.map(|s| s.to_string()),
                    customer_id,
                })
                .map_err(|e| format!("Failed to serialize cart data: {}", e))?,
            ),
            error: None,
        })
    }

    /// Validate view cart action
    async fn validate_view_cart(
        &self,
        session_id: Option<&str>,
        customer_id: Option<i32>,
    ) -> Result<ActionResponse, String> {
        Ok(ActionResponse {
            action_type: Some("view_cart".to_string()),
            success: true,
            message: "Ready to view cart".to_string(),
            data: Some(
                serde_json::to_value(CartSummaryActionData {
                    session_id: session_id.map(|s| s.to_string()),
                    customer_id,
                    total_items: 0, // Will be calculated by frontend
                    subtotal: 0.0,  // Will be calculated by frontend
                    items: vec![],  // Frontend will fetch current cart items
                })
                .map_err(|e| format!("Failed to serialize cart data: {}", e))?,
            ),
            error: None,
        })
    }

    /// Validate and EXECUTE checkout action
    async fn validate_checkout(
        &self,
        payment_method: &str,
        shipping_method: &str,
        session_id: Option<&str>,
        customer_id: Option<i32>,
    ) -> Result<ActionResponse, String> {
        // Default to ID 1 if guest
        let customer_id_val = customer_id.unwrap_or(1);
        println!(
            "[COMMAND_EXECUTOR] Starting checkout for customer: {}",
            customer_id_val
        );

        // 1. Fetch Cart Items
        let cart_items_db = if customer_id_val == 1 {
            // Guest checkout from kiosk_cart
            let session_key = session_id.unwrap_or("guest_session");
            self.db
                .cart()
                .fetch_complete_kiosk_cart_items(session_key)
                .await
                .map_err(|e| format!("Failed to fetch guest cart: {}", e))?
        } else {
            // Registered user checkout
            self.db
                .cart()
                .fetch_complete_cart_items(customer_id_val)
                .await
                .map_err(|e| format!("Failed to fetch cart: {}", e))?
        };

        if cart_items_db.is_empty() {
            return Ok(ActionResponse {
                action_type: Some("checkout".to_string()),
                success: false,
                message: "Your cart is empty. Please add items before checking out.".to_string(),
                data: None,
                error: Some("EMPTY_CART".to_string()),
            });
        }

        // Convert to CheckoutCartItem
        let cart_items: Vec<CheckoutCartItem> = cart_items_db
            .into_iter()
            .map(|item| CheckoutCartItem {
                variant_id: item.variant_id.unwrap_or(0),
                quantity: item.quantity,
                sell_price: item.sell_price,
                buy_price: item.buy_price,
            })
            .collect();

        // 2. Validate Customer (Skip complex validation for now, assume verified via auth middleware/logic)
        // In handlers we verify phone number etc. forcing simplistic check here for AI flow.

        // 3. Generate Idempotency Key
        let idempotency_key = self
            .generate_idempotency_key(customer_id_val, &cart_items)
            .await;

        // 4. Check Duplicate
        let is_duplicate = self
            .db
            .orders()
            .check_duplicate_order(&idempotency_key)
            .await
            .unwrap_or(false);

        if is_duplicate {
            return Ok(ActionResponse {
                action_type: Some("checkout".to_string()),
                success: false,
                message: "Order already processed.".to_string(),
                data: None,
                error: Some("DUPLICATE_ORDER".to_string()),
            });
        }

        // 5. Validate Cart Security & Calculate Totals
        let (is_valid, message, totals) = self
            .db
            .orders()
            .validate_cart_security(&cart_items)
            .await
            .map_err(|e| format!("Cart validation error: {}", e))?;

        if !is_valid {
            return Ok(ActionResponse {
                action_type: Some("checkout".to_string()),
                success: false,
                message,
                data: None,
                error: Some("SECURITY_VIOLATION".to_string()),
            });
        }

        // 6. Reserve Inventory
        let (reserved, res_msg) = self
            .db
            .orders()
            .reserve_inventory(&idempotency_key, &cart_items)
            .await
            .map_err(|e| format!("Inventory error: {}", e))?;

        if !reserved {
            return Ok(ActionResponse {
                action_type: Some("checkout".to_string()),
                success: false,
                message: res_msg,
                data: None,
                error: Some("INVENTORY_UNAVAILABLE".to_string()),
            });
        }

        // 7. Create Order
        // Use default defaults for AI if empty
        let final_payment = if payment_method.is_empty() {
            "cod"
        } else {
            payment_method
        };
        let final_shipping = if shipping_method.is_empty() {
            "pickup"
        } else {
            shipping_method
        };
        // AI flow assumes pickup/no address needed logic or uses default address (-1 in some contexts, or 0)
        let address_id = -1;

        let create_result = self
            .db
            .orders()
            .create_order(
                customer_id_val,
                &cart_items,
                address_id, // Fixed: removed Some() wrapper
                final_shipping,
                final_payment,
                &totals,
                &idempotency_key,
            )
            .await;

        match create_result {
            Ok((success, msg, order_id_opt)) => {
                if !success {
                    // Rollback reservation
                    self.db
                        .orders()
                        .rollback_inventory_reservation(&idempotency_key)
                        .await
                        .ok();

                    return Ok(ActionResponse {
                        action_type: Some("checkout".to_string()),
                        success: false,
                        message: msg,
                        data: None,
                        error: Some("ORDER_CREATION_FAILED".to_string()),
                    });
                }
                let order_id = order_id_opt.unwrap();

                // 8. Confirm Inventory
                self.db
                    .orders()
                    .confirm_inventory_reservation(&idempotency_key)
                    .await
                    .ok();

                // 9. Clear Cart
                if customer_id_val == 1 {
                    self.db
                        .cart()
                        .clear_kiosk_cart(session_id.unwrap_or("guest_session"))
                        .await
                        .ok();
                } else {
                    self.db.cart().clear_cart(customer_id_val).await.ok();
                }

                Ok(ActionResponse {
                    action_type: Some("checkout".to_string()),
                    success: true,
                    message: format!("Order #{} placed successfully!", order_id),
                    data: Some(json!({
                        "orderId": order_id,
                        "total": totals.total,
                        "subtotal": totals.subtotal
                    })),
                    error: None,
                })
            }
            Err(e) => {
                self.db
                    .orders()
                    .rollback_inventory_reservation(&idempotency_key)
                    .await
                    .ok();
                Err(format!("Order creation exception: {}", e))
            }
        }
    }

    /// Generate idempotency key (Helper duplicated from handlers due to isolation)
    async fn generate_idempotency_key(
        &self,
        customer_id: i32,
        cart_items: &[CheckoutCartItem],
    ) -> String {
        let cart_data: String = cart_items
            .iter()
            .map(|item| format!("{}:{}:{}", item.variant_id, item.quantity, item.sell_price))
            .collect::<Vec<_>>()
            .join("|");

        let timestamp = chrono::Utc::now().timestamp() / 60;
        let input = format!("{}:{}:{}", customer_id, cart_data, timestamp);

        let mut hasher = Sha256::new();
        hasher.update(input.as_bytes());
        let result = hasher.finalize();

        format!("ai_checkout_{:x}", result)[..24].to_string()
    }

    /// Helper: Search for variant_id by product name
    async fn search_variant_id(&self, item_name: &str) -> Result<i32, String> {
        // Search for the product
        let products = self
            .db
            .products()
            .search_products(item_name, 0, 5)
            .await
            .map_err(|e| format!("Product search failed: {}", e))?;

        if products.is_empty() {
            return Err(format!("Product '{}' not found", item_name));
        }

        // Get the first product's ID
        let product_id = products[0].product_id;

        // Fetch variations for this product
        let variations = self
            .db
            .products()
            .fetch_product_variations(product_id)
            .await
            .map_err(|e| format!("Failed to fetch variations: {}", e))?;

        if variations.is_empty() {
            return Err(format!("No variations available for '{}'", item_name));
        }

        // Return the first available variant
        let variant_id = variations[0].variant_id;

        Ok(variant_id)
    }

    /// Helper: Get product details by variant_id
    async fn get_product_details(
        &self,
        variant_id: i32,
    ) -> Result<(String, String, f64, i32), String> {
        // Get variation details
        let variation = self
            .db
            .products()
            .fetch_variation_by_id(variant_id)
            .await
            .map_err(|e| format!("Failed to fetch variation: {}", e))?;

        // Get product details
        let product = self
            .db
            .products()
            .fetch_product_by_id(variation.product_id)
            .await
            .map_err(|e| format!("Failed to fetch product: {}", e))?;

        let sell_price = variation
            .sell_price
            .to_string()
            .parse::<f64>()
            .map_err(|_| "Failed to parse sell price")?;

        Ok((
            product.name,
            variation.variant_name,
            sell_price,
            variation.stock,
        ))
    }

    /// Helper: Parse variant information from item name in format "Product Name (Variant Name)"
    fn parse_variant_from_item_name(&self, item_name: &str) -> Option<(String, String)> {
        // Look for pattern "Product Name (Variant Name)"
        if let Some(start_paren) = item_name.find('(') {
            if let Some(end_paren) = item_name.find(')') {
                if start_paren < end_paren && end_paren == item_name.len() - 1 {
                    let product_name = item_name[..start_paren].trim().to_string();
                    let variant_name = item_name[start_paren + 1..end_paren].trim().to_string();

                    if !product_name.is_empty() && !variant_name.is_empty() {
                        return Some((product_name, variant_name));
                    }
                }
            }
        }

        None
    }

    /// Helper: Validate add to cart with product name and variant name
    async fn validate_add_to_cart_with_variant_name(
        &self,
        product_name: &str,
        variant_name: &str,
        quantity: i32,
        session_id: Option<&str>,
        customer_id: Option<i32>,
    ) -> Result<ActionResponse, String> {
        // Search for the product by name
        let products = self
            .db
            .products()
            .search_products(product_name, 0, 5)
            .await
            .map_err(|e| format!("Product search failed: {}", e))?;

        if products.is_empty() {
            return Ok(ActionResponse {
                action_type: Some("add_to_cart".to_string()),
                success: false,
                message: format!("Product '{}' not found", product_name),
                data: None,
                error: Some("Product not found".to_string()),
            });
        }

        // Get the first matching product
        let product = &products[0];
        let product_id = product.product_id;

        // Fetch all variations for this product
        let variations = self
            .db
            .products()
            .fetch_product_variations(product_id)
            .await
            .map_err(|e| format!("Failed to fetch variations: {}", e))?;

        // Find the specific variant by name (case-insensitive)
        let target_variant = variations
            .iter()
            .find(|v| v.variant_name.to_lowercase() == variant_name.to_lowercase());

        match target_variant {
            Some(variant) => {
                // Found the variant, proceed with validation
                self.validate_add_to_cart_with_variant(
                    variant.variant_id,
                    quantity,
                    session_id,
                    customer_id,
                )
                .await
            }
            None => {
                // Variant not found, return available variants
                let available_variants: Vec<ProductVariant> = variations
                    .into_iter()
                    .map(|v| ProductVariant {
                        variant_id: v.variant_id,
                        variant_name: v.variant_name,
                        sell_price: v.sell_price.to_string().parse::<f64>().unwrap_or(0.0),
                        stock: v.stock,
                        attributes: None,
                    })
                    .collect();

                Ok(ActionResponse {
                    action_type: Some("variant_selection".to_string()),
                    success: true,
                    message: format!(
                        "Variant '{}' not found for '{}'. Available variants: {}",
                        variant_name,
                        product_name,
                        available_variants
                            .iter()
                            .map(|v| v.variant_name.as_str())
                            .collect::<Vec<_>>()
                            .join(", ")
                    ),
                    data: Some(
                        serde_json::to_value(VariantSelectionActionData {
                            product_id,
                            product_name: product.name.clone(),
                            quantity,
                            session_id: session_id.map(|s| s.to_string()),
                            customer_id,
                            available_variants,
                            queue_info: None, // Will be set later for sequential orchestration
                        })
                        .map_err(|e| {
                            format!("Failed to serialize variant selection data: {}", e)
                        })?,
                    ),
                    error: None,
                })
            }
        }
    }
}

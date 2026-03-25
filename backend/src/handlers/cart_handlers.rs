use axum::{
    extract::{Path, State},
    http::StatusCode,
    Json,
};
use std::sync::Arc;

use crate::{
    handlers::AiState,
    models::{
        AddToCartRequest, AddToKioskCartRequest, CartItem, CartListResponse, CartOperationResponse,
        CartValidationResponse, UpdateCartQuantityRequest, UpdateGuestCartRequest,
    },
};

/// Fetch cart items for a customer
/// GET /api/cart/:customer_id
pub async fn fetch_cart(
    State(state): State<Arc<AiState>>,
    Path(customer_id): Path<i32>,
) -> Result<Json<CartListResponse>, StatusCode> {
    println!("[GET] /api/cart/{} → fetching cart items...", customer_id);

    // Handle guest cart (customer_id 1)
    if customer_id == 1 {
        // We'll need a session ID here, but for now we'll use a placeholder or
        // return an empty list if not handled by session.
        // Actually, we should probably take session_id as a query param or header?
        // But for consistency with guest logic, let's look for a active guest cart in queue service.
        // Since we don't have session_id in the path, we might need to adjust the API or use a default.
        return match state.queue_service.get_guest_cart("guest_session") {
            Ok(items) => {
                // We need to convert GuestCartItem to CartItem by fetching product details from DB
                let mut full_items = Vec::new();
                for guest_item in items {
                    // Fetch details from DB
                    if let Ok(details) = state
                        .db
                        .products()
                        .fetch_variation_by_id(guest_item.variant_id)
                        .await
                    {
                        if let Ok(product) = state
                            .db
                            .products()
                            .fetch_product_by_id(details.product_id)
                            .await
                        {
                            full_items.push(CartItem {
                                cart_id: 0, // In-memory items don't have DB IDs
                                variant_id: Some(guest_item.variant_id),
                                quantity: guest_item.quantity,
                                customer_id: Some(1),
                                kiosk_session_id: None,
                                product_id: product.product_id,
                                product_name: product.name,
                                product_description: product.description,
                                image_url: product.image_url,
                                base_price: product.base_price,
                                sale_price: product.sale_price,
                                brand_id: product.brand_id,
                                variant_name: details.variant_name,
                                sell_price: details.sell_price,
                                buy_price: Some(details.buy_price),
                                stock: details.stock,
                                is_visible: details.is_visible,
                            });
                        }
                    }
                }

                let total_items: i32 = full_items.iter().map(|item| item.quantity).sum();
                let subtotal: f64 = full_items
                    .iter()
                    .map(|item| {
                        let qty = item.quantity as f64;
                        let price = item.sell_price.to_string().parse::<f64>().unwrap_or(0.0);
                        qty * price
                    })
                    .sum();

                Ok(Json(CartListResponse {
                    items: full_items,
                    total_items,
                    subtotal,
                    status: "success".to_string(),
                }))
            }
            Err(_) => Err(StatusCode::INTERNAL_SERVER_ERROR),
        };
    }

    match state.db.cart().fetch_complete_cart_items(customer_id).await {
        Ok(items) => {
            let total_items: i32 = items.iter().map(|item| item.quantity).sum();

            let subtotal: f64 = items
                .iter()
                .map(|item| {
                    let qty = item.quantity as f64;
                    let price = item.sell_price.to_string().parse::<f64>().unwrap_or(0.0);
                    qty * price
                })
                .sum();

            println!(
                "[OK ] /api/cart/{} → fetched {} items (total: {}, subtotal: ${:.2})",
                customer_id,
                items.len(),
                total_items,
                subtotal
            );

            Ok(Json(CartListResponse {
                items,
                total_items,
                subtotal,
                status: "success".to_string(),
            }))
        }
        Err(e) => {
            tracing::error!("Failed to fetch cart: {}", e);
            println!("[ERR] /api/cart/{} → {}", customer_id, e);
            Err(StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}

/// Fetch kiosk cart items
/// GET /api/cart/kiosk/:session_id
pub async fn fetch_kiosk_cart(
    State(state): State<Arc<AiState>>,
    Path(session_id): Path<String>,
) -> Result<Json<CartListResponse>, StatusCode> {
    println!(
        "[GET] /api/cart/kiosk/{} → fetching kiosk cart items...",
        session_id
    );

    match state
        .db
        .cart()
        .fetch_complete_kiosk_cart_items(&session_id)
        .await
    {
        Ok(items) => {
            let total_items: i32 = items.iter().map(|item| item.quantity).sum();

            let subtotal: f64 = items
                .iter()
                .map(|item| {
                    let qty = item.quantity as f64;
                    let price = item.sell_price.to_string().parse::<f64>().unwrap_or(0.0);
                    qty * price
                })
                .sum();

            println!(
                "[OK ] /api/cart/kiosk/{} → fetched {} items (total: {}, subtotal: ${:.2})",
                session_id,
                items.len(),
                total_items,
                subtotal
            );

            Ok(Json(CartListResponse {
                items,
                total_items,
                subtotal,
                status: "success".to_string(),
            }))
        }
        Err(e) => {
            tracing::error!("Failed to fetch kiosk cart: {}", e);
            println!("[ERR] /api/cart/kiosk/{} → {}", session_id, e);
            Err(StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}

/// Add item to cart
/// POST /api/cart/:customer_id/add
pub async fn add_to_cart(
    State(state): State<Arc<AiState>>,
    Path(customer_id): Path<i32>,
    Json(payload): Json<AddToCartRequest>,
) -> Result<Json<CartOperationResponse>, StatusCode> {
    println!(
        "[POST] /api/cart/{}/add → variant: {}, qty: {}",
        customer_id, payload.variant_id, payload.quantity
    );

    // Validate stock first
    match state
        .db
        .cart()
        .can_add_to_cart(payload.variant_id, payload.quantity)
        .await
    {
        Ok(can_add) => {
            if !can_add {
                println!("[ERR] /api/cart/{}/add → insufficient stock", customer_id);
                return Ok(Json(CartOperationResponse {
                    success: false,
                    message: "Insufficient stock or product not available".to_string(),
                }));
            }
        }
        Err(e) => {
            tracing::error!("Stock validation failed: {}", e);
            return Err(StatusCode::INTERNAL_SERVER_ERROR);
        }
    }

    // Handle guest cart (customer_id 1)
    if customer_id == 1 {
        println!(
            "[OK ] /api/cart/{}/add → saving to in-memory guest cart",
            customer_id
        );
        match state.queue_service.add_to_guest_cart(
            "guest_session",
            payload.variant_id,
            payload.quantity,
        ) {
            Ok(_) => {
                return Ok(Json(CartOperationResponse {
                    success: true,
                    message: "Item added to guest cart (in-memory) successfully".to_string(),
                }));
            }
            Err(e) => {
                tracing::error!("Failed to add to guest cart: {}", e);
                return Err(StatusCode::INTERNAL_SERVER_ERROR);
            }
        }
    }

    // Add to cart
    match state
        .db
        .cart()
        .add_to_cart(customer_id, payload.variant_id, payload.quantity)
        .await
    {
        Ok(_) => {
            println!("[OK ] /api/cart/{}/add → item added", customer_id);
            Ok(Json(CartOperationResponse {
                success: true,
                message: "Item added to cart successfully".to_string(),
            }))
        }
        Err(e) => {
            tracing::error!("Failed to add to cart: {}", e);
            println!("[ERR] /api/cart/{}/add → {}", customer_id, e);
            Err(StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}

/// Add item to kiosk cart
/// POST /api/cart/kiosk/add
pub async fn add_to_kiosk_cart(
    State(state): State<Arc<AiState>>,
    Json(payload): Json<AddToKioskCartRequest>,
) -> Result<Json<CartOperationResponse>, StatusCode> {
    println!(
        "[POST] /api/cart/kiosk/add → session: {}, variant: {}, qty: {}",
        payload.kiosk_session_id, payload.variant_id, payload.quantity
    );

    // Validate stock first
    match state
        .db
        .cart()
        .can_add_to_cart(payload.variant_id, payload.quantity)
        .await
    {
        Ok(can_add) => {
            if !can_add {
                println!("[ERR] /api/cart/kiosk/add → insufficient stock");
                return Ok(Json(CartOperationResponse {
                    success: false,
                    message: "Insufficient stock or product not available".to_string(),
                }));
            }
        }
        Err(e) => {
            tracing::error!("Stock validation failed: {}", e);
            return Err(StatusCode::INTERNAL_SERVER_ERROR);
        }
    }

    // Add to kiosk cart
    match state
        .db
        .cart()
        .add_to_kiosk_cart(
            &payload.kiosk_session_id,
            payload.variant_id,
            payload.quantity,
        )
        .await
    {
        Ok(_) => {
            println!("[OK ] /api/cart/kiosk/add → item added");
            Ok(Json(CartOperationResponse {
                success: true,
                message: "Item added to kiosk cart successfully".to_string(),
            }))
        }
        Err(e) => {
            tracing::error!("Failed to add to kiosk cart: {}", e);
            println!("[ERR] /api/cart/kiosk/add → {}", e);
            Err(StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}

/// Update guest cart item quantity (customer_id 1, in-memory cart)
/// PUT /api/cart/guest/item
pub async fn update_guest_cart_item(
    State(state): State<Arc<AiState>>,
    Json(payload): Json<UpdateGuestCartRequest>,
) -> Result<Json<CartOperationResponse>, StatusCode> {
    println!(
        "[PUT] /api/cart/guest/item → variant: {}, quantity: {}",
        payload.variant_id, payload.quantity
    );

    match state.queue_service.update_guest_cart_item(
        "guest_session",
        payload.variant_id,
        payload.quantity,
    ) {
        Ok(true) => {
            println!("[OK ] /api/cart/guest/item → quantity updated");
            Ok(Json(CartOperationResponse {
                success: true,
                message: "Guest cart item quantity updated".to_string(),
            }))
        }
        Ok(false) => {
            println!("[ERR] /api/cart/guest/item → item not found");
            Ok(Json(CartOperationResponse {
                success: false,
                message: "Guest cart item not found".to_string(),
            }))
        }
        Err(e) => {
            tracing::error!("Failed to update guest cart: {}", e);
            Err(StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}

/// Remove guest cart item
/// DELETE /api/cart/guest/item/:variant_id
pub async fn remove_guest_cart_item(
    State(state): State<Arc<AiState>>,
    Path(variant_id): Path<i32>,
) -> Result<Json<CartOperationResponse>, StatusCode> {
    println!("[DELETE] /api/cart/guest/item/{} → removing item...", variant_id);

    match state
        .queue_service
        .remove_from_guest_cart("guest_session", variant_id)
    {
        Ok(true) => {
            println!("[OK ] /api/cart/guest/item/{} → item removed", variant_id);
            Ok(Json(CartOperationResponse {
                success: true,
                message: "Item removed from guest cart".to_string(),
            }))
        }
        Ok(false) => {
            println!("[ERR] /api/cart/guest/item/{} → item not found", variant_id);
            Ok(Json(CartOperationResponse {
                success: false,
                message: "Guest cart item not found".to_string(),
            }))
        }
        Err(e) => {
            tracing::error!("Failed to remove from guest cart: {}", e);
            Err(StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}

/// Update cart item quantity
/// PUT /api/cart/item/:cart_id
pub async fn update_cart_quantity(
    State(state): State<Arc<AiState>>,
    Path(cart_id): Path<i32>,
    Json(payload): Json<UpdateCartQuantityRequest>,
) -> Result<Json<CartOperationResponse>, StatusCode> {
    println!(
        "[PUT] /api/cart/item/{} → updating quantity to {}",
        cart_id, payload.quantity
    );

    match state
        .db
        .cart()
        .update_cart_item_quantity(cart_id, payload.quantity)
        .await
    {
        Ok(success) => {
            if success {
                println!("[OK ] /api/cart/item/{} → quantity updated", cart_id);
                Ok(Json(CartOperationResponse {
                    success: true,
                    message: "Cart item quantity updated".to_string(),
                }))
            } else {
                println!("[ERR] /api/cart/item/{} → cart item not found", cart_id);
                Ok(Json(CartOperationResponse {
                    success: false,
                    message: "Cart item not found".to_string(),
                }))
            }
        }
        Err(e) => {
            tracing::error!("Failed to update cart quantity: {}", e);
            println!("[ERR] /api/cart/item/{} → {}", cart_id, e);
            Err(StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}

/// Update kiosk cart item quantity
/// PUT /api/cart/kiosk/item/:kiosk_id
pub async fn update_kiosk_cart_quantity(
    State(state): State<Arc<AiState>>,
    Path(kiosk_id): Path<i32>,
    Json(payload): Json<UpdateCartQuantityRequest>,
) -> Result<Json<CartOperationResponse>, StatusCode> {
    println!(
        "[PUT] /api/cart/kiosk/item/{} → updating quantity to {}",
        kiosk_id, payload.quantity
    );

    match state
        .db
        .cart()
        .update_kiosk_cart_item_quantity(kiosk_id, payload.quantity)
        .await
    {
        Ok(success) => {
            if success {
                println!("[OK ] /api/cart/kiosk/item/{} → quantity updated", kiosk_id);
                Ok(Json(CartOperationResponse {
                    success: true,
                    message: "Kiosk cart item quantity updated".to_string(),
                }))
            } else {
                println!(
                    "[ERR] /api/cart/kiosk/item/{} → kiosk cart item not found",
                    kiosk_id
                );
                Ok(Json(CartOperationResponse {
                    success: false,
                    message: "Kiosk cart item not found".to_string(),
                }))
            }
        }
        Err(e) => {
            tracing::error!("Failed to update kiosk cart quantity: {}", e);
            println!("[ERR] /api/cart/kiosk/item/{} → {}", kiosk_id, e);
            Err(StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}

/// Remove cart item
/// DELETE /api/cart/item/:cart_id
pub async fn remove_cart_item(
    State(state): State<Arc<AiState>>,
    Path(cart_id): Path<i32>,
) -> Result<Json<CartOperationResponse>, StatusCode> {
    println!("[DELETE] /api/cart/item/{} → removing item...", cart_id);

    match state.db.cart().remove_cart_item(cart_id).await {
        Ok(success) => {
            if success {
                println!("[OK ] /api/cart/item/{} → item removed", cart_id);
                Ok(Json(CartOperationResponse {
                    success: true,
                    message: "Item removed from cart".to_string(),
                }))
            } else {
                println!("[ERR] /api/cart/item/{} → item not found", cart_id);
                Ok(Json(CartOperationResponse {
                    success: false,
                    message: "Cart item not found".to_string(),
                }))
            }
        }
        Err(e) => {
            tracing::error!("Failed to remove cart item: {}", e);
            println!("[ERR] /api/cart/item/{} → {}", cart_id, e);
            Err(StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}

/// Remove kiosk cart item
/// DELETE /api/cart/kiosk/item/:kiosk_id
pub async fn remove_kiosk_cart_item(
    State(state): State<Arc<AiState>>,
    Path(kiosk_id): Path<i32>,
) -> Result<Json<CartOperationResponse>, StatusCode> {
    println!(
        "[DELETE] /api/cart/kiosk/item/{} → removing item...",
        kiosk_id
    );

    match state.db.cart().remove_kiosk_cart_item(kiosk_id).await {
        Ok(success) => {
            if success {
                println!("[OK ] /api/cart/kiosk/item/{} → item removed", kiosk_id);
                Ok(Json(CartOperationResponse {
                    success: true,
                    message: "Item removed from kiosk cart".to_string(),
                }))
            } else {
                println!("[ERR] /api/cart/kiosk/item/{} → item not found", kiosk_id);
                Ok(Json(CartOperationResponse {
                    success: false,
                    message: "Kiosk cart item not found".to_string(),
                }))
            }
        }
        Err(e) => {
            tracing::error!("Failed to remove kiosk cart item: {}", e);
            println!("[ERR] /api/cart/kiosk/item/{} → {}", kiosk_id, e);
            Err(StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}

/// Clear cart
/// DELETE /api/cart/:customer_id/clear
pub async fn clear_cart(
    State(state): State<Arc<AiState>>,
    Path(customer_id): Path<i32>,
) -> Result<Json<CartOperationResponse>, StatusCode> {
    println!(
        "[DELETE] /api/cart/{}/clear → clearing cart...",
        customer_id
    );

    if customer_id == 1 {
        match state.queue_service.clear_guest_cart("guest_session") {
            Ok(_) => {
                return Ok(Json(CartOperationResponse {
                    success: true,
                    message: "Guest cart cleared successfully".to_string(),
                }));
            }
            Err(e) => {
                tracing::error!("Failed to clear guest cart: {}", e);
                return Err(StatusCode::INTERNAL_SERVER_ERROR);
            }
        }
    }

    match state.db.cart().clear_cart(customer_id).await {
        Ok(_) => {
            println!("[OK ] /api/cart/{}/clear → cart cleared", customer_id);
            Ok(Json(CartOperationResponse {
                success: true,
                message: "Cart cleared successfully".to_string(),
            }))
        }
        Err(e) => {
            tracing::error!("Failed to clear cart: {}", e);
            println!("[ERR] /api/cart/{}/clear → {}", customer_id, e);
            Err(StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}

/// Clear kiosk cart
/// DELETE /api/cart/kiosk/:session_id/clear
pub async fn clear_kiosk_cart(
    State(state): State<Arc<AiState>>,
    Path(session_id): Path<String>,
) -> Result<Json<CartOperationResponse>, StatusCode> {
    println!(
        "[DELETE] /api/cart/kiosk/{}/clear → clearing kiosk cart...",
        session_id
    );

    match state.db.cart().clear_kiosk_cart(&session_id).await {
        Ok(_) => {
            println!(
                "[OK ] /api/cart/kiosk/{}/clear → kiosk cart cleared",
                session_id
            );
            Ok(Json(CartOperationResponse {
                success: true,
                message: "Kiosk cart cleared successfully".to_string(),
            }))
        }
        Err(e) => {
            tracing::error!("Failed to clear kiosk cart: {}", e);
            println!("[ERR] /api/cart/kiosk/{}/clear → {}", session_id, e);
            Err(StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}

/// Validate cart stock
/// GET /api/cart/:customer_id/validate
pub async fn validate_cart_stock(
    State(state): State<Arc<AiState>>,
    Path(customer_id): Path<i32>,
) -> Result<Json<CartValidationResponse>, StatusCode> {
    println!(
        "[GET] /api/cart/{}/validate → validating cart stock...",
        customer_id
    );

    if customer_id == 1 {
        // Simple validation for guest cart
        return Ok(Json(CartValidationResponse {
            has_issues: false,
            adjustments: vec![],
        }));
    }

    match state.db.cart().validate_cart_stock(customer_id).await {
        Ok(adjustments) => {
            let has_issues = !adjustments.is_empty();
            println!(
                "[OK ] /api/cart/{}/validate → {} adjustments needed",
                customer_id,
                adjustments.len()
            );

            Ok(Json(CartValidationResponse {
                has_issues,
                adjustments,
            }))
        }
        Err(e) => {
            tracing::error!("Failed to validate cart stock: {}", e);
            println!("[ERR] /api/cart/{}/validate → {}", customer_id, e);
            Err(StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}

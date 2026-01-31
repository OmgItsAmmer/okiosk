use axum::{extract::State, http::StatusCode, Json};
use rust_decimal::Decimal;
use serde_json::json;
use sha2::{Digest, Sha256};
use sqlx::Row;
use std::sync::Arc;

use crate::{
    database::Database,
    models::{CheckoutCartItem, CheckoutRequest, CheckoutResponse, OrderTotals},
};

/// Checkout handler
/// POST /api/checkout
pub async fn checkout(
    State(db): State<Arc<Database>>,
    Json(payload): Json<CheckoutRequest>,
) -> Result<Json<CheckoutResponse>, StatusCode> {
    let customer_id: i32 = payload.customer_id;
    println!(
        "[POST] /api/checkout → Starting secure checkout for customer: {}",
        customer_id
    );
    println!(
        "[POST] Shipping method: {}, Payment method: {}",
        payload.shipping_method, payload.payment_method
    );

    // Step 1: Verify customer exists and has phone number
    match db.orders().verify_customer(customer_id).await {
        Ok((is_valid, message)) => {
            if !is_valid {
                println!("[ERR] Customer verification failed: {}", message);
                return Ok(Json(CheckoutResponse {
                    success: false,
                    message,
                    order_id: None,
                    total: None,
                    error_code: Some("PHONE_NUMBER_REQUIRED".to_string()),
                }));
            }
        }
        Err(e) => {
            tracing::error!("Customer verification error: {}", e);
            return Err(StatusCode::INTERNAL_SERVER_ERROR);
        }
    }

    // Step 2: Prepare cart items (for both cart and direct checkout)
    let mut cart_items: Vec<CheckoutCartItem> = Vec::new();

    if let Some(direct_checkout) = &payload.direct_checkout {
        // Direct checkout - create temporary cart item
        // Fetch buy_price from database
        let buy_price = match fetch_variant_buy_price(&db, direct_checkout.variant_id).await {
            Ok(price) => price,
            Err(_) => {
                return Ok(Json(CheckoutResponse {
                    success: false,
                    message: "Product not found".to_string(),
                    order_id: None,
                    total: None,
                    error_code: Some("PRODUCT_NOT_FOUND".to_string()),
                }));
            }
        };

        cart_items.push(CheckoutCartItem {
            variant_id: direct_checkout.variant_id,
            quantity: direct_checkout.quantity,
            sell_price: direct_checkout.price,
            buy_price: Some(buy_price),
        });
    } else if let Some(items) = &payload.cart_items {
        cart_items = items.clone();
    }

    if cart_items.is_empty() {
        println!("[ERR] Cart is empty");
        return Ok(Json(CheckoutResponse {
            success: false,
            message: "Cart is empty".to_string(),
            order_id: None,
            total: None,
            error_code: Some("EMPTY_CART".to_string()),
        }));
    }

    // Step 3: Generate idempotency key
    let idempotency_key = match &payload.idempotency_key {
        Some(key) => key.clone(),
        None => generate_idempotency_key(customer_id, &cart_items).await,
    };

    println!("[POST] Idempotency key: {}", idempotency_key);

    // Step 4: Validate shipping method
    match db
        .orders()
        .validate_shipping_method(&payload.shipping_method, payload.address_id)
        .await
    {
        Ok((is_valid, message)) => {
            if !is_valid {
                println!("[ERR] Shipping validation failed: {}", message);
                return Ok(Json(CheckoutResponse {
                    success: false,
                    message,
                    order_id: None,
                    total: None,
                    error_code: Some("SHIPPING_METHOD_INVALID".to_string()),
                }));
            }
        }
        Err(e) => {
            tracing::error!("Shipping validation error: {}", e);
            return Err(StatusCode::INTERNAL_SERVER_ERROR);
        }
    }

    // Step 5: Check for duplicate orders
    match db.orders().check_duplicate_order(&idempotency_key).await {
        Ok(is_duplicate) => {
            if is_duplicate {
                println!("[ERR] Duplicate order detected");
                return Ok(Json(CheckoutResponse {
                    success: false,
                    message: "Order already processed. Please refresh and try again.".to_string(),
                    order_id: None,
                    total: None,
                    error_code: Some("DUPLICATE_ORDER".to_string()),
                }));
            }
        }
        Err(e) => {
            tracing::error!("Duplicate check error: {}", e);
            return Err(StatusCode::INTERNAL_SERVER_ERROR);
        }
    }

    // Step 6: Validate cart security (server-side price validation)
    let totals: OrderTotals;
    match db.orders().validate_cart_security(&cart_items).await {
        Ok((is_valid, message, calculated_totals)) => {
            if !is_valid {
                println!("[ERR] Cart validation failed: {}", message);

                // Log security event
                db.orders()
                    .log_security_event(
                        "cart_validation_failed",
                        json!({
                            "customer_id": payload.customer_id,
                            "error": message,
                            "cart_items": cart_items.len()
                        }),
                        Some(payload.customer_id),
                    )
                    .await
                    .ok();

                return Ok(Json(CheckoutResponse {
                    success: false,
                    message,
                    order_id: None,
                    total: None,
                    error_code: Some("SECURITY_VIOLATION".to_string()),
                }));
            }
            totals = calculated_totals;
        }
        Err(e) => {
            tracing::error!("Cart validation error: {}", e);
            return Err(StatusCode::INTERNAL_SERVER_ERROR);
        }
    }

    // Step 7: Reserve inventory with optimistic locking
    match db
        .orders()
        .reserve_inventory(&idempotency_key, &cart_items)
        .await
    {
        Ok((success, message)) => {
            if !success {
                println!("[ERR] Inventory reservation failed: {}", message);
                return Ok(Json(CheckoutResponse {
                    success: false,
                    message,
                    order_id: None,
                    total: None,
                    error_code: Some("INVENTORY_UNAVAILABLE".to_string()),
                }));
            }
        }
        Err(e) => {
            tracing::error!("Inventory reservation error: {}", e);
            return Err(StatusCode::INTERNAL_SERVER_ERROR);
        }
    }

    // Step 8: Process payment
    let payment_result = process_payment(
        &payload.payment_method,
        &totals.total,
        customer_id,
        &idempotency_key,
    )
    .await;

    if !payment_result.0 {
        println!("[ERR] Payment failed: {}", payment_result.1);

        // Rollback inventory reservation
        db.orders()
            .rollback_inventory_reservation(&idempotency_key)
            .await
            .ok();

        return Ok(Json(CheckoutResponse {
            success: false,
            message: payment_result.1,
            order_id: None,
            total: None,
            error_code: Some("PAYMENT_FAILED".to_string()),
        }));
    }

    // Step 9: Create order
    let order_id: i32;
    match db
        .orders()
        .create_order(
            customer_id,
            &cart_items,
            payload.address_id,
            &payload.shipping_method,
            &payload.payment_method,
            &totals,
            &idempotency_key,
        )
        .await
    {
        Ok((success, message, id)) => {
            if !success {
                println!("[ERR] Order creation failed: {}", message);

                // Rollback inventory reservation
                db.orders()
                    .rollback_inventory_reservation(&idempotency_key)
                    .await
                    .ok();

                // TODO: Add payment refund logic here for JazzCash and other payment methods

                return Ok(Json(CheckoutResponse {
                    success: false,
                    message,
                    order_id: None,
                    total: None,
                    error_code: Some("ORDER_CREATION_FAILED".to_string()),
                }));
            }
            order_id = id.unwrap();
        }
        Err(e) => {
            tracing::error!("Order creation error: {}", e);

            // Rollback inventory reservation
            db.orders()
                .rollback_inventory_reservation(&idempotency_key)
                .await
                .ok();

            return Err(StatusCode::INTERNAL_SERVER_ERROR);
        }
    }

    // Step 10: Confirm inventory reservation (reduce actual stock)
    if let Err(e) = db
        .orders()
        .confirm_inventory_reservation(&idempotency_key)
        .await
    {
        tracing::error!("Inventory confirmation error: {}", e);
        // Continue anyway - order is created
    }

    // Step 11: Clear cart for regular checkout (not direct checkout)
    if payload.direct_checkout.is_none() {
        if let Err(e) = db.orders().clear_customer_cart(customer_id).await {
            tracing::error!("Cart clearing error: {}", e);
            // Continue anyway - order is created
        }
    }

    // Step 12: Log successful checkout
    db.orders()
        .log_security_event(
            "checkout_success",
            json!({
                "customer_id": customer_id,
                "order_id": order_id,
                "total": totals.total.to_string(),
                "shipping_method": payload.shipping_method,
                "payment_method": payload.payment_method
            }),
            Some(customer_id),
        )
        .await
        .ok();

    println!(
        "[OK ] Checkout completed successfully: order_id={}",
        order_id
    );

    Ok(Json(CheckoutResponse {
        success: true,
        message: "Order placed successfully!".to_string(),
        order_id: Some(order_id),
        total: Some(totals.total),
        error_code: None,
    }))
}

// ===== Helper Functions =====

/// Generate idempotency key using SHA-256
async fn generate_idempotency_key(customer_id: i32, cart_items: &[CheckoutCartItem]) -> String {
    let cart_data: String = cart_items
        .iter()
        .map(|item| format!("{}:{}:{}", item.variant_id, item.quantity, item.sell_price))
        .collect::<Vec<_>>()
        .join("|");

    // Use 1-minute window for idempotency
    let timestamp = chrono::Utc::now().timestamp() / 60;
    let input = format!("{}:{}:{}", customer_id, cart_data, timestamp);

    let mut hasher = Sha256::new();
    hasher.update(input.as_bytes());
    let result = hasher.finalize();

    format!("checkout_{:x}", result)[..24].to_string()
}

/// Fetch variant buy price from database
async fn fetch_variant_buy_price(
    db: &Arc<Database>,
    variant_id: i32,
) -> Result<Decimal, sqlx::Error> {
    // Access the pool directly from the database instance through OrderQueries
    let pool = db.orders().pool();

    let result = sqlx::query("SELECT buy_price FROM product_variants WHERE variant_id = $1")
        .bind(variant_id)
        .fetch_one(pool)
        .await?;

    Ok(result
        .get::<Option<Decimal>, _>("buy_price")
        .unwrap_or(Decimal::new(0, 0)))
}

/// Process payment (extensible for different payment methods)
async fn process_payment(
    payment_method: &str,
    amount: &Decimal,
    _customer_id: i32,
    idempotency_key: &str,
) -> (bool, String, String) {
    println!(
        "[PAYMENT] Processing {} payment for amount: PKR {}",
        payment_method, amount
    );

    match payment_method {
        "cod" => {
            // Cash on Delivery - no payment processing needed
            (
                true,
                "Cash on Delivery order confirmed".to_string(),
                format!("cod_{}", idempotency_key),
            )
        }
        "pickup" => {
            // Pickup order - no payment processing needed
            (
                true,
                "Pickup order confirmed - payment at pickup".to_string(),
                format!("pickup_{}", idempotency_key),
            )
        }
        "credit_card" => {
            // TODO: Integrate with Stripe, Square, or other credit card processor
            (
                true,
                "Credit card payment processed".to_string(),
                format!("cc_{}", idempotency_key),
            )
        }
        "bank_transfer" => {
            // TODO: Integrate with bank transfer API
            (
                true,
                "Bank transfer initiated".to_string(),
                format!("bt_{}", idempotency_key),
            )
        }
        "jazzcash" => {
            // TODO: Implement JazzCash payment processing
            // This is where you'll integrate with JazzCash API
            println!("[PAYMENT] JazzCash payment simulation - Replace with actual API call");
            (
                true,
                "JazzCash payment processed".to_string(),
                format!("jc_{}", idempotency_key),
            )
        }
        _ => (
            false,
            format!("Payment method {} not supported", payment_method),
            String::new(),
        ),
    }
}

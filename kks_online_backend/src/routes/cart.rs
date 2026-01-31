use axum::{routing::{delete, get, post, put}, Router};
use std::sync::Arc;

use crate::database::Database;
use crate::handlers;

/// Creates cart-related routes
/// 
/// This module handles all cart endpoints including:
/// - Customer cart operations (get, add, update, remove, clear, validate)
/// - Kiosk cart operations (get, add, update, remove, clear)
/// 
/// # Arguments
/// * `database` - Shared database connection pool
/// 
/// # Returns
/// Router configured with all cart endpoints
pub fn create_cart_routes(database: Arc<Database>) -> Router {
    Router::new()
        // Customer cart endpoints
        .route("/api/cart/:customer_id", get(handlers::fetch_cart))
        .route("/api/cart/:customer_id/add", post(handlers::add_to_cart))
        .route("/api/cart/:customer_id/clear", delete(handlers::clear_cart))
        .route(
            "/api/cart/:customer_id/validate",
            get(handlers::validate_cart_stock),
        )
        .route(
            "/api/cart/item/:cart_id",
            put(handlers::update_cart_quantity),
        )
        .route(
            "/api/cart/item/:cart_id",
            delete(handlers::remove_cart_item),
        )
        // Kiosk cart endpoints
        .route(
            "/api/cart/kiosk/:session_id",
            get(handlers::fetch_kiosk_cart),
        )
        .route("/api/cart/kiosk/add", post(handlers::add_to_kiosk_cart))
        .route(
            "/api/cart/kiosk/:session_id/clear",
            delete(handlers::clear_kiosk_cart),
        )
        .route(
            "/api/cart/kiosk/item/:kiosk_id",
            put(handlers::update_kiosk_cart_quantity),
        )
        .route(
            "/api/cart/kiosk/item/:kiosk_id",
            delete(handlers::remove_kiosk_cart_item),
        )
        .with_state(database)
}

use axum::{routing::post, Router};
use std::sync::Arc;

use crate::database::Database;
use crate::handlers;

/// Creates checkout-related routes
/// 
/// This module handles checkout operations including:
/// - Order processing with race condition handling
/// - Stock validation during checkout
/// 
/// # Arguments
/// * `database` - Shared database connection pool
/// 
/// # Returns
/// Router configured with checkout endpoints
pub fn create_checkout_routes(database: Arc<Database>) -> Router {
    Router::new()
        .route("/api/checkout", post(handlers::checkout))
        .with_state(database)
}

use axum::{routing::get, Router};
use std::sync::Arc;

use crate::database::Database;
use crate::handlers;

/// Creates health check and test routes
/// 
/// This module handles:
/// - Root endpoint (welcome message)
/// - Database connection test
/// - Order fetching test
/// - Button press test
/// 
/// # Arguments
/// * `database` - Shared database connection pool
/// 
/// # Returns
/// Router configured with health and test endpoints
pub fn create_health_routes(database: Arc<Database>) -> Router {
    Router::new()
        .route("/", get(root_handler))
        .route("/test-db", get(handlers::test_database))
        .route("/orders", get(handlers::fetch_orders))
        .route("/test-button", get(handlers::test_button_press))
        .with_state(database)
}

/// Root endpoint handler
/// 
/// Returns a welcome message for the API
async fn root_handler() -> &'static str {
    "🚀 KKS Online Backend - E-commerce & Kiosk API"
}

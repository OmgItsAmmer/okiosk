mod ai;
mod cart;
mod categories;
mod checkout;
mod health;
mod products;
mod variations;

use axum::Router;
use std::sync::Arc;

use crate::database::Database;
use crate::handlers::AiState;

/// Creates and configures the main application router
/// 
/// This function combines all route modules into a single router with proper state management.
/// Each route module handles its own domain-specific routes.
/// 
/// # Arguments
/// * `database` - Shared database connection pool
/// * `ai_state` - Shared AI service state
/// 
/// # Returns
/// Configured Axum Router ready to be served
pub fn create_router(database: Arc<Database>, ai_state: Arc<AiState>) -> Router {
    Router::new()
        // Health and test routes
        .merge(health::create_health_routes(database.clone()))
        // Product routes
        .merge(products::create_product_routes(database.clone()))
        // Variation routes
        .merge(variations::create_variation_routes(database.clone()))
        // Category routes
        .merge(categories::create_category_routes(database.clone()))
        // Cart routes
        .merge(cart::create_cart_routes(database.clone()))
        // Checkout routes
        .merge(checkout::create_checkout_routes(database.clone()))
        // AI routes
        .merge(ai::create_ai_routes(ai_state))
}

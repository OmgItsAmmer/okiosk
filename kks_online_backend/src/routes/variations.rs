use axum::{routing::get, Router};
use std::sync::Arc;

use crate::database::Database;
use crate::handlers;

/// Creates product variation-related routes
/// 
/// This module handles all variation endpoints including:
/// - Variation details by ID
/// - Related variations
/// - Stock checking for variations
/// 
/// # Arguments
/// * `database` - Shared database connection pool
/// 
/// # Returns
/// Router configured with all variation endpoints
pub fn create_variation_routes(database: Arc<Database>) -> Router {
    Router::new()
        .route(
            "/api/variations/:variant_id",
            get(handlers::fetch_variation_by_id),
        )
        .route(
            "/api/variations/:variant_id/related",
            get(handlers::fetch_variations_by_variant_id),
        )
        .route(
            "/api/variations/:variant_id/stock",
            get(handlers::check_variant_stock),
        )
        .with_state(database)
}

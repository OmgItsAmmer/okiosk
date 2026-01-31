use axum::{routing::get, Router};
use std::sync::Arc;

use crate::database::Database;
use crate::handlers;

/// Creates category-related routes
/// 
/// This module handles all category endpoints including:
/// - List all categories
/// - Category statistics
/// - Category details by ID
/// 
/// # Arguments
/// * `database` - Shared database connection pool
/// 
/// # Returns
/// Router configured with all category endpoints
pub fn create_category_routes(database: Arc<Database>) -> Router {
    Router::new()
        .route("/api/categories/all", get(handlers::fetch_categories))
        .route("/api/categories/stats", get(handlers::get_category_stats))
        .route(
            "/api/categories/:category_id",
            get(handlers::fetch_category_by_id),
        )
        .with_state(database)
}

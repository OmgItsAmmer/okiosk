use axum::{routing::get, Router};
use std::sync::Arc;

use crate::database::Database;
use crate::handlers;

/// Creates product-related routes
/// 
/// This module handles all product endpoints including:
/// - Product listing with filters
/// - Popular products
/// - Product search and suggestions
/// - Products by category/brand
/// - Product details and variants
/// - Legacy product endpoints for backwards compatibility
/// 
/// # Arguments
/// * `database` - Shared database connection pool
/// 
/// # Returns
/// Router configured with all product endpoints
pub fn create_product_routes(database: Arc<Database>) -> Router {
    Router::new()
        // V1 API endpoints (Express-compatible)
        .route(
            "/api/v1/products",
            get(handlers::get_products_with_filters),
        )
        .route(
            "/api/v1/products/popular",
            get(handlers::get_popular_products_paginated),
        )
        .route(
            "/api/v1/products/search/suggestions",
            get(handlers::get_search_suggestions),
        )
        .route(
            "/api/v1/products/category/:category_id",
            get(handlers::get_products_by_category_paginated),
        )
        .route(
            "/api/v1/products/brand/:brand_id",
            get(handlers::get_products_by_brand_with_response),
        )
        .route(
            "/api/v1/products/:product_id/variants",
            get(handlers::get_product_variants_with_response),
        )
        .route(
            "/api/v1/products/:product_id",
            get(handlers::get_product_by_id_with_response),
        )
        // Legacy endpoints (for backwards compatibility)
        .route(
            "/api/products/popular/count",
            get(handlers::get_popular_products_count),
        )
        .route(
            "/api/products/popular",
            get(handlers::fetch_popular_products),
        )
        .route(
            "/api/products/pos/all",
            get(handlers::fetch_all_products_for_pos),
        )
        .route("/api/products/search", get(handlers::search_products))
        .route("/api/products/stats", get(handlers::get_product_stats))
        .route(
            "/api/products/category/:category_id",
            get(handlers::fetch_products_by_category),
        )
        .route(
            "/api/products/brand/:brand_id",
            get(handlers::fetch_products_by_brand),
        )
        .route(
            "/api/products/:product_id",
            get(handlers::fetch_product_by_id),
        )
        .route(
            "/api/products/:product_id/variations",
            get(handlers::fetch_product_variations),
        )
        .with_state(database)
}

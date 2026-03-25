use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    Json,
};
use serde_json::{json, Value};
use std::sync::Arc;

use crate::{
    database::Database,
    models::{CategoryDetailResponse, CategoryListResponse, CategoryQueryParams},
};

/// Get all categories
/// GET /api/categories/all
pub async fn fetch_categories(
    State(db): State<Arc<Database>>,
    Query(params): Query<CategoryQueryParams>,
) -> Result<Json<CategoryListResponse>, StatusCode> {
    println!("[GET] /api/categories/all → fetching categories...");

    let categories_result = if params.featured_only.unwrap_or(false) {
        db.categories().get_featured_categories().await
    } else {
        db.categories().get_all_categories().await
    };

    match categories_result {
        Ok(categories) => {
            let total_count = categories.len() as i64;
            println!(
                "[OK ] /api/categories/all → fetched {} categories",
                total_count
            );

            Ok(Json(CategoryListResponse {
                categories,
                total_count,
                status: "success".to_string(),
            }))
        }
        Err(e) => {
            tracing::error!("Failed to fetch categories: {}", e);
            println!("[ERR] /api/categories/all → {}", e);
            Err(StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}

/// Get category by ID
/// GET /api/categories/:category_id
pub async fn fetch_category_by_id(
    State(db): State<Arc<Database>>,
    Path(category_id): Path<i32>,
) -> Result<Json<CategoryDetailResponse>, StatusCode> {
    println!(
        "[GET] /api/categories/{} → fetching category...",
        category_id
    );

    match db.categories().get_category_by_id(category_id).await {
        Ok(category) => {
            println!("[OK ] /api/categories/{} → category fetched", category_id);

            Ok(Json(CategoryDetailResponse {
                category,
                status: "success".to_string(),
            }))
        }
        Err(e) => {
            tracing::error!("Failed to fetch category: {}", e);
            println!("[ERR] /api/categories/{} → {}", category_id, e);
            Err(StatusCode::NOT_FOUND)
        }
    }
}

/// Get categories statistics
/// GET /api/categories/stats
pub async fn get_category_stats(
    State(db): State<Arc<Database>>,
) -> Result<Json<Value>, StatusCode> {
    println!("[GET] /api/categories/stats → fetching stats...");

    let total_count = db.categories().get_categories_count().await.ok();
    let featured_count = db.categories().get_featured_categories_count().await.ok();

    println!(
        "[OK ] /api/categories/stats → total={:?}, featured={:?}",
        total_count, featured_count
    );

    Ok(Json(json!({
        "total_categories": total_count,
        "featured_categories": featured_count,
        "status": "success"
    })))
}

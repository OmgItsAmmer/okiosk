use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    Json,
};
use serde_json::{json, Value};
use std::sync::Arc;

use crate::{
    database::Database,
    models::{
        ProductDetailResponse, ProductListResponse, ProductQueryParams, ProductVariation,
        SearchQueryParams,
    },
};

/// Get count of popular products
/// GET /api/products/popular/count
pub async fn get_popular_products_count(
    State(db): State<Arc<Database>>,
) -> Result<Json<Value>, StatusCode> {
    println!("[GET] /api/products/popular/count → fetching count...");
    match db.products().get_popular_products_count().await {
        Ok(count) => Ok(Json(json!({
            "count": count,
            "status": "success"
        }))),
        Err(e) => {
            tracing::error!("Failed to get popular products count: {}", e);
            println!("[ERR] /api/products/popular/count → {}", e);
            Err(StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}

/// Fetch popular products with pagination
/// GET /api/products/popular?limit=10&offset=0
pub async fn fetch_popular_products(
    State(db): State<Arc<Database>>,
    Query(params): Query<ProductQueryParams>,
) -> Result<Json<ProductListResponse>, StatusCode> {
    let limit = params.limit.unwrap_or(10);
    let offset = params.offset.unwrap_or(0);
    println!(
        "[GET] /api/products/popular → fetching (limit={}, offset={})...",
        limit, offset
    );
    match db.products().fetch_popular_products(limit, offset).await {
        Ok(products) => {
            let fetched_count = products.len() as i64;

            // Get total count to determine if there are more products
            let total_count = db.products().get_popular_products_count().await.ok();
            let has_more = if let Some(total) = total_count {
                offset + fetched_count < total
            } else {
                fetched_count >= limit
            };

            println!(
                "[OK ] /api/products/popular → fetched {} (has_more={})",
                fetched_count, has_more
            );

            Ok(Json(ProductListResponse {
                products,
                total_count,
                fetched_count,
                offset: Some(offset),
                has_more,
            }))
        }
        Err(e) => {
            tracing::error!("Failed to fetch popular products: {}", e);
            println!("[ERR] /api/products/popular → {}", e);
            Err(StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}

/// Fetch all products for POS system
/// GET /api/products/pos/all
pub async fn fetch_all_products_for_pos(
    State(db): State<Arc<Database>>,
) -> Result<Json<ProductListResponse>, StatusCode> {
    println!("[GET] /api/products/pos/all → fetching all visible products...");
    match db.products().fetch_all_products_for_pos().await {
        Ok(products) => {
            let fetched_count = products.len() as i64;
            println!("[OK ] /api/products/pos/all → fetched {}", fetched_count);
            // println!("Products: {:?}", products);
            Ok(Json(ProductListResponse {
                products,
                total_count: Some(fetched_count),
                fetched_count,
                offset: None,
                has_more: false,
            }))
        }
        Err(e) => {
            tracing::error!("Failed to fetch POS products: {}", e);
            println!("[ERR] /api/products/pos/all → {}", e);
            Err(StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}

/// Fetch products by category with pagination
/// GET /api/products/category/{category_id}?page=0&page_size=20
pub async fn fetch_products_by_category(
    State(db): State<Arc<Database>>,
    Path(category_id): Path<i32>,
    Query(params): Query<ProductQueryParams>,
) -> Result<Json<ProductListResponse>, StatusCode> {
    let page = params.page.unwrap_or(0);
    let page_size = params.page_size.unwrap_or(20);
    println!(
        "[GET] /api/products/category/{} → page={}, size={}...",
        category_id, page, page_size
    );
    match db
        .products()
        .fetch_products_by_category(category_id, page, page_size)
        .await
    {
        Ok(products) => {
            let fetched_count = products.len() as i64;
            let has_more = fetched_count >= page_size;

            // Optionally get total count for the category
            let total_count = db
                .products()
                .get_category_products_count(category_id)
                .await
                .ok();

            println!(
                "[OK ] /api/products/category/{} → fetched {} (has_more={})",
                category_id, fetched_count, has_more
            );

            Ok(Json(ProductListResponse {
                products,
                total_count,
                fetched_count,
                offset: Some(page * page_size),
                has_more,
            }))
        }
        Err(e) => {
            tracing::error!("Failed to fetch products by category: {}", e);
            println!("[ERR] /api/products/category/{} → {}", category_id, e);
            Err(StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}

/// Fetch products by brand
/// GET /api/products/brand/{brand_id}
pub async fn fetch_products_by_brand(
    State(db): State<Arc<Database>>,
    Path(brand_id): Path<i32>,
) -> Result<Json<ProductListResponse>, StatusCode> {
    println!("[GET] /api/products/brand/{} → fetching...", brand_id);
    match db.products().fetch_products_by_brand(brand_id).await {
        Ok(products) => {
            let fetched_count = products.len() as i64;
            println!(
                "[OK ] /api/products/brand/{} → fetched {}",
                brand_id, fetched_count
            );

            Ok(Json(ProductListResponse {
                products,
                total_count: Some(fetched_count),
                fetched_count,
                offset: None,
                has_more: false,
            }))
        }
        Err(e) => {
            tracing::error!("Failed to fetch products by brand: {}", e);
            println!("[ERR] /api/products/brand/{} → {}", brand_id, e);
            Err(StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}

/// Search products by name or description
/// GET /api/products/search?query=shirt&page=0&page_size=20
pub async fn search_products(
    State(db): State<Arc<Database>>,
    Query(params): Query<SearchQueryParams>,
) -> Result<Json<ProductListResponse>, StatusCode> {
    let page = params.page.unwrap_or(0);
    let page_size = params.page_size.unwrap_or(20);
    println!(
        "[GET] /api/products/search → query='{}', page={}, size={}...",
        params.query, page, page_size
    );

    match db
        .products()
        .search_products(&params.query, page, page_size)
        .await
    {
        Ok(products) => {
            let fetched_count = products.len() as i64;
            let has_more = fetched_count >= page_size;
            println!(
                "[OK ] /api/products/search → fetched {} (has_more={})",
                fetched_count, has_more
            );

            Ok(Json(ProductListResponse {
                products,
                total_count: None, // Search doesn't return total count
                fetched_count,
                offset: Some(page * page_size),
                has_more,
            }))
        }
        Err(e) => {
            tracing::error!("Failed to search products: {}", e);
            println!("[ERR] /api/products/search → {}", e);
            Err(StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}

/// Fetch product by ID with variations
/// GET /api/products/{product_id}
pub async fn fetch_product_by_id(
    State(db): State<Arc<Database>>,
    Path(product_id): Path<i32>,
) -> Result<Json<ProductDetailResponse>, StatusCode> {
    println!(
        "[GET] /api/products/{} → fetching product & variations...",
        product_id
    );
    // Fetch product and variations in parallel
    let product_result = db.products().fetch_product_by_id(product_id).await;
    let variations_result = db.products().fetch_product_variations(product_id).await;

    match (product_result, variations_result) {
        (Ok(product), Ok(product_variants)) => {
            println!(
                "[OK ] /api/products/{} → product ok, {} variations",
                product_id,
                product_variants.len()
            );
            Ok(Json(ProductDetailResponse {
                product,
                product_variants,
            }))
        }
        (Err(e), _) => {
            tracing::error!("Failed to fetch product: {}", e);
            println!("[ERR] /api/products/{} → product error: {}", product_id, e);
            Err(StatusCode::NOT_FOUND)
        }
        (_, Err(e)) => {
            tracing::error!("Failed to fetch product variations: {}", e);
            println!(
                "[ERR] /api/products/{} → variations error: {}",
                product_id, e
            );
            Err(StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}

/// Fetch product variations by product ID
/// GET /api/products/{product_id}/variations
pub async fn fetch_product_variations(
    State(db): State<Arc<Database>>,
    Path(product_id): Path<i32>,
) -> Result<Json<Vec<ProductVariation>>, StatusCode> {
    println!(
        "[GET] /api/products/{}/variations → fetching...",
        product_id
    );
    match db.products().fetch_product_variations(product_id).await {
        Ok(variations) => Ok(Json(variations)),
        Err(e) => {
            tracing::error!("Failed to fetch product variations: {}", e);
            println!("[ERR] /api/products/{}/variations → {}", product_id, e);
            Err(StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}

/// Fetch product variation by variant ID
/// GET /api/variations/{variant_id}
pub async fn fetch_variation_by_id(
    State(db): State<Arc<Database>>,
    Path(variant_id): Path<i32>,
) -> Result<Json<ProductVariation>, StatusCode> {
    println!("[GET] /api/variations/{} → fetching...", variant_id);
    match db.products().fetch_variation_by_id(variant_id).await {
        Ok(variation) => Ok(Json(variation)),
        Err(e) => {
            tracing::error!("Failed to fetch variation: {}", e);
            println!("[ERR] /api/variations/{} → {}", variant_id, e);
            Err(StatusCode::NOT_FOUND)
        }
    }
}

/// Fetch all variations for a product given a variant ID
/// GET /api/variations/{variant_id}/related
pub async fn fetch_variations_by_variant_id(
    State(db): State<Arc<Database>>,
    Path(variant_id): Path<i32>,
) -> Result<Json<Vec<ProductVariation>>, StatusCode> {
    println!(
        "[GET] /api/variations/{}/related → fetching related...",
        variant_id
    );
    match db
        .products()
        .fetch_variations_by_variant_id(variant_id)
        .await
    {
        Ok(variations) => {
            println!(
                "[OK ] /api/variations/{}/related → fetched {}",
                variant_id,
                variations.len()
            );
            Ok(Json(variations))
        }
        Err(e) => {
            tracing::error!("Failed to fetch variations by variant ID: {}", e);
            println!("[ERR] /api/variations/{}/related → {}", variant_id, e);
            Err(StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}

/// Check stock for a specific variant
/// GET /api/variations/{variant_id}/stock
pub async fn check_variant_stock(
    State(db): State<Arc<Database>>,
    Path(variant_id): Path<i32>,
) -> Result<Json<Value>, StatusCode> {
    println!("[GET] /api/variations/{}/stock → checking...", variant_id);
    match db.products().check_variant_stock(variant_id).await {
        Ok(stock) => Ok(Json(json!({
            "variant_id": variant_id,
            "stock": stock,
            "in_stock": stock > 0,
            "status": "success"
        }))),
        Err(e) => {
            tracing::error!("Failed to check variant stock: {}", e);
            println!("[ERR] /api/variations/{}/stock → {}", variant_id, e);
            Err(StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}

/// Get statistics about products
/// GET /api/products/stats
pub async fn get_product_stats(State(db): State<Arc<Database>>) -> Result<Json<Value>, StatusCode> {
    let total_count = db.products().get_total_products_count().await.ok();
    let popular_count = db.products().get_popular_products_count().await.ok();

    println!(
        "[GET] /api/products/stats → total={:?}, popular={:?}",
        total_count, popular_count
    );

    Ok(Json(json!({
        "total_products": total_count,
        "popular_products": popular_count,
        "status": "success"
    })))
}

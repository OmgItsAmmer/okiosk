use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;

/// Category model matching the database schema
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Category {
    pub category_id: i32,
    pub category_name: String,
    #[serde(rename = "isFeatured")]
    pub is_featured: Option<bool>, // Can be null in DB, defaults to false
    pub created_at: Option<DateTime<Utc>>, // Can be null in DB, defaults to now()
    pub product_count: Option<i32>,        // Can be null in DB
}

/// Request models for filtering
#[derive(Debug, Deserialize)]
pub struct CategoryQueryParams {
    pub featured_only: Option<bool>,
}

/// Response models
#[derive(Debug, Serialize)]
pub struct CategoryListResponse {
    pub categories: Vec<Category>,
    pub total_count: i64,
    pub status: String,
}

#[derive(Debug, Serialize)]
pub struct CategoryDetailResponse {
    pub category: Category,
    pub status: String,
}

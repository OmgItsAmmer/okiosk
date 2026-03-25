use chrono::{DateTime, Utc};
use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};
use sqlx::FromRow;

/// Product model matching the Supabase schema and Flutter ProductModel
    #[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Product {
    pub product_id: i32,
    pub name: String,
    pub description: Option<String>,
    pub price_range: String,
    pub base_price: String,
    pub sale_price: String,
    pub category_id: Option<i32>,
    pub ispopular: bool,
    pub stock_quantity: i32,
    pub created_at: Option<DateTime<Utc>>,
    #[serde(rename = "brandID")]
    pub brand_id: Option<i32>,
    pub alert_stock: Option<i32>,
    #[serde(rename = "isVisible")]
    pub is_visible: bool,
    pub tag: Option<String>,
    pub image_url: Option<String>,
}

/// Product with embedded variations for detailed views
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProductWithVariations {
    #[serde(flatten)]
    pub product: Product,
    pub product_variants: Vec<ProductVariation>,
}

/// Product variation model matching the Supabase schema and Flutter ProductVariationModel
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct ProductVariation {
    pub variant_id: i32,
    pub sell_price: Decimal,
    pub buy_price: Decimal,
    pub product_id: i32,
    pub variant_name: String,
    pub stock: i32,
    pub is_visible: bool,
}

/// Request models for filtering and pagination
#[derive(Debug, Deserialize)]
pub struct ProductQueryParams {
    pub limit: Option<i64>,
    pub offset: Option<i64>,
    pub page: Option<i64>,
    pub page_size: Option<i64>,
}

#[derive(Debug, Deserialize)]
pub struct SearchQueryParams {
    pub query: String,
    pub page: Option<i64>,
    pub page_size: Option<i64>,
}

/// Response models
#[derive(Debug, Serialize)]
pub struct ProductListResponse {
    pub products: Vec<Product>,
    pub total_count: Option<i64>,
    pub fetched_count: i64,
    pub offset: Option<i64>,
    pub has_more: bool,
}

#[derive(Debug, Serialize)]
pub struct ProductDetailResponse {
    pub product: Product,
    pub product_variants: Vec<ProductVariation>,
}

#[derive(Debug, Serialize)]
pub struct PopularProductsCountResponse {
    pub count: i64,
}

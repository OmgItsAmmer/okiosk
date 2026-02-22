use chrono::{DateTime, Utc};
use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};
use sqlx::FromRow;

/// Cart model - represents a cart entry in the cart table
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Cart {
    pub cart_id: i32,
    pub variant_id: Option<i32>,
    pub quantity: i32,
    pub customer_id: Option<i32>,
    pub kiosk_session_id: Option<String>,
}

/// Guest Cart Item - In-memory representation for guests
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GuestCartItem {
    pub variant_id: i32,
    pub quantity: i32,
    pub added_at: i64,
}

/// Kiosk Cart model - represents entries in kiosk_cart table
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct KioskCart {
    pub kiosk_id: i32,
    pub kiosk_session_id: String,
    pub variant_id: i32,
    pub quantity: i32,
    pub created_at: Option<DateTime<Utc>>,
}

/// Complete cart item with product and variant details
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CartItem {
    // Cart data
    pub cart_id: i32,
    pub variant_id: Option<i32>,
    pub quantity: i32,
    pub customer_id: Option<i32>,
    pub kiosk_session_id: Option<String>,

    // Product data
    pub product_id: i32,
    pub product_name: String,
    pub product_description: Option<String>,
    pub image_url: Option<String>,
    pub base_price: String,
    pub sale_price: String,
    #[serde(rename = "brandID")]
    pub brand_id: Option<i32>,

    // Variant data
    pub variant_name: String,
    pub sell_price: Decimal,
    pub buy_price: Option<Decimal>,
    pub stock: i32,
    pub is_visible: bool,
}

/// Cart stock validation result
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CartStockValidation {
    pub cart_id: i32,
    pub variant_id: i32,
    pub product_name: String,
    pub variant_name: String,
    pub current_quantity: i32,
    pub available_stock: i32,
    pub suggested_quantity: i32,
    pub needs_adjustment: bool,
    pub adjustment_reason: String,
    pub should_remove: bool,
}

/// Request models
#[derive(Debug, Deserialize)]
pub struct AddToCartRequest {
    pub variant_id: i32,
    pub quantity: i32,
}

#[derive(Debug, Deserialize)]
pub struct UpdateCartQuantityRequest {
    pub quantity: i32,
}

#[derive(Debug, Deserialize)]
pub struct AddToKioskCartRequest {
    pub kiosk_session_id: String,
    pub variant_id: i32,
    pub quantity: i32,
}

#[derive(Debug, Deserialize)]
pub struct UpdateGuestCartRequest {
    pub variant_id: i32,
    pub quantity: i32,
}

/// Response models
#[derive(Debug, Serialize)]
pub struct CartListResponse {
    pub items: Vec<CartItem>,
    pub total_items: i32,
    pub subtotal: f64,
    pub status: String,
}

#[derive(Debug, Serialize)]
pub struct CartOperationResponse {
    pub success: bool,
    pub message: String,
}

#[derive(Debug, Serialize)]
pub struct CartValidationResponse {
    pub has_issues: bool,
    pub adjustments: Vec<CartStockValidation>,
}

// ===== Checkout Models =====

/// Direct checkout item (for buy now functionality)
#[derive(Debug, Clone, Deserialize)]
pub struct DirectCheckoutItem {
    pub variant_id: i32,
    pub quantity: i32,
    pub price: Decimal,
}

/// Cart item for checkout processing
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CheckoutCartItem {
    #[serde(rename = "variantId")]
    pub variant_id: i32,
    pub quantity: i32,
    #[serde(rename = "sellPrice")]
    pub sell_price: Decimal,
    #[serde(rename = "buyPrice")]
    pub buy_price: Option<Decimal>,
}

/// Checkout request
#[derive(Debug, Deserialize)]
pub struct CheckoutRequest {
    #[serde(rename = "customerId")]
    pub customer_id: i32,
    #[serde(rename = "addressId")]
    pub address_id: i32, // -1 for pickup, 0 for invalid, >0 for valid address
    #[serde(rename = "shippingMethod")]
    pub shipping_method: String, // "pickup" or "shipping"
    #[serde(rename = "paymentMethod")]
    pub payment_method: String, // "cod", "pickup", "credit_card", "bank_transfer", "jazzcash"
    #[serde(rename = "cartItems")]
    pub cart_items: Option<Vec<CheckoutCartItem>>,
    #[serde(rename = "directCheckout")]
    pub direct_checkout: Option<DirectCheckoutItem>,
    #[serde(rename = "idempotencyKey")]
    pub idempotency_key: Option<String>,
}

/// Order totals
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OrderTotals {
    pub subtotal: Decimal,
    pub tax: Decimal,
    pub shipping: Decimal,
    pub discount: Decimal,
    pub total: Decimal,
    pub cost: Decimal,
}

/// Checkout response
#[derive(Debug, Serialize)]
pub struct CheckoutResponse {
    pub success: bool,
    pub message: String,
    #[serde(rename = "orderId", skip_serializing_if = "Option::is_none")]
    pub order_id: Option<i32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub total: Option<Decimal>,
    #[serde(rename = "errorCode", skip_serializing_if = "Option::is_none")]
    pub error_code: Option<String>,
}

/// Inventory reservation item for database function
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "cart_item_type")]
pub struct InventoryReservationItem {
    #[serde(rename = "variantId")]
    pub variant_id: i32,
    pub quantity: i32,
}

use chrono::NaiveDate;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct Order {
    pub order_id: i32,
    pub order_date: NaiveDate,
    pub sub_total: rust_decimal::Decimal,
    pub status: String,
    pub saletype: Option<String>,
    pub address_id: Option<i32>,
    pub paid_amount: Option<rust_decimal::Decimal>,
    pub buying_price: Option<rust_decimal::Decimal>,
    pub discount: Option<rust_decimal::Decimal>,
    pub tax: Option<rust_decimal::Decimal>,
    pub shipping_fee: Option<rust_decimal::Decimal>,
    pub user_id: Option<i32>,
    pub customer_id: Option<i32>,
    pub idempotency_key: Option<String>,
    pub payment_method: Option<String>,
    pub salesman_id: Option<i32>,
    pub salesman_comission: Option<i32>,
    pub shipping_method: Option<String>,
}

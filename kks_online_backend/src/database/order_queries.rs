use crate::models::{CheckoutCartItem, OrderTotals};
use rust_decimal::Decimal;
use serde_json::json;
use sqlx::{PgPool, Row};

/// Order database queries
pub struct OrderQueries<'a> {
    pool: &'a PgPool,
}

impl<'a> OrderQueries<'a> {
    pub fn new(pool: &'a PgPool) -> Self {
        Self { pool }
    }

    /// Get reference to the pool
    pub fn pool(&self) -> &'a PgPool {
        self.pool
    }

    /// Check if order with idempotency key already exists (duplicate check)
    pub async fn check_duplicate_order(&self, idempotency_key: &str) -> Result<bool, sqlx::Error> {
        println!(
            "[DB] Checking for duplicate order with key: {}",
            idempotency_key
        );

        let result = sqlx::query("SELECT order_id FROM orders WHERE idempotency_key = $1 LIMIT 1")
            .bind(idempotency_key)
            .fetch_optional(self.pool)
            .await?;

        let is_duplicate = result.is_some();
        println!("[DB] Duplicate check result: {}", is_duplicate);
        Ok(is_duplicate)
    }

    /// Validate shipping method
    pub async fn validate_shipping_method(
        &self,
        shipping_method: &str,
        address_id: i32,
    ) -> Result<(bool, String), sqlx::Error> {
        println!(
            "[DB] Validating shipping method: {} with address_id: {}",
            shipping_method, address_id
        );

        // Check shop settings
        let shop_result = sqlx::query("SELECT is_shipping_enable FROM shop LIMIT 1")
            .fetch_optional(self.pool)
            .await?;

        let is_shipping_allowed = shop_result
            .map(|row| {
                row.get::<Option<bool>, _>("is_shipping_enable")
                    .unwrap_or(false)
            })
            .unwrap_or(false);

        println!("[DB] Shop shipping allowed: {}", is_shipping_allowed);

        if shipping_method == "pickup" {
            return Ok((true, "Pickup is valid".to_string()));
        }

        if shipping_method == "shipping" {
            if !is_shipping_allowed {
                return Ok((
                    false,
                    "Shipping is not available. Please select pickup instead.".to_string(),
                ));
            }

            if address_id <= 0 {
                return Ok((
                    false,
                    "Valid shipping address required for delivery.".to_string(),
                ));
            }

            // Verify address exists
            let address_exists =
                sqlx::query("SELECT address_id FROM addresses WHERE address_id = $1")
                    .bind(address_id)
                    .fetch_optional(self.pool)
                    .await?;

            if address_exists.is_none() {
                return Ok((false, "Selected shipping address not found.".to_string()));
            }

            return Ok((true, "Shipping is valid".to_string()));
        }

        Ok((
            false,
            format!("Invalid shipping method: {}", shipping_method),
        ))
    }

    /// Validate cart security (price validation, stock availability)
    pub async fn validate_cart_security(
        &self,
        cart_items: &[CheckoutCartItem],
    ) -> Result<(bool, String, OrderTotals), sqlx::Error> {
        println!(
            "[DB] Validating cart security for {} items",
            cart_items.len()
        );

        // Fetch shop settings for max quantity
        let max_allowed_quantity = self.get_max_allowed_item_quantity().await?;
        println!("[DB] Max allowed item quantity: {}", max_allowed_quantity);

        // Fetch variant IDs
        let variant_ids: Vec<i32> = cart_items.iter().map(|item| item.variant_id).collect();

        // Fetch product data from database
        let db_products = sqlx::query(
            r#"
            SELECT 
                pv.variant_id,
                pv.sell_price,
                pv.buy_price,
                pv.is_visible,
                pv.stock,
                p.product_id,
                p.name,
                p."isVisible" as product_visible
            FROM product_variants pv
            INNER JOIN products p ON pv.product_id = p.product_id
            WHERE pv.variant_id = ANY($1)
            "#,
        )
        .bind(&variant_ids)
        .fetch_all(self.pool)
        .await?;

        // Create lookup map
        let mut db_product_map = std::collections::HashMap::new();
        for row in db_products {
            let variant_id: i32 = row.get("variant_id");
            db_product_map.insert(variant_id, row);
        }

        // Validate each cart item
        for cart_item in cart_items {
            let db_product = match db_product_map.get(&cart_item.variant_id) {
                Some(p) => p,
                None => {
                    return Ok((
                        false,
                        format!("Product no longer available (ID: {})", cart_item.variant_id),
                        OrderTotals::default(),
                    ));
                }
            };

            // Check visibility
            let is_visible: bool = db_product.get("is_visible");
            let product_visible: bool = db_product.get("product_visible");

            if !is_visible || !product_visible {
                let product_name: String = db_product.get("name");
                return Ok((
                    false,
                    format!("Product {} is no longer available", product_name),
                    OrderTotals::default(),
                ));
            }

            // Validate price integrity
            let db_price: Decimal = db_product.get("sell_price");
            let price_diff = (db_price - cart_item.sell_price).abs();

            if price_diff > Decimal::new(1, 2) {
                // 0.01 tolerance
                let product_name: String = db_product.get("name");

                // Log security event
                self.log_security_event(
                    "price_manipulation_detected",
                    json!({
                        "variant_id": cart_item.variant_id,
                        "cart_price": cart_item.sell_price.to_string(),
                        "db_price": db_price.to_string(),
                        "product_name": product_name
                    }),
                    None,
                )
                .await
                .ok();

                return Ok((
                    false,
                    "Price mismatch detected. Please refresh and try again.".to_string(),
                    OrderTotals::default(),
                ));
            }

            // Validate stock availability
            let stock: i32 = db_product.get("stock");
            if cart_item.quantity > stock {
                let product_name: String = db_product.get("name");
                return Ok((
                    false,
                    format!("{} - Only {} available", product_name, stock),
                    OrderTotals::default(),
                ));
            }

            // Validate quantity constraints
            if cart_item.quantity <= 0 || cart_item.quantity > max_allowed_quantity {
                return Ok((
                    false,
                    format!(
                        "Invalid quantity. Must be between 1 and {}.",
                        max_allowed_quantity
                    ),
                    OrderTotals::default(),
                ));
            }
        }

        // Calculate totals
        let totals = self.calculate_secure_totals(cart_items).await?;

        // Validate business rules (PKR)
        if totals.total < Decimal::new(10, 0) {
            return Ok((
                false,
                "Minimum order amount is PKR 10.00".to_string(),
                totals,
            ));
        }

        if totals.total > Decimal::new(500000, 0) {
            return Ok((
                false,
                "Maximum order amount is PKR 500,000.00".to_string(),
                totals,
            ));
        }

        println!("[DB] Cart security validation passed");
        Ok((true, "Valid".to_string(), totals))
    }

    /// Calculate secure totals server-side
    pub async fn calculate_secure_totals(
        &self,
        cart_items: &[CheckoutCartItem],
    ) -> Result<OrderTotals, sqlx::Error> {
        println!(
            "[DB] Calculating secure totals for {} items",
            cart_items.len()
        );

        let mut subtotal = Decimal::new(0, 0);
        let mut total_cost = Decimal::new(0, 0);

        for item in cart_items {
            let item_total = item.sell_price * Decimal::from(item.quantity);
            let item_cost =
                item.buy_price.unwrap_or(Decimal::new(0, 0)) * Decimal::from(item.quantity);

            subtotal += item_total;
            total_cost += item_cost;
        }

        // Fetch fixed tax amount from shop table
        let tax_result = sqlx::query("SELECT taxrate FROM shop LIMIT 1")
            .fetch_optional(self.pool)
            .await?;

        let tax = tax_result
            .and_then(|row| row.get::<Option<Decimal>, _>("taxrate"))
            .unwrap_or(Decimal::new(0, 0));

        println!("[DB] Tax amount: {}", tax);

        let shipping = Decimal::new(0, 0); // No shipping fee yet
        let discount = Decimal::new(0, 0); // No discount logic yet
        let total = subtotal + tax + shipping - discount;

        let totals = OrderTotals {
            subtotal,
            tax,
            shipping,
            discount,
            total,
            cost: total_cost,
        };

        println!("[DB] Calculated totals: {:?}", totals);
        Ok(totals)
    }

    /// Reserve inventory atomically using database function
    pub async fn reserve_inventory(
        &self,
        reservation_id: &str,
        cart_items: &[CheckoutCartItem],
    ) -> Result<(bool, String), sqlx::Error> {
        println!(
            "[DB] Reserving inventory with reservation_id: {}",
            reservation_id
        );

        // Prepare cart items for the database function
        let db_cart_items: Vec<serde_json::Value> = cart_items
            .iter()
            .map(|item| {
                json!({
                    "variantId": item.variant_id,
                    "quantity": item.quantity
                })
            })
            .collect();

        // Call the atomic inventory reservation function
        let result = sqlx::query(
            r#"
            SELECT success, message, error_details 
            FROM reserve_inventory_secure($1, $2::jsonb)
            "#,
        )
        .bind(reservation_id)
        .bind(serde_json::to_value(&db_cart_items).unwrap())
        .fetch_one(self.pool)
        .await?;

        let success: bool = result.get("success");
        let message: String = result.get("message");

        if !success {
            println!("[DB] Inventory reservation failed: {}", message);
            return Ok((false, message));
        }

        println!("[DB] Inventory reserved successfully");
        Ok((true, "Inventory reserved successfully".to_string()))
    }

    /// Create order
    pub async fn create_order(
        &self,
        customer_id: i32,
        cart_items: &[CheckoutCartItem],
        address_id: i32,
        shipping_method: &str,
        payment_method: &str,
        totals: &OrderTotals,
        idempotency_key: &str,
    ) -> Result<(bool, String, Option<i32>), sqlx::Error> {
        println!("[DB] Creating order for customer_id: {}", customer_id);

        // Handle address copying for valid addresses
        if address_id > 0 {
            let copy_result = sqlx::query("SELECT copy_address_to_order_address($1)")
                .bind(address_id)
                .fetch_one(self.pool)
                .await;

            match copy_result {
                Ok(row) => {
                    let success: Option<bool> = row.get(0);
                    if success != Some(true) {
                        println!("[DB] Address copy failed for address_id: {}", address_id);
                        return Ok((
                            false,
                            "Address not found. Please select a valid address.".to_string(),
                            None,
                        ));
                    }
                }
                Err(e) => {
                    println!("[DB] Error copying address: {}", e);
                    return Ok((false, "Address processing failed".to_string(), None));
                }
            }
        }

        // Fetch product_id for each variant_id
        let variant_ids: Vec<i32> = cart_items.iter().map(|item| item.variant_id).collect();
        let variant_rows = sqlx::query(
            "SELECT variant_id, product_id FROM product_variants WHERE variant_id = ANY($1)",
        )
        .bind(&variant_ids)
        .fetch_all(self.pool)
        .await?;

        let mut variant_to_product_map = std::collections::HashMap::new();
        for row in variant_rows {
            let variant_id: i32 = row.get("variant_id");
            let product_id: i32 = row.get("product_id");
            variant_to_product_map.insert(variant_id, product_id);
        }

        // Create order
        let order_result = sqlx::query(
            r#"
            INSERT INTO orders (
                customer_id, status, sub_total, tax, shipping_fee, 
                discount, paid_amount, buying_price, address_id, 
                order_date, shipping_method, payment_method, idempotency_key
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
            RETURNING order_id
            "#,
        )
        .bind(customer_id)
        .bind("pending")
        .bind(&totals.subtotal)
        .bind(&totals.tax)
        .bind(&totals.shipping)
        .bind(&totals.discount)
        .bind(&totals.total)
        .bind(&totals.cost)
        .bind(if address_id > 0 {
            Some(address_id)
        } else {
            None
        })
        .bind(chrono::Utc::now().naive_utc().date())
        .bind(shipping_method)
        .bind(payment_method)
        .bind(idempotency_key)
        .fetch_one(self.pool)
        .await?;

        let order_id: i32 = order_result.get("order_id");
        println!("[DB] Order created with order_id: {}", order_id);

        // Create order items
        for item in cart_items {
            let product_id = variant_to_product_map
                .get(&item.variant_id)
                .ok_or_else(|| sqlx::Error::RowNotFound)?;

            sqlx::query(
                r#"
                INSERT INTO order_items (
                    order_id, product_id, variant_id, quantity, price, total_buy_price
                ) VALUES ($1, $2, $3, $4, $5, $6)
                "#,
            )
            .bind(order_id)
            .bind(product_id)
            .bind(item.variant_id)
            .bind(item.quantity)
            .bind(&item.sell_price)
            .bind(&(item.buy_price.unwrap_or(Decimal::new(0, 0)) * Decimal::from(item.quantity)))
            .execute(self.pool)
            .await?;
        }

        println!("[DB] Order items created for order_id: {}", order_id);
        Ok((
            true,
            "Order created successfully".to_string(),
            Some(order_id),
        ))
    }

    /// Confirm inventory reservation (reduce actual stock)
    pub async fn confirm_inventory_reservation(
        &self,
        reservation_id: &str,
    ) -> Result<(), sqlx::Error> {
        println!("[DB] Confirming inventory reservation: {}", reservation_id);

        sqlx::query("SELECT confirm_inventory_reservation($1)")
            .bind(reservation_id)
            .execute(self.pool)
            .await?;

        println!("[DB] Inventory reservation confirmed");
        Ok(())
    }

    /// Rollback inventory reservation
    pub async fn rollback_inventory_reservation(
        &self,
        reservation_id: &str,
    ) -> Result<(), sqlx::Error> {
        println!(
            "[DB] Rolling back inventory reservation: {}",
            reservation_id
        );

        sqlx::query("DELETE FROM inventory_reservations WHERE reservation_id = $1")
            .bind(reservation_id)
            .execute(self.pool)
            .await?;

        println!("[DB] Inventory reservation rolled back");
        Ok(())
    }

    /// Clear customer cart
    pub async fn clear_customer_cart(&self, customer_id: i32) -> Result<(), sqlx::Error> {
        println!("[DB] Clearing cart for customer_id: {}", customer_id);

        sqlx::query("DELETE FROM cart WHERE customer_id = $1")
            .bind(customer_id)
            .execute(self.pool)
            .await?;

        println!("[DB] Cart cleared");
        Ok(())
    }

    /// Log security event
    pub async fn log_security_event(
        &self,
        event_type: &str,
        event_data: serde_json::Value,
        customer_id: Option<i32>,
    ) -> Result<(), sqlx::Error> {
        println!("[DB] Logging security event: {}", event_type);

        let severity = match event_type {
            "price_manipulation_detected" | "checkout_error" => "critical",
            "cart_validation_failed" | "inventory_unavailable" => "warning",
            _ => "info",
        };

        sqlx::query(
            r#"
            INSERT INTO security_audit_log (
                event_type, event_data, timestamp, ip_address, 
                user_agent, customer_id, severity
            ) VALUES ($1, $2, $3, $4, $5, $6, $7)
            "#,
        )
        .bind(event_type)
        .bind(&event_data)
        .bind(chrono::Utc::now())
        .bind("backend_server")
        .bind("rust_backend")
        .bind(customer_id)
        .bind(severity)
        .execute(self.pool)
        .await?;

        Ok(())
    }

    /// Get max allowed item quantity from shop settings
    async fn get_max_allowed_item_quantity(&self) -> Result<i32, sqlx::Error> {
        let result = sqlx::query("SELECT max_allowed_item_quantity FROM shop LIMIT 1")
            .fetch_optional(self.pool)
            .await?;

        // Column is INT8 (BIGINT) in DB; read as i64 and clamp/cast to i32 safely
        let value_i32 = result
            .and_then(|row| row.get::<Option<i64>, _>("max_allowed_item_quantity"))
            .map(|v| {
                if v <= i64::from(i32::MAX) {
                    v as i32
                } else {
                    i32::MAX
                }
            })
            .unwrap_or(50);

        Ok(value_i32)
    }

    /// Verify customer exists and has phone number
    pub async fn verify_customer(&self, customer_id: i32) -> Result<(bool, String), sqlx::Error> {
        println!("[DB] Verifying customer_id: {}", customer_id);

        let result = sqlx::query("SELECT phone_number FROM customers WHERE customer_id = $1")
            .bind(customer_id)
            .fetch_optional(self.pool)
            .await?;

        match result {
            Some(row) => {
                let phone_number: Option<String> = row.get("phone_number");
                match phone_number {
                    Some(phone) if !phone.trim().is_empty() => {
                        Ok((true, "Customer verified".to_string()))
                    }
                    _ => Ok((
                        false,
                        "Phone number required for checkout. Please add your phone number to your profile.".to_string(),
                    )),
                }
            }
            None => Ok((false, "Customer not found".to_string())),
        }
    }
}

// Default implementation for OrderTotals
impl Default for OrderTotals {
    fn default() -> Self {
        Self {
            subtotal: Decimal::new(0, 0),
            tax: Decimal::new(0, 0),
            shipping: Decimal::new(0, 0),
            discount: Decimal::new(0, 0),
            total: Decimal::new(0, 0),
            cost: Decimal::new(0, 0),
        }
    }
}

use crate::models::{CartItem, CartStockValidation};
use sqlx::{PgPool, Row};

/// Cart database queries
pub struct CartQueries<'a> {
    pool: &'a PgPool,
}

impl<'a> CartQueries<'a> {
    pub fn new(pool: &'a PgPool) -> Self {
        Self { pool }
    }

    /// Fetch complete cart items for a customer with product and variant details
    pub async fn fetch_complete_cart_items(
        &self,
        customer_id: i32,
    ) -> Result<Vec<CartItem>, sqlx::Error> {
        println!("[DB] Fetching cart items for customer_id: {}", customer_id);

        let rows = sqlx::query(
            r#"
            SELECT 
                c.cart_id,
                c.variant_id,
                c.quantity,
                c.customer_id,
                c.kiosk_session_id,
                p.product_id,
                p.name as product_name,
                p.description as product_description,
                COALESCE(p.base_price, '1000')::text as base_price,
                COALESCE(p.sale_price, '1000')::text as sale_price,
                p."brandID" as brand_id,
                pv.variant_name,
                pv.sell_price,
                pv.buy_price,
                COALESCE(pv.stock, 0) as stock,
                COALESCE(pv.is_visible, true) as is_visible
            FROM cart c
            INNER JOIN product_variants pv ON c.variant_id = pv.variant_id
            INNER JOIN products p ON pv.product_id = p.product_id
            WHERE c.customer_id = $1
            ORDER BY c.cart_id DESC
            "#,
        )
        .bind(customer_id)
        .fetch_all(self.pool)
        .await?;

        let mut items = Vec::new();
        for row in rows {
            items.push(CartItem {
                cart_id: row.get("cart_id"),
                variant_id: row.get("variant_id"),
                quantity: match row.try_get::<i32, &str>("quantity") {
                    Ok(qty) => qty,
                    Err(_) => row.get::<String, &str>("quantity").parse().unwrap_or(0),
                },
                customer_id: row.get("customer_id"),
                kiosk_session_id: row.get("kiosk_session_id"),
                product_id: row.get("product_id"),
                product_name: row.get("product_name"),
                product_description: row.get("product_description"),
                base_price: row.get("base_price"),
                sale_price: row.get("sale_price"),
                brand_id: row.get("brand_id"),
                variant_name: row.get("variant_name"),
                sell_price: row.get("sell_price"),
                buy_price: row.get("buy_price"),
                stock: row.get("stock"),
                is_visible: row.get("is_visible"),
            });
        }

        println!("[DB] Fetched {} cart items", items.len());
        Ok(items)
    }

    /// Fetch complete kiosk cart items
    pub async fn fetch_complete_kiosk_cart_items(
        &self,
        kiosk_session_id: &str,
    ) -> Result<Vec<CartItem>, sqlx::Error> {
        println!(
            "[DB] Fetching kiosk cart items for session: {}",
            kiosk_session_id
        );

        let rows = sqlx::query(
            r#"
            SELECT 
                kc.kiosk_id as cart_id,
                kc.variant_id,
                kc.quantity,
                NULL::integer as customer_id,
                kc.kiosk_session_id,
                p.product_id,
                p.name as product_name,
                p.description as product_description,
                COALESCE(p.base_price, '1000')::text as base_price,
                COALESCE(p.sale_price, '1000')::text as sale_price,
                p."brandID" as brand_id,
                pv.variant_name,
                pv.sell_price,
                pv.buy_price,
                COALESCE(pv.stock, 0) as stock,
                COALESCE(pv.is_visible, true) as is_visible
            FROM kiosk_cart kc
            INNER JOIN product_variants pv ON kc.variant_id = pv.variant_id
            INNER JOIN products p ON pv.product_id = p.product_id
            WHERE kc.kiosk_session_id = $1
            ORDER BY kc.kiosk_id DESC
            "#,
        )
        .bind(kiosk_session_id)
        .fetch_all(self.pool)
        .await?;

        let mut items = Vec::new();
        for row in rows {
            items.push(CartItem {
                cart_id: row.get("cart_id"),
                variant_id: row.get("variant_id"),
                quantity: match row.try_get::<i32, &str>("quantity") {
                    Ok(qty) => qty,
                    Err(_) => row.get::<String, &str>("quantity").parse().unwrap_or(0),
                },
                customer_id: row.get("customer_id"),
                kiosk_session_id: row.get("kiosk_session_id"),
                product_id: row.get("product_id"),
                product_name: row.get("product_name"),
                product_description: row.get("product_description"),
                base_price: row.get("base_price"),
                sale_price: row.get("sale_price"),
                brand_id: row.get("brand_id"),
                variant_name: row.get("variant_name"),
                sell_price: row.get("sell_price"),
                buy_price: row.get("buy_price"),
                stock: row.get("stock"),
                is_visible: row.get("is_visible"),
            });
        }

        println!("[DB] Fetched {} kiosk cart items", items.len());
        Ok(items)
    }

    /// Add item to cart
    pub async fn add_to_cart(
        &self,
        customer_id: i32,
        variant_id: i32,
        quantity: i32,
    ) -> Result<bool, sqlx::Error> {
        println!(
            "[DB] Adding variant {} to cart for customer {}",
            variant_id, customer_id
        );

        // Check if item already exists
        let existing = sqlx::query(
            "SELECT cart_id, quantity FROM cart WHERE customer_id = $1 AND variant_id = $2",
        )
        .bind(customer_id)
        .bind(variant_id)
        .fetch_optional(self.pool)
        .await?;

        if let Some(existing_row) = existing {
            // Update quantity
            let cart_id: i32 = existing_row.get("cart_id");

            // Try to get quantity as i32 first, then as String
            let current_qty = match existing_row.try_get::<i32, &str>("quantity") {
                Ok(qty) => qty,
                Err(_) => {
                    // Fallback to String and parse
                    let qty_str: String = existing_row.get("quantity");
                    qty_str.parse::<i32>().unwrap_or(0)
                }
            };

            let new_qty = current_qty + quantity;
            println!(
                "[DB] Item exists. Current qty: {}, new qty: {}",
                current_qty, new_qty
            );

            sqlx::query("UPDATE cart SET quantity = $1 WHERE cart_id = $2")
                .bind(new_qty)
                .bind(cart_id)
                .execute(self.pool)
                .await?;

            println!("[DB] Updated cart item quantity to {}", new_qty);
        } else {
            // Insert new item
            println!(
                "[DB] Item not in cart. Inserting new entry for variant {}",
                variant_id
            );
            sqlx::query("INSERT INTO cart (customer_id, variant_id, quantity) VALUES ($1, $2, $3)")
                .bind(customer_id)
                .bind(variant_id)
                .bind(quantity)
                .execute(self.pool)
                .await?;

            println!("[DB] Inserted new cart item");
        }

        Ok(true)
    }

    /// Add item to kiosk cart
    pub async fn add_to_kiosk_cart(
        &self,
        kiosk_session_id: &str,
        variant_id: i32,
        quantity: i32,
    ) -> Result<bool, sqlx::Error> {
        println!(
            "[DB] Adding variant {} to kiosk cart for session {}",
            variant_id, kiosk_session_id
        );

        // Check if item already exists
        let existing = sqlx::query("SELECT kiosk_id, quantity FROM kiosk_cart WHERE kiosk_session_id = $1 AND variant_id = $2")
            .bind(kiosk_session_id)
            .bind(variant_id)
            .fetch_optional(self.pool)
            .await?;

        if let Some(existing_row) = existing {
            // Update quantity
            let kiosk_id: i32 = existing_row.get("kiosk_id");
            let current_qty: i32 = existing_row.get("quantity");
            let new_qty = current_qty + quantity;

            sqlx::query("UPDATE kiosk_cart SET quantity = $1 WHERE kiosk_id = $2")
                .bind(new_qty)
                .bind(kiosk_id)
                .execute(self.pool)
                .await?;

            println!("[DB] Updated kiosk cart item quantity to {}", new_qty);
        } else {
            // Insert new item
            sqlx::query("INSERT INTO kiosk_cart (kiosk_session_id, variant_id, quantity) VALUES ($1, $2, $3)")
                .bind(kiosk_session_id)
                .bind(variant_id)
                .bind(quantity)
                .execute(self.pool)
                .await?;

            println!("[DB] Inserted new kiosk cart item");
        }

        Ok(true)
    }

    /// Update cart item quantity
    pub async fn update_cart_item_quantity(
        &self,
        cart_id: i32,
        new_quantity: i32,
    ) -> Result<bool, sqlx::Error> {
        println!(
            "[DB] Updating cart item {} to quantity {}",
            cart_id, new_quantity
        );

        let result = sqlx::query("UPDATE cart SET quantity = $1 WHERE cart_id = $2")
            .bind(new_quantity)
            .bind(cart_id)
            .execute(self.pool)
            .await?;

        Ok(result.rows_affected() > 0)
    }

    /// Update kiosk cart item quantity
    pub async fn update_kiosk_cart_item_quantity(
        &self,
        kiosk_id: i32,
        new_quantity: i32,
    ) -> Result<bool, sqlx::Error> {
        println!(
            "[DB] Updating kiosk cart item {} to quantity {}",
            kiosk_id, new_quantity
        );

        let result = sqlx::query("UPDATE kiosk_cart SET quantity = $1 WHERE kiosk_id = $2")
            .bind(new_quantity)
            .bind(kiosk_id)
            .execute(self.pool)
            .await?;

        Ok(result.rows_affected() > 0)
    }

    /// Remove cart item
    pub async fn remove_cart_item(&self, cart_id: i32) -> Result<bool, sqlx::Error> {
        println!("[DB] Removing cart item {}", cart_id);

        let result = sqlx::query("DELETE FROM cart WHERE cart_id = $1")
            .bind(cart_id)
            .execute(self.pool)
            .await?;

        Ok(result.rows_affected() > 0)
    }

    /// Remove kiosk cart item
    pub async fn remove_kiosk_cart_item(&self, kiosk_id: i32) -> Result<bool, sqlx::Error> {
        println!("[DB] Removing kiosk cart item {}", kiosk_id);

        let result = sqlx::query("DELETE FROM kiosk_cart WHERE kiosk_id = $1")
            .bind(kiosk_id)
            .execute(self.pool)
            .await?;

        Ok(result.rows_affected() > 0)
    }

    /// Clear entire cart for customer
    pub async fn clear_cart(&self, customer_id: i32) -> Result<bool, sqlx::Error> {
        println!("[DB] Clearing cart for customer {}", customer_id);

        sqlx::query("DELETE FROM cart WHERE customer_id = $1")
            .bind(customer_id)
            .execute(self.pool)
            .await?;

        Ok(true)
    }

    /// Clear kiosk cart for session
    pub async fn clear_kiosk_cart(&self, kiosk_session_id: &str) -> Result<bool, sqlx::Error> {
        println!("[DB] Clearing kiosk cart for session {}", kiosk_session_id);

        sqlx::query("DELETE FROM kiosk_cart WHERE kiosk_session_id = $1")
            .bind(kiosk_session_id)
            .execute(self.pool)
            .await?;

        Ok(true)
    }

    /// Validate variant stock availability
    pub async fn validate_variant_stock(
        &self,
        variant_id: i32,
        requested_quantity: i32,
    ) -> Result<bool, sqlx::Error> {
        println!(
            "[DB] Validating stock for variant {} (requested: {})",
            variant_id, requested_quantity
        );

        let result = sqlx::query(
            r#"
            SELECT 
                COALESCE(stock, 0) as stock,
                COALESCE(is_visible, true) as is_visible
            FROM product_variants 
            WHERE variant_id = $1
            "#,
        )
        .bind(variant_id)
        .fetch_optional(self.pool)
        .await?;

        match result {
            Some(row) => {
                let stock: i32 = row.get("stock");
                let is_visible: bool = row.get("is_visible");

                let is_valid = is_visible && stock >= requested_quantity;

                println!(
                    "[DB] Stock validation result for variant {}: {} (stock: {}, visible: {})",
                    variant_id, is_valid, stock, is_visible
                );
                Ok(is_valid)
            }
            None => {
                println!(
                    "[DB] Variant {} not found in product_variants table",
                    variant_id
                );
                Ok(false)
            }
        }
    }

    /// Validate entire cart stock
    pub async fn validate_cart_stock(
        &self,
        customer_id: i32,
    ) -> Result<Vec<CartStockValidation>, sqlx::Error> {
        println!("[DB] Validating cart stock for customer {}", customer_id);

        let rows = sqlx::query(
            r#"
            SELECT 
                c.cart_id,
                c.variant_id,
                p.name as product_name,
                pv.variant_name,
                c.quantity::int as current_quantity,
                COALESCE(pv.stock, 0) as available_stock,
                COALESCE(pv.is_visible, true) as is_visible
            FROM cart c
            INNER JOIN product_variants pv ON c.variant_id = pv.variant_id
            INNER JOIN products p ON pv.product_id = p.product_id
            WHERE c.customer_id = $1
            "#,
        )
        .bind(customer_id)
        .fetch_all(self.pool)
        .await?;

        let mut result = Vec::new();

        for row in rows {
            let cart_id: i32 = row.get("cart_id");
            let variant_id: i32 = row.get("variant_id");
            let product_name: String = row.get("product_name");
            let variant_name: String = row.get("variant_name");
            let current_qty: i32 = row.get("current_quantity");
            let available: i32 = row.get("available_stock");
            let visible: bool = row.get("is_visible");

            if !visible || available < current_qty {
                result.push(CartStockValidation {
                    cart_id,
                    variant_id,
                    product_name,
                    variant_name,
                    current_quantity: current_qty,
                    available_stock: available,
                    suggested_quantity: if available > 0 { available } else { 0 },
                    needs_adjustment: true,
                    adjustment_reason: if !visible {
                        "Product no longer available".to_string()
                    } else {
                        format!("Only {} available", available)
                    },
                    should_remove: available == 0 || !visible,
                });
            }
        }

        println!("[DB] Found {} items needing adjustment", result.len());
        Ok(result)
    }

    /// Check if variant can be added to cart (stock check)
    pub async fn can_add_to_cart(
        &self,
        variant_id: i32,
        quantity: i32,
    ) -> Result<bool, sqlx::Error> {
        self.validate_variant_stock(variant_id, quantity).await
    }
}

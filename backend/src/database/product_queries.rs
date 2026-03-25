use crate::models::{Product, ProductVariation};
use sqlx::PgPool;
use tracing::{error, info};

/// Product database queries
pub struct ProductQueries<'a> {
    pool: &'a PgPool,
}

impl<'a> ProductQueries<'a> {
    pub fn new(pool: &'a PgPool) -> Self {
        Self { pool }
    }

    /// Get count of popular products
    pub async fn get_popular_products_count(&self) -> Result<i64, sqlx::Error> {
        let count: (i64,) = sqlx::query_as(
            "SELECT COUNT(*) FROM products WHERE ispopular = true AND \"isVisible\" = true",
        )
        .fetch_one(self.pool)
        .await
        .map_err(|e| {
            error!("Failed to fetch popular products count: {:?}", e);
            e
        })?;

        info!("Fetched popular products count: {}", count.0);

        Ok(count.0)
    }

    /// Fetch popular products with pagination
    pub async fn fetch_popular_products(
        &self,
        limit: i64,
        offset: i64,
    ) -> Result<Vec<Product>, sqlx::Error> {
        let products = sqlx::query_as::<_, Product>(
            r#"
            SELECT 
                products.product_id,
                name,
                description,
                price_range,
                COALESCE(base_price, '1000')::text as base_price,
                COALESCE(sale_price, '1000')::text as sale_price,
                category_id,
                COALESCE(products.ispopular, false) as ispopular,
                COALESCE(stock_quantity, 0) as stock_quantity,
                products.created_at,
                "brandID" as brand_id,
                alert_stock,
                COALESCE("isVisible", false) as is_visible,
                tag::text as tag,
                CASE 
                    WHEN i.filename IS NOT NULL THEN 
                        format('https://jjxqwtltkepeajwtcish.supabase.co/storage/v1/object/public/%s/%s', i."folderType", i.filename)
                    ELSE NULL 
                END as image_url
            FROM products 
            LEFT JOIN image_entity ie ON products.product_id = ie.entity_id AND ie.entity_category = 'products' AND ie."isFeatured" = true
            LEFT JOIN images i ON ie.image_id = i.image_id
            WHERE COALESCE(products.ispopular, false) = true AND COALESCE("isVisible", false) = true
            ORDER BY products.created_at DESC
            LIMIT $1 OFFSET $2
            "#,
        )
        .bind(limit)
        .bind(offset)
        .fetch_all(self.pool)
        .await
        .map_err(|e| {
            error!("Failed to fetch popular products: {:?}", e);
            e
        })?;

        info!(
            "Fetched {} popular products (limit: {}, offset: {})",
            products.len(),
            limit,
            offset
        );

        Ok(products)
    }

    /// Fetch all products for POS system (all visible products)
    pub async fn fetch_all_products_for_pos(&self) -> Result<Vec<Product>, sqlx::Error> {
        let products = sqlx::query_as::<_, Product>(
            r#"
            SELECT 
                products.product_id,
                name,
                description,
                price_range,
                COALESCE(base_price, '1000')::text as base_price,
                COALESCE(sale_price, '1000')::text as sale_price,
                category_id,
                COALESCE(products.ispopular, false) as ispopular,
                COALESCE(stock_quantity, 0) as stock_quantity,
                products.created_at,
                "brandID" as brand_id,
                alert_stock,
                COALESCE("isVisible", false) as is_visible,
                tag::text as tag,
                CASE 
                    WHEN i.filename IS NOT NULL THEN 
                        format('https://jjxqwtltkepeajwtcish.supabase.co/storage/v1/object/public/%s/%s', i."folderType", i.filename)
                    ELSE NULL 
                END as image_url
            FROM products 
            LEFT JOIN image_entity ie ON products.product_id = ie.entity_id AND ie.entity_category = 'products' AND ie."isFeatured" = true
            LEFT JOIN images i ON ie.image_id = i.image_id
            WHERE COALESCE("isVisible", false) = true
            ORDER BY name ASC
            "#,
        )
        .fetch_all(self.pool)
        .await
        .map_err(|e| {
            error!("Failed to fetch all products for POS: {:?}", e);
            e
        })?;

        info!("Fetched {} products for POS", products.len());

        Ok(products)
    }

    /// Fetch products by category with pagination
    pub async fn fetch_products_by_category(
        &self,
        category_id: i32,
        page: i64,
        page_size: i64,
    ) -> Result<Vec<Product>, sqlx::Error> {
        let offset = page * page_size;

        let products = sqlx::query_as::<_, Product>(
            r#"
            SELECT 
                products.product_id,
                name,
                description,
                price_range,
                COALESCE(base_price, '1000')::text as base_price,
                COALESCE(sale_price, '1000')::text as sale_price,
                category_id,
                COALESCE(products.ispopular, false) as ispopular,
                COALESCE(stock_quantity, 0) as stock_quantity,
                products.created_at,
                "brandID" as brand_id,
                alert_stock,
                COALESCE("isVisible", false) as is_visible,
                tag::text as tag,
                CASE 
                    WHEN i.filename IS NOT NULL THEN 
                        format('https://jjxqwtltkepeajwtcish.supabase.co/storage/v1/object/public/%s/%s', i."folderType", i.filename)
                    ELSE NULL 
                END as image_url
            FROM products 
            LEFT JOIN image_entity ie ON products.product_id = ie.entity_id AND ie.entity_category = 'products' AND ie."isFeatured" = true
            LEFT JOIN images i ON ie.image_id = i.image_id
            WHERE category_id = $1 AND COALESCE("isVisible", false) = true
            ORDER BY name ASC
            LIMIT $2 OFFSET $3
            "#,
        )
        .bind(category_id)
        .bind(page_size)
        .bind(offset)
        .fetch_all(self.pool)
        .await
        .map_err(|e| {
            error!("Failed to fetch products for category {}: {:?}", category_id, e);
            e
        })?;

        info!(
            "Fetched {} products for category {} (page: {}, size: {})",
            products.len(),
            category_id,
            page,
            page_size
        );

        Ok(products)
    }

    /// Fetch products by brand
    pub async fn fetch_products_by_brand(
        &self,
        brand_id: i32,
    ) -> Result<Vec<Product>, sqlx::Error> {
        let products = sqlx::query_as::<_, Product>(
            r#"
            SELECT 
                products.product_id,
                name,
                description,
                price_range,
                COALESCE(base_price, '1000')::text as base_price,
                COALESCE(sale_price, '1000')::text as sale_price,
                category_id,
                COALESCE(products.ispopular, false) as ispopular,
                COALESCE(stock_quantity, 0) as stock_quantity,
                products.created_at,
                "brandID" as brand_id,
                alert_stock,
                COALESCE("isVisible", false) as is_visible,
                tag::text as tag,
                CASE 
                    WHEN i.filename IS NOT NULL THEN 
                        format('https://jjxqwtltkepeajwtcish.supabase.co/storage/v1/object/public/%s/%s', i."folderType", i.filename)
                    ELSE NULL 
                END as image_url
            FROM products 
            LEFT JOIN image_entity ie ON products.product_id = ie.entity_id AND ie.entity_category = 'products' AND ie."isFeatured" = true
            LEFT JOIN images i ON ie.image_id = i.image_id
            WHERE "brandID" = $1 AND COALESCE("isVisible", false) = true
            ORDER BY name ASC
            "#,
        )
        .bind(brand_id)
        .fetch_all(self.pool)
        .await?;

        Ok(products)
    }

    /// Search products by name or description
    pub async fn search_products(
        &self,
        query: &str,
        page: i64,
        page_size: i64,
    ) -> Result<Vec<Product>, sqlx::Error> {
        let offset = page * page_size;
        let search_pattern = format!("%{}%", query);

        let products = sqlx::query_as::<_, Product>(
            r#"
        SELECT 
            products.product_id,
            name,
            description,
            price_range,
            COALESCE(base_price, '1000')::text as base_price,
            COALESCE(sale_price, '1000')::text as sale_price,
            category_id,
            COALESCE(products.ispopular, false) as ispopular,
            COALESCE(stock_quantity, 0) as stock_quantity,
            products.created_at,
            "brandID" as brand_id,
            alert_stock,
            COALESCE("isVisible", false) as is_visible,
            tag::text as tag,
            CASE 
                WHEN i.filename IS NOT NULL THEN 
                    format('https://jjxqwtltkepeajwtcish.supabase.co/storage/v1/object/public/%s/%s', i."folderType", i.filename)
                ELSE NULL 
            END as image_url
        FROM products 
        LEFT JOIN image_entity ie ON products.product_id = ie.entity_id AND ie.entity_category = 'products' AND ie."isFeatured" = true
        LEFT JOIN images i ON ie.image_id = i.image_id
        WHERE COALESCE("isVisible", false) = true
          AND (LOWER(name) LIKE LOWER($1) OR LOWER(COALESCE(description, '')) LIKE LOWER($1))
        ORDER BY 
            CASE WHEN LOWER(name) LIKE LOWER($1) THEN 1 ELSE 2 END,
            name ASC
        LIMIT $2 OFFSET $3
        "#,
        )
        .bind(&search_pattern)
        .bind(page_size)
        .bind(offset)
        .fetch_all(self.pool)
        .await?;

        println!("products: {:?}", products.len());

        Ok(products)
    }

    /// Fetch product by ID
    pub async fn fetch_product_by_id(&self, product_id: i32) -> Result<Product, sqlx::Error> {
        let product = sqlx::query_as::<_, Product>(
            r#"
            SELECT 
                products.product_id,
                name,
                description,
                price_range,
                COALESCE(base_price, '1000')::text as base_price,
                COALESCE(sale_price, '1000')::text as sale_price,
                category_id,
                COALESCE(products.ispopular, false) as ispopular,
                COALESCE(stock_quantity, 0) as stock_quantity,
                products.created_at,
                "brandID" as brand_id,
                alert_stock,
                COALESCE("isVisible", false) as is_visible,
                tag::text as tag,
                CASE 
                    WHEN i.filename IS NOT NULL THEN 
                        format('https://jjxqwtltkepeajwtcish.supabase.co/storage/v1/object/public/%s/%s', i."folderType", i.filename)
                    ELSE NULL 
                END as image_url
            FROM products 
            LEFT JOIN image_entity ie ON products.product_id = ie.entity_id AND ie.entity_category = 'products' AND ie."isFeatured" = true
            LEFT JOIN images i ON ie.image_id = i.image_id
            WHERE products.product_id = $1
            "#,
        )
        .bind(product_id)
        .fetch_one(self.pool)
        .await?;

        Ok(product)
    }

    /// Fetch product variations by product ID
    pub async fn fetch_product_variations(
        &self,
        product_id: i32,
    ) -> Result<Vec<ProductVariation>, sqlx::Error> {
        let variations = sqlx::query_as::<_, ProductVariation>(
            r#"
            SELECT 
                variant_id,
                sell_price,
                buy_price,
                product_id,
                variant_name,
                COALESCE(stock, 0) as stock,
                COALESCE(is_visible, true) as is_visible
            FROM product_variants 
            WHERE product_id = $1 AND COALESCE(is_visible, true) = true
            ORDER BY variant_name ASC
            "#,
        )
        .bind(product_id)
        .fetch_all(self.pool)
        .await?;

        Ok(variations)
    }

    /// Fetch product variation by variant ID
    pub async fn fetch_variation_by_id(
        &self,
        variant_id: i32,
    ) -> Result<ProductVariation, sqlx::Error> {
        let variation = sqlx::query_as::<_, ProductVariation>(
            r#"
            SELECT 
                variant_id,
                sell_price,
                buy_price,
                product_id,
                variant_name,
                COALESCE(stock, 0) as stock,
                COALESCE(is_visible, true) as is_visible
            FROM product_variants 
            WHERE variant_id = $1
            "#,
        )
        .bind(variant_id)
        .fetch_one(self.pool)
        .await?;

        Ok(variation)
    }

    /// Fetch all variations for a specific variant ID (related variations)
    pub async fn fetch_variations_by_variant_id(
        &self,
        variant_id: i32,
    ) -> Result<Vec<ProductVariation>, sqlx::Error> {
        // First get the product_id from the variant
        let product_id: (i32,) =
            sqlx::query_as("SELECT product_id FROM product_variants WHERE variant_id = $1")
                .bind(variant_id)
                .fetch_one(self.pool)
                .await?;

        // Then fetch all variations for that product
        self.fetch_product_variations(product_id.0).await
    }

    /// Check stock for a specific variant
    pub async fn check_variant_stock(&self, variant_id: i32) -> Result<i32, sqlx::Error> {
        let stock: (i32,) =
            sqlx::query_as("SELECT stock FROM product_variants WHERE variant_id = $1")
                .bind(variant_id)
                .fetch_one(self.pool)
                .await?;

        Ok(stock.0)
    }

    /// Get total products count (for statistics)
    pub async fn get_total_products_count(&self) -> Result<i64, sqlx::Error> {
        let count: (i64,) = sqlx::query_as(
            "SELECT COUNT(*) FROM products WHERE COALESCE(\"isVisible\", false) = true",
        )
        .fetch_one(self.pool)
        .await?;

        Ok(count.0)
    }

    /// Get products count by category
    pub async fn get_category_products_count(&self, category_id: i32) -> Result<i64, sqlx::Error> {
        let count: (i64,) = sqlx::query_as(
            "SELECT COUNT(*) FROM products WHERE category_id = $1 AND COALESCE(\"isVisible\", false) = true",
        )
        .bind(category_id)
        .fetch_one(self.pool)
        .await?;

        Ok(count.0)
    }
}

use crate::models::Category;
use sqlx::PgPool;

/// Category database queries
pub struct CategoryQueries<'a> {
    pool: &'a PgPool,
}

impl<'a> CategoryQueries<'a> {
    pub fn new(pool: &'a PgPool) -> Self {
        Self { pool }
    }

    /// Get all categories
    pub async fn get_all_categories(&self) -> Result<Vec<Category>, sqlx::Error> {
        println!("[DB] Fetching all categories...");

        let categories = sqlx::query_as::<_, Category>(
            r#"
            SELECT 
                category_id,
                category_name,
                "isFeatured" as is_featured,
                created_at,
                product_count
            FROM categories 
            ORDER BY category_name ASC
            "#,
        )
        .fetch_all(self.pool)
        .await?;

        println!("[DB] Fetched {} categories", categories.len());
        Ok(categories)
    }

    /// Get featured categories only
    pub async fn get_featured_categories(&self) -> Result<Vec<Category>, sqlx::Error> {
        println!("[DB] Fetching featured categories...");

        let categories = sqlx::query_as::<_, Category>(
            r#"
            SELECT 
                category_id,
                category_name,
                "isFeatured" as is_featured,
                created_at,
                product_count
            FROM categories 
            WHERE "isFeatured" = true
            ORDER BY category_name ASC
            "#,
        )
        .fetch_all(self.pool)
        .await?;

        println!("[DB] Fetched {} featured categories", categories.len());
        Ok(categories)
    }

    /// Get category by ID
    pub async fn get_category_by_id(&self, category_id: i32) -> Result<Category, sqlx::Error> {
        println!("[DB] Fetching category with ID: {}", category_id);

        let category = sqlx::query_as::<_, Category>(
            r#"
            SELECT 
                category_id,
                category_name,
                "isFeatured" as is_featured,
                created_at,
                product_count
            FROM categories 
            WHERE category_id = $1
            "#,
        )
        .bind(category_id)
        .fetch_one(self.pool)
        .await?;

        Ok(category)
    }

    /// Get total categories count
    pub async fn get_categories_count(&self) -> Result<i64, sqlx::Error> {
        let count: (i64,) = sqlx::query_as("SELECT COUNT(*) FROM categories")
            .fetch_one(self.pool)
            .await?;

        Ok(count.0)
    }

    /// Get featured categories count
    pub async fn get_featured_categories_count(&self) -> Result<i64, sqlx::Error> {
        let count: (i64,) =
            sqlx::query_as(r#"SELECT COUNT(*) FROM categories WHERE "isFeatured" = true"#)
                .fetch_one(self.pool)
                .await?;

        Ok(count.0)
    }
}

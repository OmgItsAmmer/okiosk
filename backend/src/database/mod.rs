mod auth_queries;
mod cart_queries;
mod category_queries;
mod order_queries;
mod product_queries;

use crate::models::Order;
use sqlx::{postgres::PgPoolOptions, PgPool};
use std::time::Duration;

pub use auth_queries::AuthQueries;
pub use cart_queries::CartQueries;
pub use category_queries::CategoryQueries;
pub use order_queries::OrderQueries;
pub use product_queries::ProductQueries;

pub struct Database {
    pool: PgPool,
}

impl Database {
    // pub async fn new(database_url: &str) -> Result<Self, sqlx::Error> {
    //     eprintln!("🔍 Connecting to database...");
    //     let pool = PgPoolOptions::new()
    //         .max_connections(5)
    //         .min_connections(1)
    //         .acquire_timeout(Duration::from_secs(30))
    //         .idle_timeout(Duration::from_secs(600))
    //         .max_lifetime(Duration::from_secs(1800))
    //         .connect(database_url)
    //         .await?;
    //     eprintln!("✅ Database connected successfully");
    //     Ok(Self { pool })
    // }

    pub async fn new(database_url: &str) -> Result<Self, sqlx::Error> {
        eprintln!("🔍 Connecting to database...");

        // Inject a short TCP-level connect_timeout so a silently-dropped SYN
        // (e.g. Render → Supabase pooler firewall DROP) fails in 10 s instead
        // of waiting the full acquire_timeout (30 s).
        let url_with_timeout = if database_url.contains('?') {
            if database_url.contains("connect_timeout") {
                database_url.to_string()
            } else {
                format!("{}&connect_timeout=10", database_url)
            }
        } else {
            format!("{}?connect_timeout=10", database_url)
        };

        let pool = PgPoolOptions::new()
            .max_connections(5)
            .min_connections(1)                           // keep one warm connection alive
            .acquire_timeout(Duration::from_secs(15))
            .idle_timeout(Duration::from_secs(1200))
            .max_lifetime(Duration::from_secs(900))
            .connect(&url_with_timeout)                   // eager connect — fails at startup if DB unreachable
            .await?;

        eprintln!("✅ Database connected successfully");
        Ok(Self { pool })
    }

    /// Get product queries helper
    pub fn products(&self) -> ProductQueries<'_> {
        ProductQueries::new(&self.pool)
    }

    /// Get category queries helper
    pub fn categories(&self) -> CategoryQueries<'_> {
        CategoryQueries::new(&self.pool)
    }

    /// Get cart queries helper
    pub fn cart(&self) -> CartQueries<'_> {
        CartQueries::new(&self.pool)
    }

    /// Get order queries helper
    pub fn orders(&self) -> OrderQueries<'_> {
        OrderQueries::new(&self.pool)
    }

    /// Get the underlying connection pool
    pub fn pool(&self) -> &PgPool {
        &self.pool
    }

    // ===== Order methods =====
    pub async fn get_all_orders(&self) -> Result<Vec<Order>, sqlx::Error> {
        let orders =
            sqlx::query_as::<_, Order>("SELECT * FROM orders ORDER BY order_date DESC LIMIT 10")
                .fetch_all(&self.pool)
                .await?;

        Ok(orders)
    }

    pub async fn test_connection(&self) -> Result<String, sqlx::Error> {
        let row: (i64,) = sqlx::query_as("SELECT COUNT(*) FROM orders")
            .fetch_one(&self.pool)
            .await?;

        Ok(format!(
            "Connected to Supabase! Found {} orders in the database.",
            row.0
        ))
    }
}

mod auth_queries;
mod cart_queries;
mod category_queries;
mod order_queries;
mod product_queries;

use crate::models::Order;
use sqlx::postgres::{PgConnectOptions, PgPoolOptions};
use sqlx::PgPool;
use std::str::FromStr;
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

        let (url, disable_statement_cache) = prepare_database_url(database_url);

        let mut connect_options = PgConnectOptions::from_str(&url)?;
        if disable_statement_cache {
            connect_options = connect_options.statement_cache_capacity(0);
        }

        let pool = PgPoolOptions::new()
            .max_connections(5)
            .min_connections(1) // keep one warm connection alive
            .acquire_timeout(Duration::from_secs(15))
            .idle_timeout(Duration::from_secs(1200))
            .max_lifetime(Duration::from_secs(900))
            .connect_with(connect_options) // eager connect — fails at startup if DB unreachable
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

/// Normalize the database URL for SQLx + Supabase compatibility.
///
/// SQLx uses named prepared statements (`sqlx_s_1`, …) which break on Supabase's
/// transaction-mode pooler (port 6543). Session-mode pooler (port 5432) works.
fn prepare_database_url(database_url: &str) -> (String, bool) {
    let mut url = database_url.to_string();
    let mut disable_statement_cache = false;

    // Supabase transaction pooler → session pooler (same host, port 5432).
    if url.contains("pooler.supabase.com:6543") {
        eprintln!(
            "⚠️  Supabase transaction pooler (6543) is incompatible with SQLx; using session pooler (5432)"
        );
        url = url.replace("pooler.supabase.com:6543", "pooler.supabase.com:5432");
    } else if url.contains(":6543") {
        // Other PgBouncer transaction poolers: disable statement cache as a fallback.
        disable_statement_cache = true;
    }

    // Short TCP connect_timeout so a silently-dropped SYN fails fast instead of
    // waiting the full acquire_timeout.
    if url.contains('?') {
        if !url.contains("connect_timeout") {
            url = format!("{}&connect_timeout=10", url);
        }
    } else {
        url = format!("{}?connect_timeout=10", url);
    }

    (url, disable_statement_cache)
}

#[cfg(test)]
mod tests {
    use super::prepare_database_url;

    #[test]
    fn rewrites_supabase_transaction_pooler_to_session_mode() {
        let input = "postgresql://postgres.x:pw@aws-0-ap.pooler.supabase.com:6543/postgres";
        let (url, disable_cache) = prepare_database_url(input);
        assert!(url.contains("pooler.supabase.com:5432"));
        assert!(!url.contains(":6543"));
        assert!(!disable_cache);
    }

    #[test]
    fn adds_connect_timeout() {
        let (url, _) = prepare_database_url("postgresql://localhost/okiosk");
        assert!(url.contains("connect_timeout=10"));
    }
}

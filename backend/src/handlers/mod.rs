mod ai_handlers;
mod auth_handlers;
mod cart_handlers;
mod category_handlers;
mod checkout_handlers;
mod product_handlers;
mod transcribe_handlers;

use axum::{extract::State, http::StatusCode, Json};
use serde_json::{json, Value};
use std::sync::Arc;

use crate::database::Database;

// Re-export handlers
pub use ai_handlers::*;
pub use auth_handlers::*;
pub use cart_handlers::*;
pub use category_handlers::*;
pub use checkout_handlers::*;
pub use product_handlers::*;
pub use transcribe_handlers::*;

/// AI State - shared between handlers
pub struct AiState {
    pub db: Arc<Database>,
    pub ai_service: Arc<crate::services::AiService>,
    pub queue_service: Arc<crate::services::QueueService>,
    pub transcribe_service: Arc<crate::services::TranscribeService>,
}

impl AiState {
    pub fn new(
        db: Arc<Database>,
        llm_api_url: String,
        whisper_path: String,
        model_path: String,
    ) -> Self {
        Self {
            db,
            ai_service: Arc::new(crate::services::AiService::new(llm_api_url)),
            queue_service: Arc::new(crate::services::QueueService::new()),
            transcribe_service: Arc::new(crate::services::TranscribeService::new(
                whisper_path,
                model_path,
            )),
        }
    }
}

// Test handler for button press - just logs and responds
pub async fn test_button_press() -> Result<Json<Value>, StatusCode> {
    // Log to console
    tracing::info!("🚀 Button pressed! Test function called successfully!");
    println!("🚀 Button pressed! Test function called successfully!");

    Ok(Json(json!({
        "message": "Button press received successfully!",
        "status": "ok",
        "timestamp": chrono::Utc::now().to_rfc3339()
    })))
}

// Test handler to fetch orders from Supabase
pub async fn fetch_orders(State(db): State<Arc<Database>>) -> Result<Json<Value>, StatusCode> {
    tracing::info!("📦 Fetching orders from Supabase...");
    println!("📦 Fetching orders from Supabase...");

    match db.get_all_orders().await {
        Ok(orders) => {
            tracing::info!("✅ Successfully fetched {} orders", orders.len());
            println!("✅ Successfully fetched {} orders", orders.len());

            Ok(Json(json!({
                "message": "Orders fetched successfully",
                "count": orders.len(),
                "orders": orders
            })))
        }
        Err(e) => {
            tracing::error!("❌ Failed to fetch orders: {}", e);
            println!("❌ Failed to fetch orders: {}", e);

            Err(StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}

// Test database connection
pub async fn test_database(State(db): State<Arc<Database>>) -> Result<Json<Value>, StatusCode> {
    tracing::info!("🔗 Testing database connection...");
    println!("🔗 Testing database connection...");

    match db.test_connection().await {
        Ok(message) => {
            tracing::info!("✅ {}", message);
            println!("✅ {}", message);

            Ok(Json(json!({
                "message": message,
                "status": "connected"
            })))
        }
        Err(e) => {
            tracing::error!("❌ Database connection failed: {}", e);
            println!("❌ Database connection failed: {}", e);

            Err(StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}

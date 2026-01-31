use axum::{routing::post, Router};
use std::sync::Arc;

use crate::handlers::AiState;

/// Creates AI-related routes
/// 
/// This module handles AI endpoints including:
/// - Natural language command processing using Gemini AI
/// - Variant selection confirmation for sequential queue
/// 
/// # Arguments
/// * `ai_state` - Shared AI service state
/// 
/// # Returns
/// Router configured with AI endpoints
pub fn create_ai_routes(ai_state: Arc<AiState>) -> Router {
    Router::new()
        .route("/api/ai/command", post(crate::handlers::process_ai_command))
        .route(
            "/api/ai/variant-confirm",
            post(crate::handlers::confirm_variant_selection),
        )
        .with_state(ai_state)
}

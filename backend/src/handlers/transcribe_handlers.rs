use axum::{
    extract::State,
    http::StatusCode,
    Json,
};
use axum_extra::extract::Multipart;
use serde_json::{json, Value};
use std::sync::Arc;

use crate::models::TranscribeResponse;
use crate::handlers::AiState;

/// Maximum audio file size (5 seconds of WebM ≈ 800KB, adding buffer)
const MAX_AUDIO_SIZE: usize = 2 * 1024 * 1024; // 2MB

/// Transcribe audio endpoint
/// POST /api/transcribe
/// 
/// Accepts multipart form with 'audio' field containing the audio file.
/// Supports audio/webm, audio/wav, audio/mp3 formats.
/// 
/// Returns: { "text": "transcribed text" }
pub async fn transcribe_audio(
    State(ai_state): State<Arc<AiState>>,
    mut multipart: Multipart,
) -> Result<Json<TranscribeResponse>, (StatusCode, Json<Value>)> {
    tracing::info!("Received transcription request");

    // Extract audio file from multipart form
    let mut audio_data: Option<Vec<u8>> = None;
    let mut audio_format: Option<String> = None;

    while let Some(field) = multipart
        .next_field()
        .await
        .map_err(|e| {
            tracing::error!("Failed to read multipart field: {}", e);
            (
                StatusCode::BAD_REQUEST,
                Json(json!({ "error": format!("Failed to read form data: {}", e) })),
            )
        })?
    {
        let name = field.name().unwrap_or("").to_string();
        
        if name == "audio" {
            // Get content type to determine format
            let content_type = field.content_type().unwrap_or("audio/webm").to_string();
            audio_format = Some(extract_format(&content_type));

            // Read audio bytes
            let data = field.bytes().await.map_err(|e| {
                tracing::error!("Failed to read audio bytes: {}", e);
                (
                    StatusCode::BAD_REQUEST,
                    Json(json!({ "error": format!("Failed to read audio data: {}", e) })),
                )
            })?;

            // Validate size
            if data.len() > MAX_AUDIO_SIZE {
                return Err((
                    StatusCode::PAYLOAD_TOO_LARGE,
                    Json(json!({ 
                        "error": format!(
                            "Audio file too large: {} bytes (max: {} bytes)", 
                            data.len(), 
                            MAX_AUDIO_SIZE
                        ) 
                    })),
                ));
            }

            audio_data = Some(data.to_vec());
            tracing::info!(
                "Received audio: {} bytes, content-type: {}",
                data.len(),
                content_type
            );
        }
    }

    // Validate we got audio data
    let audio_data = audio_data.ok_or_else(|| {
        tracing::error!("No audio field in request");
        (
            StatusCode::BAD_REQUEST,
            Json(json!({ "error": "Missing 'audio' field in form data" })),
        )
    })?;

    let format = audio_format.unwrap_or_else(|| "webm".to_string());

    let start = std::time::Instant::now();
    let text: String = ai_state
        .transcribe_service
        .transcribe(&audio_data, &format)
        .await
        .map_err(|e: String| {
            tracing::error!("Transcription failed: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({ "error": format!("Transcription failed: {}", e) })),
            )
        })?;

    tracing::info!(
        "Total transcription time: {:?}, result: '{}'",
        start.elapsed(),
        text
    );

    Ok(Json(TranscribeResponse { text }))
}

/// Extract audio format from content type
fn extract_format(content_type: &str) -> String {
    match content_type {
        "audio/webm" => "webm".to_string(),
        "audio/wav" | "audio/wave" | "audio/x-wav" => "wav".to_string(),
        "audio/mpeg" | "audio/mp3" => "mp3".to_string(),
        "audio/ogg" => "ogg".to_string(),
        _ => {
            // Try to extract from mime type
            if let Some(subtype) = content_type.split('/').nth(1) {
                subtype.split(';').next().unwrap_or("webm").to_string()
            } else {
                "webm".to_string()
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_extract_format() {
        assert_eq!(extract_format("audio/webm"), "webm");
        assert_eq!(extract_format("audio/wav"), "wav");
        assert_eq!(extract_format("audio/mpeg"), "mp3");
        assert_eq!(extract_format("audio/ogg"), "ogg");
        assert_eq!(extract_format("audio/webm; codecs=opus"), "webm");
    }
}

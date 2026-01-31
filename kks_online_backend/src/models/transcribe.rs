use serde::Serialize;

/// Response from the transcription endpoint
#[derive(Debug, Serialize)]
pub struct TranscribeResponse {
    pub text: String,
}

/// Error response from the transcription endpoint
#[derive(Debug, Serialize)]
pub struct TranscribeError {
    pub error: String,
}

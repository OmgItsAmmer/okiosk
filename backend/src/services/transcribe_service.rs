use std::path::Path;
use std::process::Command;
use tempfile::NamedTempFile;
use tokio::fs;
use tokio::io::AsyncWriteExt;

/// Service for transcribing audio using whisper.cpp
pub struct TranscribeService {
    whisper_path: String,
    model_path: String,
}

impl TranscribeService {
    /// Create a new TranscribeService with paths to whisper.cpp binary and model
    pub fn new(whisper_path: String, model_path: String) -> Self {
        match std::fs::canonicalize(&whisper_path) {
            Ok(abs_path) => {
                let whisper_path = abs_path.to_string_lossy().to_string();
                // Canonicalize on Windows often adds \\?\ prefix (UNC path)
                // We should strip it if it causes issues, but Command::new usually likes it.
                let whisper_path = whisper_path.trim_start_matches(r"\\?\").to_string();
                
                let model_path = match std::fs::canonicalize(&model_path) {
                    Ok(abs_model) => abs_model.to_string_lossy().to_string().trim_start_matches(r"\\?\").to_string(),
                    Err(_) => model_path,
                };
                
                tracing::info!("Transcription service initialized with absolute paths:");
                tracing::info!("  Binary: {}", whisper_path);
                tracing::info!("  Model:  {}", model_path);

                Self {
                    whisper_path,
                    model_path,
                }
            }
            Err(_) => {
                Self {
                    whisper_path,
                    model_path,
                }
            }
        }
    }

    /// Create service from environment variables with fallback defaults
    pub fn from_env() -> Result<Self, String> {
        let whisper_path = std::env::var("WHISPER_CPP_PATH")
            .unwrap_or_else(|_| "whisper".to_string());
        let model_path = std::env::var("WHISPER_MODEL_PATH")
            .unwrap_or_else(|_| "models/ggml-base.en.bin".to_string());

        // Validate paths exist
        if !Path::new(&whisper_path).exists() && !which_exists(&whisper_path) {
            tracing::warn!(
                "Whisper binary not found at '{}'. Transcription may fail.",
                whisper_path
            );
        }

        if !Path::new(&model_path).exists() {
            tracing::warn!(
                "Whisper model not found at '{}'. Transcription may fail.",
                model_path
            );
        }

        Ok(Self {
            whisper_path,
            model_path,
        })
    }

    /// Transcribe audio data to text
    /// 
    /// # Arguments
    /// * `audio_data` - Raw audio bytes
    /// * `format` - Audio format (e.g., "webm", "wav")
    /// 
    /// # Returns
    /// Transcribed text or error message
    pub async fn transcribe(&self, audio_data: &[u8], format: &str) -> Result<String, String> {
        // Create temp file for input audio
        let input_suffix = format!(".{}", format);
        let input_file = NamedTempFile::with_suffix(&input_suffix)
            .map_err(|e| format!("Failed to create temp input file: {}", e))?;
        let input_path = input_file.path().to_path_buf();

        // Create temp file for converted WAV
        let wav_file = NamedTempFile::with_suffix(".wav")
            .map_err(|e| format!("Failed to create temp WAV file: {}", e))?;
        let wav_path = wav_file.path().to_path_buf();

        // Write audio data to input file
        let mut file = fs::File::create(&input_path)
            .await
            .map_err(|e| format!("Failed to write audio data: {}", e))?;
        file.write_all(audio_data)
            .await
            .map_err(|e| format!("Failed to write audio data: {}", e))?;
        file.flush()
            .await
            .map_err(|e| format!("Failed to flush audio data: {}", e))?;
        drop(file);

        tracing::info!(
            "Received audio: {} bytes, format: {}",
            audio_data.len(),
            format
        );

        // Convert to 16kHz mono WAV using ffmpeg
        self.convert_to_wav(&input_path, &wav_path).await?;

        // Run whisper.cpp
        let text = self.run_whisper(&wav_path).await?;

        // Clean up is automatic via NamedTempFile drop
        // But we need to keep the files alive until we're done
        drop(input_file);
        drop(wav_file);

        Ok(text.trim().to_string())
    }

    /// Convert audio file to 16kHz mono WAV using ffmpeg
    async fn convert_to_wav(&self, input_path: &Path, output_path: &Path) -> Result<(), String> {
        let start = std::time::Instant::now();

        let output = Command::new("ffmpeg")
            .args([
                "-y",                           // Overwrite output
                "-i", input_path.to_str().unwrap(),
                "-ar", "16000",                 // 16kHz sample rate
                "-ac", "1",                     // Mono
                "-c:a", "pcm_s16le",           // 16-bit PCM
                "-f", "wav",                    // WAV format
                output_path.to_str().unwrap(),
            ])
            .output()
            .map_err(|e| format!("Failed to run ffmpeg: {}. Is ffmpeg installed?", e))?;

        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            return Err(format!("FFmpeg conversion failed: {}", stderr));
        }

        tracing::info!("Audio converted to WAV in {:?}", start.elapsed());
        Ok(())
    }

    /// Run whisper.cpp on the WAV file and extract transcription
    async fn run_whisper(&self, wav_path: &Path) -> Result<String, String> {
        let start = std::time::Instant::now();

        tracing::debug!(
            "Running whisper: '{}' with model '{}' on file '{}'",
            self.whisper_path,
            self.model_path,
            wav_path.display()
        );

        let output = Command::new(&self.whisper_path)
            .args([
                "-m", &self.model_path,
                "-f", wav_path.to_str().unwrap(),
                "--no-timestamps",              // No timestamps in output
                "--print-colors", "false",      // No color codes
                "-l", "en",                     // English language
                "--output-txt",                 // Output plain text
            ])
            .output()
            .map_err(|e| format!("Failed to run whisper.cpp: {}. Is whisper.cpp installed?", e))?;

        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            return Err(format!("Whisper transcription failed: {}", stderr));
        }

        let transcription = String::from_utf8_lossy(&output.stdout).to_string();
        
        tracing::info!(
            "Transcription completed in {:?}: '{}'",
            start.elapsed(),
            transcription.trim()
        );

        Ok(transcription)
    }
}

/// Check if a command exists in PATH
fn which_exists(cmd: &str) -> bool {
    Command::new("where")
        .arg(cmd)
        .output()
        .map(|o| o.status.success())
        .unwrap_or(false)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_service_creation() {
        let service = TranscribeService::new(
            "whisper".to_string(),
            "models/ggml-base.en.bin".to_string(),
        );
        assert!(!service.whisper_path.is_empty());
        assert!(!service.model_path.is_empty());
    }
}

use std::env;
use std::path::PathBuf;

#[derive(Debug, Clone)]
pub struct Config {
    pub database_url: String,
    pub port: u16,
    pub host: String,
    pub llm_api_url: String,
    pub google_client_id: String,
    pub google_client_secret: String,
    pub google_redirect_uri: String,
    pub jwt_secret: String,
    pub jwt_expiration: i64,
    pub whisper_cpp_path: String,
    pub whisper_model_path: String,
}

impl Config {
    pub fn from_env() -> Result<Self, Box<dyn std::error::Error>> {
        // Get current directory
        let current_dir = env::current_dir().unwrap_or_else(|_| PathBuf::from("."));

        // Try multiple locations for .env file
        let mut env_paths: Vec<PathBuf> = vec![
            current_dir.join(".env"),                            // Current directory
            current_dir.join("kks_online_backend").join(".env"), // If running from project root
            PathBuf::from(".env"),                               // Simple relative path
            PathBuf::from("kks_online_backend/.env"),            // Relative path from root
        ];

        // Add parent directory if it exists
        if let Some(parent) = current_dir.parent() {
            env_paths.push(parent.join(".env"));
            env_paths.push(parent.join("kks_online_backend").join(".env"));
        }

        // Debug: Print current directory
        eprintln!("🔍 Current working directory: {}", current_dir.display());
        eprintln!("🔍 Looking for .env file in the following locations:");

        let mut loaded = false;
        for path in &env_paths {
            eprintln!("   - {} (exists: {})", path.display(), path.exists());
            if path.exists() {
                match dotenv::from_filename(path) {
                    Ok(_) => {
                        loaded = true;
                        eprintln!("✅ Successfully loaded .env from: {}", path.display());
                        break;
                    }
                    Err(e) => {
                        eprintln!("   ⚠️  Failed to load from {}: {}", path.display(), e);
                    }
                }
            }
        }

        // Also try the default dotenv behavior
        if !loaded {
            eprintln!("🔍 Trying default dotenv::dotenv()...");
            match dotenv::dotenv() {
                Ok(path) => {
                    eprintln!(
                        "✅ Successfully loaded .env from default location: {}",
                        path.display()
                    );
                }
                Err(e) => {
                    eprintln!("   ⚠️  Default dotenv failed: {}", e);
                }
            }
        }

        // Debug: Check if DATABASE_URL is set
        eprintln!(
            "🔍 DATABASE_URL in environment: {}",
            env::var("DATABASE_URL").is_ok()
        );

        Ok(Config {
            database_url: env::var("DATABASE_URL").map_err(|_| {
                eprintln!("❌ DATABASE_URL not found in environment");
                eprintln!("   Current dir: {}", current_dir.display());
                eprintln!("   Tried loading .env from multiple locations");
                "DATABASE_URL must be set"
            })?,
            port: env::var("PORT")
                .unwrap_or_else(|_| "3000".to_string())
                .parse()?,
            host: env::var("HOST").unwrap_or_else(|_| "0.0.0.0".to_string()),
            llm_api_url: env::var("LLM_API_URL")
                .unwrap_or_else(|_| "http://localhost:8080/v1/chat/completions".to_string()),
            google_client_id: env::var("GOOGLE_CLIENT_ID")
                .map_err(|_| "GOOGLE_CLIENT_ID must be set")?,
            google_client_secret: env::var("GOOGLE_CLIENT_SECRET")
                .map_err(|_| "GOOGLE_CLIENT_SECRET must be set")?,
            google_redirect_uri: env::var("GOOGLE_REDIRECT_URI")
                .map_err(|_| "GOOGLE_REDIRECT_URI must be set")?,
            jwt_secret: env::var("JWT_SECRET").map_err(|_| "JWT_SECRET must be set")?,
            jwt_expiration: env::var("JWT_EXPIRATION")
                .unwrap_or_else(|_| "86400".to_string())
                .parse()
                .unwrap_or(86400),
            whisper_cpp_path: env::var("WHISPER_CPP_PATH")
                .unwrap_or_else(|_| "whisper".to_string()),
            whisper_model_path: env::var("WHISPER_MODEL_PATH")
                .unwrap_or_else(|_| "models/ggml-base.en.bin".to_string()),
        })
    }
}

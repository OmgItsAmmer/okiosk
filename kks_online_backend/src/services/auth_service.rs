use crate::models::{AuthResponse, Claims, GoogleUserInfo, User};
use chrono::Utc;
use jsonwebtoken::{decode, encode, DecodingKey, EncodingKey, Header, Validation};
use oauth2::{
    basic::BasicClient, AuthUrl, AuthorizationCode, ClientId, ClientSecret, CsrfToken,
    RedirectUrl, TokenResponse, TokenUrl,
};
use reqwest::Client;
use serde_json::Value;
use std::sync::Arc;

pub struct AuthService {
    oauth_client: BasicClient,
    jwt_secret: String,
    jwt_expiration: i64,
    http_client: Client,
}

impl AuthService {
    pub fn new(
        google_client_id: String,
        google_client_secret: String,
        redirect_uri: String,
        jwt_secret: String,
        jwt_expiration: i64,
    ) -> Result<Self, Box<dyn std::error::Error>> {
        let client_id = ClientId::new(google_client_id);
        let client_secret = ClientSecret::new(google_client_secret);
        let auth_url = AuthUrl::new("https://accounts.google.com/o/oauth2/v2/auth".to_string())?;
        let token_url =
            TokenUrl::new("https://oauth2.googleapis.com/token".to_string())?;

        let redirect = RedirectUrl::new(redirect_uri)?;

        let oauth_client = BasicClient::new(client_id, Some(client_secret), auth_url, Some(token_url))
            .set_redirect_uri(redirect);

        Ok(Self {
            oauth_client,
            jwt_secret,
            jwt_expiration,
            http_client: Client::new(),
        })
    }

    /// Generate Google OAuth authorization URL
    pub fn get_authorization_url(&self, session_id: String) -> (String, CsrfToken) {
        let (auth_url, csrf_token) = self
            .oauth_client
            .authorize_url(|| CsrfToken::new(session_id))
            .add_scope(oauth2::Scope::new(
                "https://www.googleapis.com/auth/userinfo.email".to_string(),
            ))
            .add_scope(oauth2::Scope::new(
                "https://www.googleapis.com/auth/userinfo.profile".to_string(),
            ))
            .url();

        (auth_url.to_string(), csrf_token)
    }

    /// Exchange authorization code for access token
    pub async fn exchange_code(
        &self,
        code: String,
    ) -> Result<String, Box<dyn std::error::Error>> {
        let token_result = self
            .oauth_client
            .exchange_code(AuthorizationCode::new(code))
            .request_async(oauth2::reqwest::async_http_client)
            .await?;

        Ok(token_result.access_token().secret().to_string())
    }

    /// Get user info from Google using access token
    pub async fn get_google_user_info(
        &self,
        access_token: &str,
    ) -> Result<GoogleUserInfo, Box<dyn std::error::Error>> {
        let response = self
            .http_client
            .get("https://www.googleapis.com/oauth2/v2/userinfo")
            .bearer_auth(access_token)
            .send()
            .await?;

        if !response.status().is_success() {
            return Err(format!("Failed to get user info: {}", response.status()).into());
        }

        let user_data: Value = response.json().await?;

        let user_info = GoogleUserInfo {
            id: user_data["id"]
                .as_str()
                .ok_or("Missing id field")?
                .to_string(),
            email: user_data["email"]
                .as_str()
                .ok_or("Missing email field")?
                .to_string(),
            name: user_data["name"]
                .as_str()
                .ok_or("Missing name field")?
                .to_string(),
            picture: user_data["picture"].as_str().map(|s| s.to_string()),
        };

        Ok(user_info)
    }

    /// Generate JWT token for authenticated user
    pub fn generate_jwt(&self, user: &User) -> Result<String, Box<dyn std::error::Error>> {
        let now = Utc::now().timestamp() as usize;
        let expiration = now + self.jwt_expiration as usize;

        let claims = Claims {
            sub: user.id.to_string(),
            email: user.email.clone(),
            name: user.name.clone(),
            exp: expiration,
            iat: now,
        };

        let token = encode(
            &Header::default(),
            &claims,
            &EncodingKey::from_secret(self.jwt_secret.as_bytes()),
        )?;

        Ok(token)
    }

    /// Verify and decode JWT token
    pub fn verify_jwt(&self, token: &str) -> Result<Claims, Box<dyn std::error::Error>> {
        let token_data = decode::<Claims>(
            token,
            &DecodingKey::from_secret(self.jwt_secret.as_bytes()),
            &Validation::default(),
        )?;

        Ok(token_data.claims)
    }

    /// Create auth response with token and user data
    pub fn create_auth_response(&self, user: User) -> Result<AuthResponse, Box<dyn std::error::Error>> {
        let token = self.generate_jwt(&user)?;
        Ok(AuthResponse { token, user })
    }

    /// Generate JWT token for guest user (24 hour expiration)
    pub fn generate_guest_jwt(&self, guest_id: &str, guest_name: &str) -> Result<String, Box<dyn std::error::Error>> {
        use crate::models::GuestClaims;
        
        let now = Utc::now().timestamp() as usize;
        let expiration = now + (24 * 60 * 60); // 24 hours for guest sessions

        let claims = GuestClaims {
            sub: guest_id.to_string(),
            name: guest_name.to_string(),
            user_type: "guest".to_string(),
            exp: expiration,
            iat: now,
        };

        let token = encode(
            &Header::default(),
            &claims,
            &EncodingKey::from_secret(self.jwt_secret.as_bytes()),
        )?;

        Ok(token)
    }
}

pub type SharedAuthService = Arc<AuthService>;

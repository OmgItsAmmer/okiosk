use crate::database::AuthQueries;
use crate::models::{AuthResponse, GoogleAuthQuery, GoogleCallbackQuery};
use crate::services::AuthService;
use axum::{
    extract::{Query, State},
    http::StatusCode,
    response::{IntoResponse, Redirect, Response},
    Json,
};
use serde_json::json;
use socketioxide::SocketIo;
use sqlx::{PgPool, Row};
use std::sync::Arc;
use tracing::{error, info};

pub struct AuthState {
    pub pool: Arc<PgPool>,
    pub auth_service: Arc<AuthService>,
    pub io: SocketIo,
}

/// Initiate Google OAuth flow
/// GET /api/auth/google?session_id=<session_id>
pub async fn initiate_google_auth(
    State(state): State<Arc<AuthState>>,
    Query(params): Query<GoogleAuthQuery>,
) -> Result<Redirect, Response> {
    info!("Initiating Google auth for session: {}", params.session_id);

    // Create session in database
    match AuthQueries::create_session(&state.pool, &params.session_id).await {
        Ok(_) => {
            info!("Session created: {}", params.session_id);
        }
        Err(e) => {
            error!("Failed to create session: {}", e);
            return Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({ "error": "Failed to create session" })),
            )
                .into_response());
        }
    }

    // Generate Google OAuth URL
    let (auth_url, _csrf_token) = state
        .auth_service
        .get_authorization_url(params.session_id.clone());

    info!("Redirecting to Google OAuth: {}", auth_url);
    Ok(Redirect::to(&auth_url))
}

/// Handle Google OAuth callback
/// GET /api/auth/google/callback?code=<code>&state=<session_id>
pub async fn google_callback(
    State(state): State<Arc<AuthState>>,
    Query(params): Query<GoogleCallbackQuery>,
) -> Result<Response, Response> {
    info!("Google callback received for session: {}", params.state);

    let session_id = params.state;

    // Verify session exists and is pending
    let _session = match AuthQueries::get_session(&state.pool, &session_id).await {
        Ok(Some(s)) if s.status == "pending" => s,
        Ok(Some(_)) => {
            error!("Session {} is not pending", session_id);
            return Err((
                StatusCode::BAD_REQUEST,
                Json(json!({ "error": "Session is not pending" })),
            )
                .into_response());
        }
        Ok(None) => {
            error!("Session {} not found", session_id);
            return Err((
                StatusCode::NOT_FOUND,
                Json(json!({ "error": "Session not found" })),
            )
                .into_response());
        }
        Err(e) => {
            error!("Database error: {}", e);
            return Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({ "error": "Database error" })),
            )
                .into_response());
        }
    };

    // Exchange code for access token
    let access_token = match state.auth_service.exchange_code(params.code).await {
        Ok(token) => token,
        Err(e) => {
            error!("Failed to exchange code: {}", e);
            
            // Emit error to WebSocket
            state.io.of("/").unwrap().to(session_id.clone()).emit("auth-error", json!({
                "message": "Failed to exchange authorization code"
            })).ok();
            
            return Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({ "error": "Failed to exchange code" })),
            )
                .into_response());
        }
    };

    // Get user info from Google
    let google_user = match state.auth_service.get_google_user_info(&access_token).await {
        Ok(user) => user,
        Err(e) => {
            error!("Failed to get user info: {}", e);
            
            // Emit error to WebSocket
            state.io.of("/").unwrap().to(session_id.clone()).emit("auth-error", json!({
                "message": "Failed to get user information"
            })).ok();
            
            return Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({ "error": "Failed to get user info" })),
            )
                .into_response());
        }
    };

    // Upsert user in database
    let user = match AuthQueries::upsert_user(
        &state.pool,
        &google_user.id,
        &google_user.email,
        &google_user.name,
        google_user.picture.as_deref(),
    )
    .await
    {
        Ok(u) => u,
        Err(e) => {
            error!("Failed to upsert user: {}", e);
            
            // Emit error to WebSocket
            state.io.of("/").unwrap().to(session_id.clone()).emit("auth-error", json!({
                "message": "Failed to create user account"
            })).ok();
            
            return Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({ "error": "Failed to create user" })),
            )
                .into_response());
        }
    };

    // Complete session
    match AuthQueries::complete_session(&state.pool, &session_id, user.id).await {
        Ok(_) => info!("Session {} completed", session_id),
        Err(e) => {
            error!("Failed to complete session: {}", e);
        }
    }

    // Generate JWT token
    let auth_response = match state.auth_service.create_auth_response(user) {
        Ok(resp) => resp,
        Err(e) => {
            error!("Failed to create auth response: {}", e);
            return Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({ "error": "Failed to generate token" })),
            )
                .into_response());
        }
    };

    // Emit success event to WebSocket (to the kiosk waiting for auth)
    info!("Emitting auth-success to session: {}", session_id);
    state.io.of("/").unwrap().to(session_id.clone()).emit("auth-success", json!({
        "token": auth_response.token,
        "user": auth_response.user
    })).ok();

    // Return success page to mobile browser
    let html = format!(
        r#"
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Authentication Successful</title>
            <style>
                body {{
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    min-height: 100vh;
                    margin: 0;
                    background: linear-gradient(135deg, #F5E6D3 0%, #E8D5C4 100%);
                }}
                .container {{
                    text-align: center;
                    padding: 2rem;
                    background: white;
                    border-radius: 16px;
                    box-shadow: 0 10px 40px rgba(0, 0, 0, 0.1);
                    max-width: 400px;
                }}
                h1 {{
                    color: #E63946;
                    margin: 0 0 1rem 0;
                }}
                p {{
                    color: #6B5D54;
                    line-height: 1.6;
                }}
                .checkmark {{
                    font-size: 4rem;
                    color: #E63946;
                    margin-bottom: 1rem;
                }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="checkmark">✓</div>
                <h1>Success!</h1>
                <p>You've been authenticated successfully.</p>
                <p>You can now close this window and return to the kiosk.</p>
            </div>
        </body>
        </html>
        "#
    );

    Ok((StatusCode::OK, axum::response::Html(html)).into_response())
}

/// Verify JWT token
/// POST /api/auth/verify
/// Headers: Authorization: Bearer <token>
pub async fn verify_token(
    State(state): State<Arc<AuthState>>,
    headers: axum::http::HeaderMap,
) -> Result<Json<AuthResponse>, Response> {
    let auth_header = headers
        .get("Authorization")
        .and_then(|h| h.to_str().ok())
        .ok_or_else(|| {
            (
                StatusCode::UNAUTHORIZED,
                Json(json!({ "error": "Missing authorization header" })),
            )
                .into_response()
        })?;

    let token = auth_header
        .strip_prefix("Bearer ")
        .ok_or_else(|| {
            (
                StatusCode::UNAUTHORIZED,
                Json(json!({ "error": "Invalid authorization header" })),
            )
                .into_response()
        })?;

    let claims = state.auth_service.verify_jwt(token).map_err(|e| {
        error!("Failed to verify token: {}", e);
        (
            StatusCode::UNAUTHORIZED,
            Json(json!({ "error": "Invalid token" })),
        )
            .into_response()
    })?;

    let user_id = uuid::Uuid::parse_str(&claims.sub).map_err(|e| {
        error!("Invalid user ID in token: {}", e);
        (
            StatusCode::UNAUTHORIZED,
            Json(json!({ "error": "Invalid token" })),
        )
            .into_response()
    })?;

    let user = AuthQueries::get_user_by_id(&state.pool, user_id)
        .await
        .map_err(|e| {
            error!("Database error: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({ "error": "Database error" })),
            )
                .into_response()
        })?
        .ok_or_else(|| {
            (
                StatusCode::NOT_FOUND,
                Json(json!({ "error": "User not found" })),
            )
                .into_response()
        })?;

    let auth_response = state.auth_service.create_auth_response(user).map_err(|e| {
        error!("Failed to create auth response: {}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({ "error": "Failed to generate response" })),
        )
            .into_response()
    })?;

    Ok(Json(auth_response))
}

/// Create a guest session
/// POST /api/auth/guest-session
pub async fn create_guest_session(
    State(state): State<Arc<AuthState>>,
) -> Result<Json<crate::models::GuestSessionResponse>, Response> {
    info!("Creating guest session for customer 1");

    // Use fixed guest ID 1 as requested
    let guest_id = "1".to_string();
    
    // Attempt to fetch customer 1's name from database
    let customer_name = match sqlx::query("SELECT first_name, last_name FROM customers WHERE customer_id = 1")
        .fetch_optional(&*state.pool)
        .await {
            Ok(Some(row)) => {
                let first: Option<String> = row.get("first_name");
                let last: Option<String> = row.get("last_name");
                match (first, last) {
                    (Some(f), Some(l)) => format!("{} {}", f, l),
                    (Some(f), None) => f,
                    (None, Some(l)) => l,
                    _ => "Guest User".to_string(),
                }
            },
            _ => "Guest User".to_string(),
        };

    info!("Guest session using customer 1: {}", customer_name);

    // Generate guest JWT
    let jwt = state.auth_service.generate_guest_jwt(&guest_id, &customer_name).map_err(|e| {
        error!("Failed to generate guest JWT: {}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({ "error": "Failed to create guest session" })),
        )
            .into_response()
    })?;

    info!("Guest session created for: {}", customer_name);

    Ok(Json(crate::models::GuestSessionResponse {
        status: "OK".to_string(),
        jwt,
        user_id: guest_id,
        name: customer_name,
        user_type: "guest".to_string(),
    }))
}

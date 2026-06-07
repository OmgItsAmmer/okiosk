use axum::body::Body;
use axum::http::{Request, StatusCode};
use http_body_util::BodyExt;
use kks_online_backend::app::build_router;
use kks_online_backend::database::Database;
use kks_online_backend::handlers::{AiState, AuthState};
use kks_online_backend::services::AuthService;
use socketioxide::SocketIo;
use std::sync::Arc;
use tower::ServiceExt;

mod common;

async fn test_app() -> axum::Router {
    common::set_test_env();

    let database = Arc::new(
        Database::new(&std::env::var("DATABASE_URL").unwrap_or_else(|_| {
            "postgresql://postgres:postgres@localhost:5432/okiosk_test".to_string()
        }))
        .await
        .expect("test database connection"),
    );

    let ai_state = Arc::new(AiState::new(
        database.clone(),
        "whisper".to_string(),
        "models/ggml-base.en.bin".to_string(),
    ));

    let (socket_layer, io) = SocketIo::new_layer();
    let auth_service = Arc::new(
        AuthService::new(
            std::env::var("GOOGLE_CLIENT_ID").unwrap(),
            std::env::var("GOOGLE_CLIENT_SECRET").unwrap(),
            std::env::var("GOOGLE_REDIRECT_URI").unwrap(),
            std::env::var("JWT_SECRET").unwrap(),
            86400,
        )
        .unwrap(),
    );

    let auth_state = Arc::new(AuthState {
        pool: Arc::new(database.pool().clone()),
        auth_service,
        io,
    });

    build_router(database, ai_state, auth_state, socket_layer)
}

#[tokio::test]
async fn root_endpoint_returns_welcome_message() {
    if std::env::var("RUN_DB_TESTS").is_err() {
        eprintln!("Skipping DB integration test (set RUN_DB_TESTS=1 to enable)");
        return;
    }

    let app = test_app().await;

    let response = app
        .oneshot(Request::builder().uri("/").body(Body::empty()).unwrap())
        .await
        .unwrap();

    assert_eq!(response.status(), StatusCode::OK);

    let body = response.into_body().collect().await.unwrap().to_bytes();
    let text = String::from_utf8(body.to_vec()).unwrap();
    assert!(text.contains("KKS Online Backend"));
}

#[tokio::test]
async fn auth_verify_rejects_missing_authorization_header() {
    if std::env::var("RUN_DB_TESTS").is_err() {
        eprintln!("Skipping DB integration test (set RUN_DB_TESTS=1 to enable)");
        return;
    }

    let app = test_app().await;

    let response = app
        .oneshot(
            Request::builder()
                .method("POST")
                .uri("/api/auth/verify")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();

    assert_eq!(response.status(), StatusCode::UNAUTHORIZED);
}

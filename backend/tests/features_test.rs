mod common;

use chrono::Utc;
use kks_online_backend::config::Config;
use kks_online_backend::models::{Action, Command, User};
use kks_online_backend::services::AuthService;
use uuid::Uuid;

#[test]
fn action_enum_serializes_with_tagged_format() {
    let action = Action::AddToCart {
        item: "Zinger Burger".to_string(),
        quantity: 2,
        variant_id: Some(42),
    };

    let json = serde_json::to_string(&action).unwrap();
    assert!(json.contains("\"action\":\"add_to_cart\""));
    assert!(json.contains("\"item\":\"Zinger Burger\""));
}

#[test]
fn action_enum_deserializes_from_llm_json_shape() {
    let json = r#"{"action":"search_product","query":"chicken"}"#;
    let action: Action = serde_json::from_str(json).unwrap();
    match action {
        Action::SearchProduct { query } => assert_eq!(query, "chicken"),
        _ => panic!("expected SearchProduct"),
    }
}

#[test]
fn command_round_trips_through_json() {
    let command = Command {
        actions: vec![
            Action::ViewCart,
            Action::Checkout {
                payment_method: "cod".to_string(),
                shipping_method: "pickup".to_string(),
            },
        ],
        response_message: Some("Done".to_string()),
    };

    let encoded = serde_json::to_string(&command).unwrap();
    let decoded: Command = serde_json::from_str(&encoded).unwrap();
    assert_eq!(decoded.actions.len(), 2);
    assert_eq!(decoded.response_message.as_deref(), Some("Done"));
}

#[test]
fn jwt_generate_and_verify_round_trip() {
    common::set_test_env();

    let auth = AuthService::new(
        "test-id.apps.googleusercontent.com".to_string(),
        "secret".to_string(),
        "http://localhost:3000/callback".to_string(),
        "test-jwt-secret-for-ci-only-min-32-chars".to_string(),
        3600,
    )
    .unwrap();

    let user = User {
        id: Uuid::new_v4(),
        google_id: "google-123".to_string(),
        email: "user@example.com".to_string(),
        name: "Test User".to_string(),
        picture: None,
        created_at: Utc::now(),
        updated_at: Utc::now(),
    };

    let token = auth.generate_jwt(&user).unwrap();
    let claims = auth.verify_jwt(&token).unwrap();
    assert_eq!(claims.email, "user@example.com");
    assert_eq!(claims.sub, user.id.to_string());
}

#[test]
fn guest_jwt_contains_guest_user_type() {
    common::set_test_env();

    let auth = AuthService::new(
        "test-id.apps.googleusercontent.com".to_string(),
        "secret".to_string(),
        "http://localhost:3000/callback".to_string(),
        "test-jwt-secret-for-ci-only-min-32-chars".to_string(),
        3600,
    )
    .unwrap();

    let token = auth.generate_guest_jwt("guest-abc", "Guest").unwrap();
    let claims = auth.verify_jwt(&token).unwrap();
    assert_eq!(claims.user_type.as_deref(), Some("guest"));
}

#[test]
fn config_loads_required_env_vars() {
    common::set_test_env();
    let config = Config::from_env().expect("config should load with test env");
    assert_eq!(config.port, 3000);
    assert_eq!(config.host, "0.0.0.0");
    assert!(config.database_url.contains("okiosk_test"));
}

#[test]
fn production_env_detects_fly_app_name() {
    common::set_test_env();
    std::env::set_var("FLY_APP_NAME", "okiosk-api");
    assert!(Config::is_production_env());
    std::env::remove_var("FLY_APP_NAME");
}

use axum::{
    routing::{delete, get, post, put},
    Router,
};
use socketioxide::SocketIo;
use std::sync::Arc;
use tower_http::cors::{Any, CorsLayer};
use tower_http::trace::TraceLayer;

use crate::config::Config;
use crate::database::Database;
use crate::handlers::{self, AiState, AuthState};
use crate::services::AuthService;

/// Build the full Axum router with all API routes, WebSocket layer, and middleware.
pub fn build_router(
    database: Arc<Database>,
    ai_state: Arc<AiState>,
    auth_state: Arc<AuthState>,
    socket_layer: socketioxide::layer::SocketIoLayer,
) -> Router {
    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods(Any)
        .allow_headers(Any);

    let app = Router::new()
        .route(
            "/",
            get(|| async { "🚀 KKS Online Backend - E-commerce & Kiosk API" }),
        )
        .route(
            "/api/products/popular/count",
            get(handlers::get_popular_products_count),
        )
        .route(
            "/api/products/popular",
            get(handlers::fetch_popular_products),
        )
        .route(
            "/api/products/pos/all",
            get(handlers::fetch_all_products_for_pos),
        )
        .route("/api/products/search", get(handlers::search_products))
        .route("/api/products/stats", get(handlers::get_product_stats))
        .route(
            "/api/products/category/:category_id",
            get(handlers::fetch_products_by_category),
        )
        .route(
            "/api/products/brand/:brand_id",
            get(handlers::fetch_products_by_brand),
        )
        .route(
            "/api/products/:product_id",
            get(handlers::fetch_product_by_id),
        )
        .route(
            "/api/products/:product_id/variations",
            get(handlers::fetch_product_variations),
        )
        .route(
            "/api/variations/:variant_id",
            get(handlers::fetch_variation_by_id),
        )
        .route(
            "/api/variations/:variant_id/related",
            get(handlers::fetch_variations_by_variant_id),
        )
        .route(
            "/api/variations/:variant_id/stock",
            get(handlers::check_variant_stock),
        )
        .route("/api/categories/all", get(handlers::fetch_categories))
        .route("/api/categories/stats", get(handlers::get_category_stats))
        .route(
            "/api/categories/:category_id",
            get(handlers::fetch_category_by_id),
        )
        .route("/api/checkout", post(handlers::checkout))
        .with_state(database.clone());

    let cart_router = Router::new()
        .route("/api/cart/:customer_id", get(handlers::fetch_cart))
        .route("/api/cart/:customer_id/add", post(handlers::add_to_cart))
        .route("/api/cart/:customer_id/clear", delete(handlers::clear_cart))
        .route(
            "/api/cart/:customer_id/validate",
            get(handlers::validate_cart_stock),
        )
        .route(
            "/api/cart/guest/item",
            put(handlers::update_guest_cart_item),
        )
        .route(
            "/api/cart/guest/item/:variant_id",
            delete(handlers::remove_guest_cart_item),
        )
        .route(
            "/api/cart/item/:cart_id",
            put(handlers::update_cart_quantity),
        )
        .route(
            "/api/cart/item/:cart_id",
            delete(handlers::remove_cart_item),
        )
        .route(
            "/api/cart/kiosk/:session_id",
            get(handlers::fetch_kiosk_cart),
        )
        .route("/api/cart/kiosk/add", post(handlers::add_to_kiosk_cart))
        .route(
            "/api/cart/kiosk/:session_id/clear",
            delete(handlers::clear_kiosk_cart),
        )
        .route(
            "/api/cart/kiosk/item/:kiosk_id",
            put(handlers::update_kiosk_cart_quantity),
        )
        .route(
            "/api/cart/kiosk/item/:kiosk_id",
            delete(handlers::remove_kiosk_cart_item),
        )
        .with_state(ai_state.clone());

    let auth_router = Router::new()
        .route("/api/auth/google", get(handlers::initiate_google_auth))
        .route("/api/auth/google/callback", get(handlers::google_callback))
        .route("/api/auth/verify", post(handlers::verify_token))
        .route("/api/auth/logout", post(handlers::logout))
        .route(
            "/api/auth/guest-session",
            post(handlers::create_guest_session),
        )
        .with_state(auth_state);

    let ai_router = Router::new()
        .route("/api/ai/command", post(handlers::process_ai_command))
        .route(
            "/api/ai/variant-confirm",
            post(handlers::confirm_variant_selection),
        )
        .with_state(ai_state.clone());

    let transcribe_router = Router::new()
        .route("/api/transcribe", post(handlers::transcribe_audio))
        .with_state(ai_state);

    app.merge(cart_router)
        .merge(ai_router)
        .merge(auth_router)
        .merge(transcribe_router)
        .layer(socket_layer)
        .layer(cors)
        .layer(TraceLayer::new_for_http())
}

fn init_socket_io() -> (socketioxide::layer::SocketIoLayer, socketioxide::SocketIo) {
    let (socket_layer, io) = SocketIo::new_layer();

    io.ns("/", |socket: socketioxide::extract::SocketRef| {
        tracing::info!("Socket connected: {}", socket.id);

        socket.on(
            "join-session",
            |socket: socketioxide::extract::SocketRef,
             socketioxide::extract::Data::<String>(session_id)| {
                tracing::info!("Socket {} joining session: {}", socket.id, session_id);
                socket.join(session_id.clone()).ok();
                socket.emit("joined", session_id).ok();
            },
        );

        socket.on_disconnect(|socket: socketioxide::extract::SocketRef| {
            tracing::info!("Socket disconnected: {}", socket.id);
        });
    });

    (socket_layer, io)
}

/// Start the HTTP server with configuration loaded from the environment.
pub async fn run() -> Result<(), Box<dyn std::error::Error>> {
    let config = Config::from_env()?;
    tracing::info!("Configuration loaded successfully");

    let database = Arc::new(Database::new(&config.database_url).await?);
    tracing::info!("Database connected successfully");

    let ai_state = Arc::new(AiState::new(
        database.clone(),
        config.whisper_cpp_path.clone(),
        config.whisper_model_path.clone(),
    ));
    tracing::info!("AI Service initialized successfully");

    let (socket_layer, io) = init_socket_io();
    tracing::info!("WebSocket layer initialized");

    let auth_service = Arc::new(AuthService::new(
        config.google_client_id.clone(),
        config.google_client_secret.clone(),
        config.google_redirect_uri.clone(),
        config.jwt_secret.clone(),
        config.jwt_expiration,
    )?);
    tracing::info!("Auth Service initialized successfully");

    let auth_state = Arc::new(AuthState {
        pool: Arc::new(database.pool().clone()),
        auth_service,
        io: io.clone(),
    });

    match database.test_connection().await {
        Ok(msg) => tracing::info!("DB health check passed: {}", msg),
        Err(e) => {
            tracing::error!("DB health check FAILED: {}", e);
            return Err(e.into());
        }
    }

    let app = build_router(database, ai_state, auth_state, socket_layer);

    let addr = format!("{}:{}", config.host, config.port);
    let listener = tokio::net::TcpListener::bind(&addr).await?;

    tracing::info!("Server starting on {}", addr);
    axum::serve(listener, app).await?;

    Ok(())
}

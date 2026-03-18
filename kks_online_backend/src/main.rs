mod config;
mod database;
mod handlers;
mod models;
mod services;

use axum::{
    routing::{delete, get, post, put},
    Router,
};
use std::sync::Arc;
use tower_http::cors::{Any, CorsLayer};
use tower_http::trace::TraceLayer;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

use config::Config;
use database::Database;
use handlers::{AiState, AuthState};
use services::AuthService;
use socketioxide::SocketIo;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Initialize logger
    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "kks_online_backend=debug,tower_http=debug".into()),
        )
        .with(tracing_subscriber::fmt::layer())
        .init();

    // Load configuration
    let config = Config::from_env()?;
    tracing::info!("✅ Configuration loaded successfully");
    println!("✅ Configuration loaded successfully");

    // Setup database connection
    let database = Arc::new(Database::new(&config.database_url).await?);
    tracing::info!("✅ Database connected successfully");
    println!("✅ Database connected successfully");

    // Setup AI service
    let ai_state = Arc::new(AiState::new(
        database.clone(),
        config.llm_api_url.clone(),
        config.whisper_cpp_path.clone(),
        config.whisper_model_path.clone(),
    ));
    tracing::info!("✅ AI Service initialized successfully");
    println!("✅ AI Service initialized successfully");

    // Setup WebSocket layer
    let (socket_layer, io) = SocketIo::new_layer();
    tracing::info!("✅ WebSocket layer initialized");
    println!("✅ WebSocket layer initialized");

    // Setup WebSocket event handlers
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

    // Setup Auth service
    let auth_service = Arc::new(AuthService::new(
        config.google_client_id.clone(),
        config.google_client_secret.clone(),
        config.google_redirect_uri.clone(),
        config.jwt_secret.clone(),
        config.jwt_expiration,
    )?);
    tracing::info!("✅ Auth Service initialized successfully");
    println!("✅ Auth Service initialized successfully");

    // Setup Auth state
    let auth_state = Arc::new(AuthState {
        pool: Arc::new(database.pool().clone()),
        auth_service,
        io: io.clone(),
    });

    // Setup CORS
    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods(Any)
        .allow_headers(Any);

    // Create router with all endpoints
    let app = Router::new()
        // Root endpoint
        .route(
            "/",
            get(|| async { "🚀 KKS Online Backend - E-commerce & Kiosk API" }),
        )
        // Product endpoints
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
        // Product variation endpoints
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
        // Category endpoints
        .route("/api/categories/all", get(handlers::fetch_categories))
        .route("/api/categories/stats", get(handlers::get_category_stats))
        .route(
            "/api/categories/:category_id",
            get(handlers::fetch_category_by_id),
        )
        // Checkout endpoint
        .route("/api/checkout", post(handlers::checkout))
        .with_state(database.clone());

    // Create Cart router with AiState
    let cart_router = Router::new()
        // Cart endpoints
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
        // Kiosk cart endpoints
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

    // Create Auth router with its own state
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

    // Create AI router separately with its own state
    let ai_router = Router::new()
        .route("/api/ai/command", post(handlers::process_ai_command))
        .route(
            "/api/ai/variant-confirm",
            post(handlers::confirm_variant_selection),
        )
        .with_state(ai_state.clone());

    // Create Transcribe router
    let transcribe_router = Router::new()
        .route("/api/transcribe", post(handlers::transcribe_audio))
        .with_state(ai_state);

    // Merge routers
    let app = app
        .merge(cart_router)
        .merge(ai_router)
        .merge(auth_router)
        .merge(transcribe_router)
        .layer(socket_layer)
        .layer(cors)
        .layer(TraceLayer::new_for_http());

    // Start server
    let addr = format!("{}:{}", config.host, config.port);
    let listener = tokio::net::TcpListener::bind(&addr).await?;

    tracing::info!("🚀 Server starting on {}", addr);
    println!("🚀 Server starting on {}", addr);
    println!("\n📝 Available Endpoints:");
    println!("\n🧪 Test Endpoints:");
    println!("   GET  /            - Welcome message");
    println!("   POST /test-button - Test button press");
    println!("   GET  /test-db     - Test database connection");
    println!("   GET  /orders      - Fetch orders from Supabase");

    println!("\n🛍️  Product Endpoints:");
    println!("   GET  /api/products/popular/count              - Get count of popular products");
    println!("   GET  /api/products/popular?limit=10&offset=0  - Fetch popular products");
    println!("   GET  /api/products/pos/all                    - Fetch all products for POS");
    println!("   GET  /api/products/search?query=...           - Search products");
    println!("   GET  /api/products/stats                      - Get product statistics");
    println!("   GET  /api/products/category/:id               - Fetch products by category");
    println!("   GET  /api/products/brand/:id                  - Fetch products by brand");
    println!(
        "   GET  /api/products/:id                        - Get product by ID with variations"
    );
    println!("   GET  /api/products/:id/variations             - Get product variations");

    println!("\n🔧 Product Variation Endpoints:");
    println!("   GET  /api/variations/:id                      - Get variation by ID");
    println!("   GET  /api/variations/:id/related              - Get related variations");
    println!("   GET  /api/variations/:id/stock                - Check variant stock");

    println!("\n📁 Category Endpoints:");
    println!("   GET  /api/categories/all                      - Get all categories");
    println!("   GET  /api/categories/all?featured_only=true   - Get featured categories");
    println!("   GET  /api/categories/stats                    - Get category statistics");
    println!("   GET  /api/categories/:id                      - Get category by ID");

    println!("\n🛒 Cart Endpoints:");
    println!("   GET    /api/cart/:customer_id                 - Get cart items");
    println!("   POST   /api/cart/:customer_id/add             - Add item to cart");
    println!("   PUT    /api/cart/item/:cart_id                - Update cart item quantity");
    println!("   DELETE /api/cart/item/:cart_id                - Remove cart item");
    println!("   DELETE /api/cart/:customer_id/clear           - Clear entire cart");
    println!("   GET    /api/cart/:customer_id/validate        - Validate cart stock");

    println!("\n🖥️ Kiosk Cart Endpoints:");
    println!("   GET    /api/cart/kiosk/:session_id            - Get kiosk cart items");
    println!("   POST   /api/cart/kiosk/add                    - Add item to kiosk cart");
    println!("   PUT    /api/cart/kiosk/item/:kiosk_id         - Update kiosk cart item");
    println!("   DELETE /api/cart/kiosk/item/:kiosk_id         - Remove kiosk cart item");
    println!("   DELETE /api/cart/kiosk/:session_id/clear      - Clear kiosk cart");

    println!("\n💳 Checkout Endpoint:");
    println!("   POST   /api/checkout                          - Process checkout with race condition handling");

    println!("\n🤖 AI Endpoint:");
    println!("   POST   /api/ai/command                        - Process natural language commands using Local LLM");
    println!("   POST   /api/ai/variant-confirm                - Confirm variant selection for sequential queue");

    println!("\n🎤 Speech-to-Text Endpoint:");
    println!("   POST   /api/transcribe                        - Transcribe audio to text using Whisper.cpp");

    axum::serve(listener, app).await?;

    let db_check = database.clone();
tokio::spawn(async move {
    match db_check.test_connection().await {
        Ok(msg) => tracing::info!("✅ DB check passed: {}", msg),
        Err(e) => tracing::error!("❌ DB check failed: {}", e),
    }
});

    Ok(())
}

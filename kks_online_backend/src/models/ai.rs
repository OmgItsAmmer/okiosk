use serde::{Deserialize, Serialize};

/// AI Command Request from Frontend
#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct AiCommandRequest {
    pub prompt: String,
    pub session_id: Option<String>, // For kiosk mode
    pub customer_id: Option<i32>,   // For authenticated users
}

/// AI Command Response to Frontend
#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct AiCommandResponse {
    pub success: bool,
    pub message: String,
    pub actions_executed: Vec<String>,
    pub error: Option<String>,
}

/// Parsed Command from Gemini AI
#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct Command {
    pub actions: Vec<Action>,
    pub response_message: Option<String>,
}

/// Individual Action
#[derive(Debug, Deserialize, Serialize, Clone)]
#[serde(tag = "action", rename_all = "snake_case")]
pub enum Action {
    AddToCart {
        item: String,
        quantity: i32,
        #[serde(default)]
        variant_id: Option<i32>,
    },
    RemoveFromCart {
        item: String,
        #[serde(default)]
        variant_id: Option<i32>,
    },
    ClearCart,
    GenerateBill,
    ShowMenu {
        #[serde(default)]
        category: Option<String>,
    },
    SearchProduct {
        query: String,
    },
    UpdateQuantity {
        item: String,
        quantity: i32,
        #[serde(default)]
        variant_id: Option<i32>,
    },
    ViewCart,
    Checkout {
        payment_method: String,
        shipping_method: String,
    },
}

/// Gemini API Request Structure
#[derive(Debug, Serialize)]
pub struct GeminiRequest {
    pub contents: Vec<GeminiContent>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub generation_config: Option<GenerationConfig>,
}

#[derive(Debug, Serialize)]
pub struct GeminiContent {
    pub parts: Vec<GeminiPart>,
}

#[derive(Debug, Serialize)]
pub struct GeminiPart {
    pub text: String,
}

#[derive(Debug, Serialize)]
pub struct GenerationConfig {
    pub temperature: f32,
    pub top_p: f32,
    pub top_k: i32,
    pub max_output_tokens: i32,
}

/// Gemini API Response Structure
#[derive(Debug, Deserialize)]
pub struct GeminiResponse {
    pub candidates: Vec<GeminiCandidate>,
}

#[derive(Debug, Deserialize)]
pub struct GeminiCandidate {
    pub content: GeminiContentResponse,
}

#[derive(Debug, Deserialize)]
pub struct GeminiContentResponse {
    pub parts: Vec<GeminiPartResponse>,
}

#[derive(Debug, Deserialize)]
pub struct GeminiPartResponse {
    pub text: String,
}

/// Command Execution Result
#[derive(Debug)]
pub struct CommandResult {
    pub success: bool,
    pub message: String,
    pub actions_executed: Vec<String>,
    pub pending_variant_selections: Vec<ActionResponse>, // New: Queue of variant selections
}

impl Default for CommandResult {
    fn default() -> Self {
        Self {
            success: true,
            message: String::new(),
            actions_executed: Vec::new(),
            pending_variant_selections: Vec::new(),
        }
    }
}

/// Generic Action Response for Frontend
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ActionResponse {
    pub action_type: Option<String>,
    pub success: bool,
    pub message: String,
    pub data: Option<serde_json::Value>,
    pub error: Option<String>,
}

/// Cart Action Data
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct CartActionData {
    pub variant_id: i32,
    pub product_name: String,
    pub variant_name: String,
    pub quantity: i32,
    pub available_stock: i32,
    pub sell_price: f64,
    pub session_id: Option<String>,
    pub customer_id: Option<i32>,
}

/// Product Search Action Data
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ProductSearchActionData {
    pub query: String,
    pub results: Vec<ProductSearchResult>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ProductSearchResult {
    pub product_id: i32,
    pub product_name: String,
    pub variant_id: i32,
    pub variant_name: String,
    pub sell_price: f64,
    pub stock: i32,
}

/// Menu Action Data
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct MenuActionData {
    pub category: Option<String>,
    pub products: Vec<ProductSearchResult>,
}

/// Cart Summary Action Data
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct CartSummaryActionData {
    pub session_id: Option<String>,
    pub customer_id: Option<i32>,
    pub total_items: i32,
    pub subtotal: f64,
    pub items: Vec<CartActionData>,
}

/// Variant Selection Action Data - Used when product has multiple variants
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct VariantSelectionActionData {
    pub product_id: i32,
    pub product_name: String,
    pub quantity: i32,
    pub session_id: Option<String>,
    pub customer_id: Option<i32>,
    pub available_variants: Vec<ProductVariant>,
    pub queue_info: Option<serde_json::Value>, // For sequential orchestration
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ProductVariant {
    pub variant_id: i32,
    pub variant_name: String,
    pub sell_price: f64,
    pub stock: i32,
    pub attributes: Option<serde_json::Value>, // For future extension (size, color, etc.)
}

/// Multi-Variant Selection Response - Used when multiple products need variant selection
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct MultiVariantSelectionData {
    pub pending_selections: Vec<VariantSelectionActionData>,
    pub total_items: i32,
    pub message: String,
}

/// Queue Item - Represents a single product waiting in the cart action queue
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct QueuedAction {
    pub action_type: String, // "add_to_cart", "update_quantity", etc.
    pub product_name: String,
    pub quantity: i32,
    pub session_id: Option<String>,
    pub customer_id: Option<i32>,
    pub timestamp: i64, // Unix timestamp for timeout tracking
}

/// Cart Action Queue - Stores pending actions for a user/session
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct CartActionQueue {
    pub queue_id: String, // session_id or customer_id
    pub actions: Vec<QueuedAction>,
    pub current_action: Option<VariantSelectionActionData>,
    pub locked: bool,
    pub created_at: i64,
}

/// Frontend Handshake Request - Confirmation/rejection from frontend
#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct VariantConfirmationRequest {
    pub action: String, // "variant_selection"
    pub status: String, // "success", "cancel", "timeout"
    pub product_name: String,
    pub variant_id: Option<i32>,
    pub quantity: Option<i32>, // Quantity for the selected variant
    pub session_id: Option<String>,
    pub customer_id: Option<i32>,
}

/// Queue Status Response - Information about current queue state
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct QueueStatusResponse {
    pub has_pending: bool,
    pub total_pending: i32,
    pub current_product: Option<String>,
    pub remaining_products: Vec<String>,
}

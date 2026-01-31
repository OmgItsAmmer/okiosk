use crate::models::{
    Action, Command, GeminiContent, GeminiPart, GeminiRequest, GeminiResponse, GenerationConfig,
};
use reqwest::Client;
use serde_json::Value;

const GEMINI_API_URL: &str =
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent";

/// AI Service for communicating with Google Gemini Pro API
pub struct AiService {
    client: Client,
    api_key: String,
}

impl AiService {
    /// Create a new AI Service
    pub fn new(api_key: String) -> Self {
        Self {
            client: Client::new(),
            api_key,
        }
    }

    /// Parse user command using Gemini Pro API
    pub async fn parse_user_command(&self, prompt: &str) -> Result<Command, String> {
        // Check if API key is set
        if self.api_key.is_empty() {
            return Err(
                "Gemini API key is not configured. Please set GEMINI_API_KEY environment variable."
                    .to_string(),
            );
        }

        // Build the system prompt
        let system_prompt = self.build_system_prompt();

        // Build the user prompt
        let full_prompt = format!(
            "{}\n\nUser Command: \"{}\"\n\nPlease analyze this command and return ONLY the JSON response.",
            system_prompt, prompt
        );

        // Call Gemini API
        let gemini_response = self.call_gemini_api(&full_prompt).await?;

        // Parse the response
        let command = self.parse_gemini_response(gemini_response)?;

        Ok(command)
    }

    /// Generate a friendly confirmation message using Gemini
    pub async fn generate_confirmation_message(
        &self,
        actions: &[String],
        prompt: &str,
    ) -> Result<String, String> {
        // Check if API key is set
        if self.api_key.is_empty() {
            return Err(
                "Gemini API key is not configured. Please set GEMINI_API_KEY environment variable."
                    .to_string(),
            );
        }

        let confirmation_prompt = format!(
            "The user said: \"{}\"\n\nWe executed these actions: {}\n\nGenerate a short, friendly confirmation message (1-2 sentences) in the same language as the user's command (English or Urdu). Be natural and conversational.",
            prompt,
            actions.join(", ")
        );

        let gemini_response = self.call_gemini_api(&confirmation_prompt).await?;

        // Extract the text from the response
        if let Some(candidate) = gemini_response.candidates.first() {
            if let Some(part) = candidate.content.parts.first() {
                return Ok(part.text.trim().to_string());
            }
        }

        Err("Failed to generate confirmation message".to_string())
    }

    /// Build the system prompt for command parsing
    fn build_system_prompt(&self) -> String {
        r#"You are an AI assistant for a kiosk ordering system. Your job is to parse natural language commands (in English, Urdu, or mixed) and convert them into structured JSON actions.

**Supported Actions:**
1. add_to_cart - Add items to cart
2. remove_from_cart - Remove items from cart
3. clear_cart - Clear the entire cart
4. generate_bill / checkout - Generate bill or checkout
5. show_menu - Show menu (optionally filtered by category)
6. search_product - Search for products
7. update_quantity - Update item quantity in cart
8. view_cart - View current cart

**Response Format (JSON only, no markdown, no explanations):**
{
  "actions": [
    {
      "action": "add_to_cart",
      "item": "zinger burger",
      "quantity": 2
    }
  ]
}

**Examples:**

User: "add 2 zinger burger to cart and bill bana do"
{
  "actions": [
    {"action": "add_to_cart", "item": "zinger burger", "quantity": 2},
    {"action": "generate_bill"}
  ]
}

User: "3 pizza aur 2 coke add karo"
{
  "actions": [
    {"action": "add_to_cart", "item": "pizza", "quantity": 3},
    {"action": "add_to_cart", "item": "coke", "quantity": 2}
  ]
}

User: "remove burger from cart"
{
  "actions": [
    {"action": "remove_from_cart", "item": "burger"}
  ]
}

User: "show menu"
{
  "actions": [
    {"action": "show_menu"}
  ]
}

User: "checkout kar do"
{
  "actions": [
    {"action": "generate_bill"}
  ]
}

User: "cart dikha do"
{
  "actions": [
    {"action": "view_cart"}
  ]
}

User: "burger search karo"
{
  "actions": [
    {"action": "search_product", "query": "burger"}
  ]
}

User: "Pizza (Medium)" or "add Pizza (Large) to cart"
{
  "actions": [
    {"action": "add_to_cart", "item": "Pizza (Medium)", "quantity": 1}
  ]
}

**Important Rules:**
- Return ONLY valid JSON, no markdown code blocks, no explanations
- Support both English and Urdu (or mixed) commands
- Understand common Urdu words: "karo", "do", "dikha", "bana", "add", etc.
- Extract item names and quantities accurately
- Handle multiple actions in one command
- If quantity is not specified, default to 1
- Be case-insensitive and flexible with item names
- **Variant Selection**: When user specifies variant in format "Product Name (Variant Name)", keep the entire string as item name (e.g., "Pizza (Medium)", "Burger (Large)", "Coffee (Decaf)")
- **Variant Parsing**: The system will automatically parse variant information from the item name format"#.to_string()
    }

    /// Call Gemini Pro API
    async fn call_gemini_api(&self, prompt: &str) -> Result<GeminiResponse, String> {
        let request = GeminiRequest {
            contents: vec![GeminiContent {
                parts: vec![GeminiPart {
                    text: prompt.to_string(),
                }],
            }],
            generation_config: Some(GenerationConfig {
                temperature: 0.2,
                top_p: 0.8,
                top_k: 40,
                max_output_tokens: 1024,
            }),
        };

        let url = format!("{}?key={}", GEMINI_API_URL, self.api_key);

        let response = self
            .client
            .post(&url)
            .json(&request)
            .send()
            .await
            .map_err(|e| format!("Failed to call Gemini API: {}", e))?;

        if !response.status().is_success() {
            let error_text = response
                .text()
                .await
                .unwrap_or_else(|_| "Unknown error".to_string());
            tracing::error!("Gemini API error response: {}", error_text);
            return Err(format!("Gemini API error: {}", error_text));
        }

        let response_text = response
            .text()
            .await
            .map_err(|e| format!("Failed to get response text: {}", e))?;

        let gemini_response: GeminiResponse =
            serde_json::from_str(&response_text).map_err(|e| {
                tracing::error!("Failed to parse Gemini JSON: {}", e);
                format!(
                    "Failed to parse Gemini response: {}. Response: {}",
                    e, response_text
                )
            })?;

        Ok(gemini_response)
    }

    /// Parse Gemini response to extract Command
    fn parse_gemini_response(&self, response: GeminiResponse) -> Result<Command, String> {
        // Extract the text from the first candidate
        let text = response
            .candidates
            .first()
            .and_then(|c| c.content.parts.first())
            .map(|p| p.text.as_str())
            .ok_or_else(|| {
                tracing::error!(
                    "No response from Gemini - candidates: {:?}",
                    response.candidates
                );
                "No response from Gemini".to_string()
            })?;

        tracing::info!("Gemini Response: {}", text);

        // Clean up the text (remove markdown code blocks if present)
        let cleaned_text = text
            .trim()
            .trim_start_matches("```json")
            .trim_start_matches("```")
            .trim_end_matches("```")
            .trim();

        // Parse JSON
        let json_value: Value = serde_json::from_str(cleaned_text).map_err(|e| {
            format!(
                "Failed to parse JSON from Gemini: {}. Text: {}",
                e, cleaned_text
            )
        })?;

        // Extract actions
        let actions_array = json_value
            .get("actions")
            .and_then(|v| v.as_array())
            .ok_or_else(|| "No 'actions' array in response".to_string())?;

        let mut actions: Vec<Action> = Vec::new();

        for action_value in actions_array {
            let action_type = action_value
                .get("action")
                .and_then(|v| v.as_str())
                .ok_or_else(|| "Missing 'action' field".to_string())?;

            let action = match action_type {
                "add_to_cart" => {
                    let item = action_value
                        .get("item")
                        .and_then(|v| v.as_str())
                        .unwrap_or("")
                        .to_string();
                    let quantity = action_value
                        .get("quantity")
                        .and_then(|v| v.as_i64())
                        .unwrap_or(1) as i32;
                    Action::AddToCart {
                        item,
                        quantity,
                        variant_id: None,
                    }
                }
                "remove_from_cart" => {
                    let item = action_value
                        .get("item")
                        .and_then(|v| v.as_str())
                        .unwrap_or("")
                        .to_string();
                    Action::RemoveFromCart {
                        item,
                        variant_id: None,
                    }
                }
                "clear_cart" => Action::ClearCart,
                "generate_bill" => Action::GenerateBill,
                "show_menu" => {
                    let category = action_value
                        .get("category")
                        .and_then(|v| v.as_str())
                        .map(|s| s.to_string());
                    Action::ShowMenu { category }
                }
                "search_product" => {
                    let query = action_value
                        .get("query")
                        .and_then(|v| v.as_str())
                        .unwrap_or("")
                        .to_string();
                    Action::SearchProduct { query }
                }
                "update_quantity" => {
                    let item = action_value
                        .get("item")
                        .and_then(|v| v.as_str())
                        .unwrap_or("")
                        .to_string();
                    let quantity = action_value
                        .get("quantity")
                        .and_then(|v| v.as_i64())
                        .unwrap_or(1) as i32;
                    Action::UpdateQuantity {
                        item,
                        quantity,
                        variant_id: None,
                    }
                }
                "view_cart" => Action::ViewCart,
                "checkout" => {
                    let payment_method = action_value
                        .get("payment_method")
                        .and_then(|v| v.as_str())
                        .unwrap_or("cod")
                        .to_string();
                    let shipping_method = action_value
                        .get("shipping_method")
                        .and_then(|v| v.as_str())
                        .unwrap_or("pickup")
                        .to_string();
                    Action::Checkout {
                        payment_method,
                        shipping_method,
                    }
                }
                _ => {
                    tracing::warn!("Unknown action type: {}", action_type);
                    continue;
                }
            };

            actions.push(action);
        }

        Ok(Command {
            actions,
            response_message: None,
        })
    }
}

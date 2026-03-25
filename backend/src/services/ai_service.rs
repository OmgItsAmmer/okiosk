use crate::models::{Action, Command};
use reqwest::Client;
use serde_json::{json, Value};
use std::env;

/// AI Service for communicating with Gemini API
pub struct AiService {
    client: Client,
    api_key: String,
    gemini_model: String,
}

impl AiService {
    /// Create a new AI Service
    pub fn new(_api_url: String) -> Self {
        // we ignore the passed api_url as we are using Gemini now
        let api_key = env::var("GEMINI_API_KEY").expect("GEMINI_API_KEY must be set");
        let gemini_model = env::var("GEMINI_MODEL")
            .unwrap_or_else(|_| "gemini-2.5-flash".to_string());

        Self {
            client: Client::new(),
            api_key,
            gemini_model,
        }
    }

    /// Parse user command using Gemini API
    pub async fn parse_user_command(&self, prompt: &str) -> Result<Command, String> {
        let system_prompt = self.build_system_prompt();

        let request_body = json!({
            "system_instruction": {
                "parts": [{ "text": system_prompt }]
            },
            "contents": [{
                "role": "user",
                "parts": [{ "text": prompt }]
            }],
            "generationConfig": {
                "response_mime_type": "application/json"
            }
        });

        // Call Gemini API
        let response_json = self.call_gemini_api(&request_body).await?;

        // Parse the response
        self.parse_gemini_json_response(response_json)
    }

    /// Generate a friendly confirmation message using Gemini API
    pub async fn generate_confirmation_message(
        &self,
        actions: &[String],
        prompt: &str,
    ) -> Result<String, String> {
        let system_message = "You are a friendly kiosk assistant. Generate a short, natural confirmation message (1-2 sentences) based on the user's request and the actions taken. Reply in the same language as the user (English or Urdu). Only return the plain text message, no JSON.";

        let user_message = format!(
            "User said: \"{}\"\nActions taken: {}\n\nResponse:",
            prompt,
            actions.join(", ")
        );

        let request_body = json!({
            "system_instruction": {
                "parts": [{ "text": system_message }]
            },
            "contents": [{
                "role": "user",
                "parts": [{ "text": user_message }]
            }]
        });

        let response_json = self.call_gemini_api(&request_body).await?;

        // Extract text
        if let Some(candidates) = response_json.get("candidates").and_then(|v| v.as_array()) {
            if let Some(first) = candidates.first() {
                if let Some(parts) = first
                    .get("content")
                    .and_then(|c| c.get("parts"))
                    .and_then(|p| p.as_array())
                {
                    if let Some(text_part) = parts.first() {
                        if let Some(text) = text_part.get("text").and_then(|t| t.as_str()) {
                            return Ok(text.trim().to_string());
                        }
                    }
                }
            }
        }

        Err("Failed to extract text from Gemini response".to_string())
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
        
        **Response Format (JSON):**
        {
          "actions": [
            { "action": "add_to_cart", "item": "zinger burger", "quantity": 2 }
          ]
        }
        
        **Examples:**
        User: "add 2 zinger burger to cart and bill bana do"
        { "actions": [ {"action": "add_to_cart", "item": "zinger burger", "quantity": 2}, {"action": "generate_bill"} ] }
        
        User: "3 pizza aur 2 coke add karo"
        { "actions": [ {"action": "add_to_cart", "item": "pizza", "quantity": 3}, {"action": "add_to_cart", "item": "coke", "quantity": 2} ] }
        
        User: "remove burger from cart"
        { "actions": [ {"action": "remove_from_cart", "item": "burger"} ] }
        
        User: "show menu"
        { "actions": [ {"action": "show_menu"} ] }
        
        User: "checkout kar do"
        { "actions": [ {"action": "generate_bill"} ] }
        
        User: "cart dikha do"
        { "actions": [ {"action": "view_cart"} ] }
        
        User: "burger search karo"
        { "actions": [ {"action": "search_product", "query": "burger"} ] }
        
        User: "Pizza (Medium)" or "add Pizza (Large) to cart"
        { "actions": [ {"action": "add_to_cart", "item": "Pizza (Medium)", "quantity": 1} ] }
        
        **Important Rules:**
        - Return ONLY valid JSON.
        - Support both English and Urdu (or mixed) commands.
        - Understand common Urdu words: "karo", "do", "dikha", "bana", "add", etc.
        - Extract item names and quantities accurately.
        - Handle multiple actions in one command.
        - If quantity is not specified, default to 1.
        - Be case-insensitive and flexible with item names.
        - **Variant Selection**: When user specifies variant in format "Product Name (Variant Name)", keep the entire string as item.
        "#.to_string()
    }

    /// Call Gemini API
    async fn call_gemini_api(&self, request_body: &Value) -> Result<Value, String> {
        let url = format!(
            "https://generativelanguage.googleapis.com/v1beta/models/{}:generateContent?key={}",
            self.gemini_model,
            self.api_key
        );

        let response = self
            .client
            .post(&url)
            .json(request_body)
            .send()
            .await
            .map_err(|e| format!("Failed to call Gemini API: {}", e))?;

        if !response.status().is_success() {
            let error_text = response
                .text()
                .await
                .unwrap_or_else(|_| "Unknown error".to_string());
            tracing::error!("Gemini API error: {}", error_text);
            return Err(format!("Gemini API error: {}", error_text));
        }

        let response_json: Value = response
            .json()
            .await
            .map_err(|e| format!("Failed to parse Gemini response: {}", e))?;
        Ok(response_json)
    }

    /// Parse JSON response from Gemini
    fn parse_gemini_json_response(&self, response: Value) -> Result<Command, String> {
        // Extract text from the first choice
        let text = response
            .get("candidates")
            .and_then(|v| v.as_array())
            .and_then(|arr| arr.first())
            .and_then(|cand| cand.get("content"))
            .and_then(|cont| cont.get("parts"))
            .and_then(|parts| parts.as_array())
            .and_then(|arr| arr.first())
            .and_then(|part| part.get("text"))
            .and_then(|t| t.as_str())
            .ok_or_else(|| {
                tracing::error!("No text in Gemini response");
                "No valid response text from Gemini".to_string()
            })?;

        tracing::info!("Gemini Response Text: {}", text);

        let json_value: Value = serde_json::from_str(text).map_err(|e| {
            format!(
                "Failed to parse JSON from Gemini text: {}. Text: {}",
                e, text
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

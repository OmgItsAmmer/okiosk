use crate::models::{
    Action, ChatChoice, ChatCompletionRequest, ChatCompletionResponse, ChatMessage, Command,
};
use reqwest::Client;
use serde_json::Value;

/// AI Service for communicating with Local LLM (OpenAI Compatible)
pub struct AiService {
    client: Client,
    api_url: String,
}

impl AiService {
    /// Create a new AI Service
    pub fn new(api_url: String) -> Self {
        Self {
            client: Client::new(),
            api_url,
        }
    }

    /// Parse user command using Local LLM
    pub async fn parse_user_command(&self, prompt: &str) -> Result<Command, String> {
        let system_prompt = self.build_system_prompt();

        let messages = vec![
            ChatMessage {
                role: "system".to_string(),
                content: system_prompt,
            },
            ChatMessage {
                role: "user".to_string(),
                content: prompt.to_string(),
            },
        ];

        // Call LLM API
        let llm_response = self.call_llm_api(messages).await?;

        // Parse the response
        let command = self.parse_llm_response(llm_response)?;

        Ok(command)
    }

    /// Generate a friendly confirmation message using Local LLM
    pub async fn generate_confirmation_message(
        &self,
        actions: &[String],
        prompt: &str,
    ) -> Result<String, String> {
        let system_message = "You are a friendly kiosk assistant. Generate a short, natural confirmation message (1-2 sentences) based on the user's request and the actions taken. Reply in the same language as the user (English or Urdu).".to_string();

        let user_message = format!(
            "User said: \"{}\"\nActions taken: {}\n\nResponse:",
            prompt,
            actions.join(", ")
        );

        let messages = vec![
            ChatMessage {
                role: "system".to_string(),
                content: system_message,
            },
            ChatMessage {
                role: "user".to_string(),
                content: user_message,
            },
        ];

        let llm_response = self.call_llm_api(messages).await?;

        // Extract the text from the response   
        if let Some(choice) = llm_response.choices.first() {
            return Ok(choice.message.content.trim().to_string());
        }

        Err("Failed to generate confirmation message".to_string())
    }

    /// Build the system prompt for command parsing
    fn build_system_prompt(&self) -> String {
        r#"You are an AI assistant for a kiosk ordering system. Your job is to parse natural language commands (in English, Urdu, or mixed) and convert them into structured JSON actions. **Supported Actions:** 1. add_to_cart - Add items to cart 2. remove_from_cart - Remove items from cart 3. clear_cart - Clear the entire cart 4. generate_bill / checkout - Generate bill or checkout 5. show_menu - Show menu (optionally filtered by category) 6. search_product - Search for products 7. update_quantity - Update item quantity in cart 8. view_cart - View current cart **Response Format (JSON only, no markdown, no explanations):** { "actions": [ { "action": "add_to_cart", "item": "zinger burger", "quantity": 2 } ] } **Examples:** User: "add 2 zinger burger to cart and bill bana do" { "actions": [ {"action": "add_to_cart", "item": "zinger burger", "quantity": 2}, {"action": "generate_bill"} ] } User: "3 pizza aur 2 coke add karo" { "actions": [ {"action": "add_to_cart", "item": "pizza", "quantity": 3}, {"action": "add_to_cart", "item": "coke", "quantity": 2} ] } User: "remove burger from cart" { "actions": [ {"action": "remove_from_cart", "item": "burger"} ] } User: "show menu" { "actions": [ {"action": "show_menu"} ] } User: "checkout kar do" { "actions": [ {"action": "generate_bill"} ] } User: "cart dikha do" { "actions": [ {"action": "view_cart"} ] } User: "burger search karo" { "actions": [ {"action": "search_product", "query": "burger"} ] } User: "Pizza (Medium)" or "add Pizza (Large) to cart" { "actions": [ {"action": "add_to_cart", "item": "Pizza (Medium)", "quantity": 1} ] } **Important Rules:** - Return ONLY valid JSON, no markdown code blocks, no explanations - Support both English and Urdu (or mixed) commands - Understand common Urdu words: "karo", "do", "dikha", "bana", "add", etc. - Extract item names and quantities accurately - Handle multiple actions in one command - If quantity is not specified, default to 1 - Be case-insensitive and flexible with item names - **Variant Selection**: When user specifies variant in format "Product Name (Variant Name)", keep the entire string as item"#.to_string()
    }

    /// Call Local LLM API
    async fn call_llm_api(
        &self,
        messages: Vec<ChatMessage>,
    ) -> Result<ChatCompletionResponse, String> {
        let request = ChatCompletionRequest {
            model: "mistral".to_string(), // Model specific name might not matter for local server but good to have
            messages,
            temperature: 0.2,
            top_p: 0.8,
            max_tokens: 1024,
        };

        let response = self
            .client
            .post(&self.api_url)
            .json(&request)
            .send()
            .await
            .map_err(|e| format!("Failed to call LLM API at {}: {}", self.api_url, e))?;

        if !response.status().is_success() {
            let error_text = response
                .text()
                .await
                .unwrap_or_else(|_| "Unknown error".to_string());
            tracing::error!("LLM API error response: {}", error_text);
            return Err(format!("LLM API error: {}", error_text));
        }

        let response_text = response
            .text()
            .await
            .map_err(|e| format!("Failed to get response text: {}", e))?;

        let chat_response: ChatCompletionResponse =
            serde_json::from_str(&response_text).map_err(|e| {
                tracing::error!("Failed to parse LLM JSON: {}", e);
                format!(
                    "Failed to parse LLM response: {}. Response: {}",
                    e, response_text
                )
            })?;

        Ok(chat_response)
    }

    /// Parse LLM response to extract Command
    fn parse_llm_response(&self, response: ChatCompletionResponse) -> Result<Command, String> {
        // Extract the text from the first choice
        let text = response
            .choices
            .first()
            .map(|c| c.message.content.as_str())
            .ok_or_else(|| {
                tracing::error!("No choices in LLM response");
                "No response from LLM".to_string()
            })?;

        tracing::info!("LLM Response: {}", text);

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
                "Failed to parse JSON from LLM: {}. Text: {}",
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

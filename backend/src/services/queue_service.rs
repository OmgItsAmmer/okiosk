use crate::models::{CartActionQueue, GuestCartItem, QueuedAction, VariantSelectionActionData};
use std::collections::HashMap;
use std::sync::{Arc, Mutex};
use std::time::{SystemTime, UNIX_EPOCH};

/// Queue Service - In-memory queue storage (Redis-like)
/// In production, replace this with actual Redis
pub struct QueueService {
    queues: Arc<Mutex<HashMap<String, CartActionQueue>>>,
    guest_carts: Arc<Mutex<HashMap<String, Vec<GuestCartItem>>>>,
    timeout_seconds: i64,
}

impl QueueService {
    pub fn new() -> Self {
        Self {
            queues: Arc::new(Mutex::new(HashMap::new())),
            guest_carts: Arc::new(Mutex::new(HashMap::new())),
            timeout_seconds: 300, // 5 minutes default timeout
        }
    }

    /// Create or update a queue for a user/session
    pub fn create_queue(&self, queue_id: String, actions: Vec<QueuedAction>) -> Result<(), String> {
        let mut queues = self
            .queues
            .lock()
            .map_err(|e| format!("Lock error: {}", e))?;

        let now = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_secs() as i64;

        let queue = CartActionQueue {
            queue_id: queue_id.clone(),
            actions: actions.clone(),
            current_action: None,
            locked: false,
            created_at: now,
        };

        println!(
            "[QUEUE_SERVICE] Creating queue '{}' with {} actions",
            queue_id,
            actions.len()
        );
        for action in &actions {
            println!(
                "[QUEUE_SERVICE]   - Action: {} {} (qty: {})",
                action.action_type, action.product_name, action.quantity
            );
        }

        queues.insert(queue_id.clone(), queue);
        println!("[QUEUE_SERVICE] Queue '{}' created successfully", queue_id);
        Ok(())
    }

    /// Get the current queue for a user/session
    pub fn get_queue(&self, queue_id: &str) -> Result<Option<CartActionQueue>, String> {
        let queues = self
            .queues
            .lock()
            .map_err(|e| format!("Lock error: {}", e))?;
        Ok(queues.get(queue_id).cloned())
    }

    /// Pop the next action from the queue
    pub fn pop_next_action(&self, queue_id: &str) -> Result<Option<QueuedAction>, String> {
        let mut queues = self
            .queues
            .lock()
            .map_err(|e| format!("Lock error: {}", e))?;

        if let Some(queue) = queues.get_mut(queue_id) {
            if queue.actions.is_empty() {
                return Ok(None);
            }

            let action = queue.actions.remove(0);
            Ok(Some(action))
        } else {
            Ok(None)
        }
    }

    /// Set the current action being processed
    pub fn set_current_action(
        &self,
        queue_id: &str,
        action: VariantSelectionActionData,
    ) -> Result<(), String> {
        let mut queues = self
            .queues
            .lock()
            .map_err(|e| format!("Lock error: {}", e))?;

        if let Some(queue) = queues.get_mut(queue_id) {
            queue.current_action = Some(action);
            queue.locked = true;
        }

        Ok(())
    }

    /// Clear the current action
    pub fn clear_current_action(&self, queue_id: &str) -> Result<(), String> {
        let mut queues = self
            .queues
            .lock()
            .map_err(|e| format!("Lock error: {}", e))?;

        if let Some(queue) = queues.get_mut(queue_id) {
            queue.current_action = None;
            queue.locked = false;
        }

        Ok(())
    }

    /// Check if queue has pending actions
    pub fn has_pending(&self, queue_id: &str) -> Result<bool, String> {
        let queues = self
            .queues
            .lock()
            .map_err(|e| format!("Lock error: {}", e))?;

        if let Some(queue) = queues.get(queue_id) {
            Ok(!queue.actions.is_empty())
        } else {
            Ok(false)
        }
    }

    /// Get the number of pending actions
    pub fn pending_count(&self, queue_id: &str) -> Result<i32, String> {
        let queues = self
            .queues
            .lock()
            .map_err(|e| format!("Lock error: {}", e))?;

        if let Some(queue) = queues.get(queue_id) {
            Ok(queue.actions.len() as i32)
        } else {
            Ok(0)
        }
    }

    /// Clear the entire queue for a user/session
    pub fn clear_queue(&self, queue_id: &str) -> Result<(), String> {
        let mut queues = self
            .queues
            .lock()
            .map_err(|e| format!("Lock error: {}", e))?;
        queues.remove(queue_id);
        Ok(())
    }

    /// Lock the queue (prevent concurrent operations)
    pub fn lock_queue(&self, queue_id: &str) -> Result<bool, String> {
        let mut queues = self
            .queues
            .lock()
            .map_err(|e| format!("Lock error: {}", e))?;

        if let Some(queue) = queues.get_mut(queue_id) {
            if queue.locked {
                return Ok(false); // Already locked
            }
            queue.locked = true;
            Ok(true)
        } else {
            Ok(false)
        }
    }

    /// Unlock the queue
    pub fn unlock_queue(&self, queue_id: &str) -> Result<(), String> {
        let mut queues = self
            .queues
            .lock()
            .map_err(|e| format!("Lock error: {}", e))?;

        if let Some(queue) = queues.get_mut(queue_id) {
            queue.locked = false;
        }

        Ok(())
    }

    /// Check and clean up expired queues
    pub fn cleanup_expired_queues(&self) -> Result<usize, String> {
        let mut queues = self
            .queues
            .lock()
            .map_err(|e| format!("Lock error: {}", e))?;

        let now = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_secs() as i64;

        let expired_keys: Vec<String> = queues
            .iter()
            .filter(|(_, queue)| now - queue.created_at > self.timeout_seconds)
            .map(|(key, _)| key.clone())
            .collect();

        let count = expired_keys.len();
        for key in expired_keys {
            queues.remove(&key);
        }

        Ok(count)
    }

    /// Get remaining product names in queue
    pub fn get_remaining_products(&self, queue_id: &str) -> Result<Vec<String>, String> {
        let queues = self
            .queues
            .lock()
            .map_err(|e| format!("Lock error: {}", e))?;

        if let Some(queue) = queues.get(queue_id) {
            Ok(queue
                .actions
                .iter()
                .map(|a| a.product_name.clone())
                .collect())
        } else {
            Ok(Vec::new())
        }
    }

    /// Check if queue is locked
    pub fn is_locked(&self, queue_id: &str) -> Result<bool, String> {
        let queues = self
            .queues
            .lock()
            .map_err(|e| format!("Lock error: {}", e))?;

        if let Some(queue) = queues.get(queue_id) {
            println!(
                "[QUEUE_SERVICE] Queue '{}' exists, locked: {}",
                queue_id, queue.locked
            );
            Ok(queue.locked)
        } else {
            println!("[QUEUE_SERVICE] Queue '{}' not found", queue_id);
            Ok(false)
        }
    }

    /// Add item to guest cart (in-memory)
    pub fn add_to_guest_cart(
        &self,
        session_id: &str,
        variant_id: i32,
        quantity: i32,
    ) -> Result<(), String> {
        let mut carts = self
            .guest_carts
            .lock()
            .map_err(|e| format!("Lock error: {}", e))?;
        let cart = carts.entry(session_id.to_string()).or_insert_with(Vec::new);

        // Check if variant already exists in guest cart
        if let Some(item) = cart.iter_mut().find(|i| i.variant_id == variant_id) {
            item.quantity += quantity;
            println!(
                "[QUEUE_SERVICE] Updated variant {} in guest cart (session: {}), new quantity: {}",
                variant_id, session_id, item.quantity
            );
        } else {
            let now = SystemTime::now()
                .duration_since(UNIX_EPOCH)
                .unwrap()
                .as_secs() as i64;
            cart.push(GuestCartItem {
                variant_id,
                quantity,
                added_at: now,
            });
            println!(
                "[QUEUE_SERVICE] Added variant {} to guest cart (session: {}), quantity: {}",
                variant_id, session_id, quantity
            );
        }
        Ok(())
    }

    /// Get items from guest cart
    pub fn get_guest_cart(&self, session_id: &str) -> Result<Vec<GuestCartItem>, String> {
        let carts = self
            .guest_carts
            .lock()
            .map_err(|e| format!("Lock error: {}", e))?;
        Ok(carts.get(session_id).cloned().unwrap_or_default())
    }

    /// Update quantity for a variant in guest cart
    pub fn update_guest_cart_item(
        &self,
        session_id: &str,
        variant_id: i32,
        quantity: i32,
    ) -> Result<bool, String> {
        let mut carts = self
            .guest_carts
            .lock()
            .map_err(|e| format!("Lock error: {}", e))?;

        if let Some(cart) = carts.get_mut(session_id) {
            if quantity <= 0 {
                let initial_len = cart.len();
                cart.retain(|i| i.variant_id != variant_id);
                if cart.len() < initial_len {
                    println!(
                        "[QUEUE_SERVICE] Removed variant {} from guest cart (session: {})",
                        variant_id, session_id
                    );
                    return Ok(true);
                }
                return Ok(false);
            }
            if let Some(item) = cart.iter_mut().find(|i| i.variant_id == variant_id) {
                item.quantity = quantity;
                println!(
                    "[QUEUE_SERVICE] Updated variant {} in guest cart (session: {}), quantity: {}",
                    variant_id, session_id, quantity
                );
                return Ok(true);
            }
        }
        Ok(false)
    }

    /// Remove a variant from guest cart
    pub fn remove_from_guest_cart(
        &self,
        session_id: &str,
        variant_id: i32,
    ) -> Result<bool, String> {
        let mut carts = self
            .guest_carts
            .lock()
            .map_err(|e| format!("Lock error: {}", e))?;

        if let Some(cart) = carts.get_mut(session_id) {
            let initial_len = cart.len();
            cart.retain(|i| i.variant_id != variant_id);
            if cart.len() < initial_len {
                println!(
                    "[QUEUE_SERVICE] Removed variant {} from guest cart (session: {})",
                    variant_id, session_id
                );
                return Ok(true);
            }
        }
        Ok(false)
    }

    /// Clear guest cart
    pub fn clear_guest_cart(&self, session_id: &str) -> Result<(), String> {
        let mut carts = self
            .guest_carts
            .lock()
            .map_err(|e| format!("Lock error: {}", e))?;
        carts.remove(session_id);
        Ok(())
    }
}

impl Default for QueueService {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_queue_creation() {
        let service = QueueService::new();
        let actions = vec![QueuedAction {
            action_type: "add_to_cart".to_string(),
            product_name: "Lux".to_string(),
            quantity: 1,
            session_id: Some("test-123".to_string()),
            customer_id: None,
            timestamp: 0,
        }];

        let result = service.create_queue("test-123".to_string(), actions);
        assert!(result.is_ok());
    }

    #[test]
    fn test_pop_action() {
        let service = QueueService::new();
        let actions = vec![QueuedAction {
            action_type: "add_to_cart".to_string(),
            product_name: "Lux".to_string(),
            quantity: 1,
            session_id: Some("test-123".to_string()),
            customer_id: None,
            timestamp: 0,
        }];

        service
            .create_queue("test-123".to_string(), actions)
            .unwrap();
        let action = service.pop_next_action("test-123").unwrap();

        assert!(action.is_some());
        assert_eq!(action.unwrap().product_name, "Lux");
    }
}

# Sequential Queue Orchestration Architecture

## Executive Summary

This document describes the new **Sequential Queue Orchestration Model** for
handling multi-item variant selection in the AI cart system. Instead of showing
all product variants at once, the system now processes products one at a time,
providing a cleaner UX and more predictable state management.

---

## Problem with Previous Approach

### Old Flow (Parallel Multi-Variant):

```
User: "Add lux and rice to cart"
Backend: Returns ALL variants for BOTH products at once
Frontend: Must handle complex state for 2+ products simultaneously
Issues:
- Complex state management
- Poor UX (overwhelming)
- Hard to track partial completions
- Difficult error recovery
```

### New Flow (Sequential Orchestration):

```
User: "Add lux and rice to cart"
Backend: Returns ONLY lux variants + queues rice
Frontend: Shows lux variants, user selects
Frontend: Sends confirmation → Backend
Backend: Sends rice variants
Frontend: Shows rice variants, user selects
Frontend: Sends confirmation → Backend
Backend: All done!
```

---

## Architecture Components

### 1. Queue Storage Service (`src/services/queue_service.rs`)

**Purpose**: In-memory queue storage (Redis-like) for pending actions

**Key Features**:

- Stores pending actions per user/session
- Lock mechanism to prevent concurrent operations
- Timeout handling for abandoned queues
- CRUD operations for queue management

**Data Structure**:

```rust
pub struct CartActionQueue {
    pub queue_id: String,              // session_id or customer_id
    pub actions: Vec<QueuedAction>,    // Remaining products to process
    pub current_action: Option<VariantSelectionActionData>, // Currently being confirmed
    pub locked: bool,                  // Lock during confirmation
    pub created_at: i64,               // For timeout tracking
}

pub struct QueuedAction {
    pub action_type: String,           // "add_to_cart"
    pub product_name: String,          // "Rice"
    pub quantity: i32,                 // 1
    pub session_id: Option<String>,
    pub customer_id: Option<i32>,
    pub timestamp: i64,                // When queued
}
```

**Key Methods**:

```rust
create_queue(queue_id, actions) → Result<(), String>
pop_next_action(queue_id) → Result<Option<QueuedAction>, String>
set_current_action(queue_id, action) → Result<(), String>
clear_current_action(queue_id) → Result<(), String>
lock_queue(queue_id) → Result<bool, String>
unlock_queue(queue_id) → Result<(), String>
cleanup_expired_queues() → Result<usize, String>
```

---

### 2. New API Endpoints

#### A. **Initial AI Command** (Modified)

**Endpoint**: `POST /api/ai/command`

**Request**:

```json
{
    "prompt": "add lux and rice to cart",
    "session_id": "kiosk-123",
    "customer_id": null
}
```

**Response** (Multiple items detected):

```json
{
    "success": true,
    "message": "Please select variant for Lux (1 of 2 items)",
    "actions_executed": [
        "{
      \"action_type\": \"variant_selection\",
      \"data\": {
        \"product_name\": \"Lux\",
        \"quantity\": 1,
        \"available_variants\": [...],
        \"queue_info\": {
          \"position\": 1,
          \"total\": 2,
          \"remaining\": [\"Rice\"]
        }
      }
    }"
    ],
    "error": null
}
```

#### B. **Variant Confirmation** (New)

**Endpoint**: `POST /api/ai/variant-confirm`

**Request**:

```json
{
    "action": "variant_selection",
    "status": "success", // or "cancel", "timeout"
    "product_name": "Lux",
    "variant_id": 456,
    "session_id": "kiosk-123",
    "customer_id": null
}
```

**Response** (Next product in queue):

```json
{
  "success": true,
  "message": "Lux added! Now select variant for Rice (2 of 2 items)",
  "has_more": true,
  "next_action": {
    "action_type": "variant_selection",
    "data": {
      \"product_name\": \"Rice\",
      \"quantity\": 1,
      \"available_variants\": [...],
      \"queue_info\": {
        \"position\": 2,
        \"total\": 2,
        \"remaining\": []
      }
    }
  }
}
```

**Response** (Queue complete):

```json
{
    "success": true,
    "message": "All items added to cart successfully!",
    "has_more": false,
    "next_action": null
}
```

**Response** (User cancelled):

```json
{
    "success": false,
    "message": "Action cancelled. Remaining items cleared from queue.",
    "has_more": false,
    "next_action": null
}
```

#### C. **Queue Status** (New)

**Endpoint**: `GET /api/ai/queue-status?session_id=kiosk-123`

**Response**:

```json
{
    "has_pending": true,
    "total_pending": 1,
    "current_product": "Lux",
    "remaining_products": ["Rice"]
}
```

---

### 3. Backend Flow Implementation

#### Step 1: AI Command Processing

```rust
// In process_ai_command handler

// 1. Parse AI command
let command = ai_state.ai_service.parse_user_command(&payload.prompt).await?;

// 2. Execute command executor
let result = executor.execute_command(command, session_id, customer_id).await;

// 3. Check for variant selections
if !result.pending_variant_selections.is_empty() {
    
    if result.pending_variant_selections.len() == 1 {
        // Single item - return immediately (existing logic)
        return Ok(Json(single_variant_response));
    } else {
        // Multiple items - SEQUENTIAL ORCHESTRATION
        
        // Get queue ID
        let queue_id = get_queue_id(session_id, customer_id);
        
        // Pop first product
        let first_product = result.pending_variant_selections[0].clone();
        
        // Queue remaining products
        let mut queued_actions = Vec::new();
        for i in 1..result.pending_variant_selections.len() {
            let variant_data = &result.pending_variant_selections[i];
            
            queued_actions.push(QueuedAction {
                action_type: "add_to_cart".to_string(),
                product_name: variant_data.product_name.clone(),
                quantity: variant_data.quantity,
                session_id: session_id.map(|s| s.to_string()),
                customer_id,
                timestamp: get_timestamp(),
            });
        }
        
        // Create queue
        ai_state.queue_service.create_queue(queue_id.clone(), queued_actions)?;
        
        // Set current action
        ai_state.queue_service.set_current_action(&queue_id, first_product.clone())?;
        
        // Return first product only
        return Ok(Json(create_sequential_response(first_product, 1, result.pending_variant_selections.len())));
    }
}
```

#### Step 2: Variant Confirmation Handler

```rust
// New endpoint: /api/ai/variant-confirm

pub async fn confirm_variant_selection(
    State(ai_state): State<Arc<AiState>>,
    Json(payload): Json<VariantConfirmationRequest>,
) -> Result<Json<AiCommandResponse>, StatusCode> {
    
    let queue_id = get_queue_id(payload.session_id.as_deref(), payload.customer_id);
    
    // Check lock
    if !ai_state.queue_service.is_locked(&queue_id).unwrap_or(false) {
        return Ok(Json(AiCommandResponse {
            success: false,
            message: "No active queue".to_string(),
            actions_executed: Vec::new(),
            error: Some("Queue not found or expired".to_string()),
        }));
    }
    
    match payload.status.as_str() {
        "success" => {
            // 1. Add confirmed variant to cart
            if let Some(variant_id) = payload.variant_id {
                add_to_cart_internal(
                    ai_state.db.clone(),
                    variant_id,
                    payload.quantity,
                    payload.session_id.as_deref(),
                    payload.customer_id,
                ).await?;
            }
            
            // 2. Clear current action
            ai_state.queue_service.clear_current_action(&queue_id)?;
            
            // 3. Check if more items in queue
            if let Some(next_queued_action) = ai_state.queue_service.pop_next_action(&queue_id)? {
                
                // 4. Fetch variants for next product
                let next_variant_data = fetch_product_variants(
                    ai_state.db.clone(),
                    &next_queued_action.product_name,
                    next_queued_action.quantity,
                ).await?;
                
                // 5. Set as current action
                ai_state.queue_service.set_current_action(&queue_id, next_variant_data.clone())?;
                
                // 6. Return next product
                let remaining_count = ai_state.queue_service.pending_count(&queue_id)?;
                
                return Ok(Json(create_next_product_response(next_variant_data, remaining_count)));
                
            } else {
                // Queue empty - all done!
                ai_state.queue_service.clear_queue(&queue_id)?;
                
                return Ok(Json(AiCommandResponse {
                    success: true,
                    message: "All items added to cart successfully!".to_string(),
                    actions_executed: vec!["queue_completed".to_string()],
                    error: None,
                }));
            }
        },
        
        "cancel" | "timeout" => {
            // User cancelled - clear entire queue
            ai_state.queue_service.clear_queue(&queue_id)?;
            
            return Ok(Json(AiCommandResponse {
                success: false,
                message: "Action cancelled. Queue cleared.".to_string(),
                actions_executed: Vec::new(),
                error: Some("User cancelled".to_string()),
            }));
        },
        
        _ => {
            return Ok(Json(AiCommandResponse {
                success: false,
                message: "Invalid status".to_string(),
                actions_executed: Vec::new(),
                error: Some("Invalid status value".to_string()),
            }));
        }
    }
}
```

---

### 4. Timeout Handling

**Background Task**:

```rust
// In main.rs or dedicated cleanup service

tokio::spawn(async move {
    let queue_service = ai_state.queue_service.clone();
    
    loop {
        // Clean up expired queues every 60 seconds
        tokio::time::sleep(Duration::from_secs(60)).await;
        
        match queue_service.cleanup_expired_queues() {
            Ok(count) => {
                if count > 0 {
                    println!("[CLEANUP] Removed {} expired queues", count);
                }
            },
            Err(e) => {
                eprintln!("[CLEANUP ERROR] {}", e);
            }
        }
    }
});
```

**Timeout Settings**:

- Default timeout: 5 minutes (300 seconds)
- Configurable via environment variable
- Timeout starts from queue creation
- On timeout, queue is automatically deleted

---

### 5. Lock Mechanism

**Purpose**: Prevent concurrent operations on the same queue

**How it works**:

1. When first product sent → Queue is locked
2. While waiting for frontend confirmation → Queue remains locked
3. After confirmation (success/cancel) → Queue is unlocked
4. Next product sent → Queue is locked again

**Code**:

```rust
// Lock when setting current action
ai_state.queue_service.set_current_action(&queue_id, variant_data)?;
// Queue is now locked

// Unlock after handling confirmation
ai_state.queue_service.clear_current_action(&queue_id)?;
// Queue is now unlocked (but still exists if more items)

// Or unlock explicitly
ai_state.queue_service.unlock_queue(&queue_id)?;
```

---

### 6. Error Recovery

**Scenarios**:

1. **User Cancels**:
   - Frontend sends `{status: "cancel"}`
   - Backend clears entire queue
   - User can start fresh

2. **Network Timeout**:
   - Frontend timeout (30s) → sends `{status: "timeout"}`
   - Backend clears queue
   - User notified

3. **Server Restart**:
   - In-memory queue lost (acceptable for this use case)
   - For production: Use Redis for persistence
   - Queue expires after 5 minutes anyway

4. **Partial Completion**:
   - Already-added items remain in cart
   - Remaining items discarded
   - User can manually add or retry

---

## Frontend Integration

### Required Changes

See updated `FRONTEND_MULTI_VARIANT_SOLUTION.md` for complete frontend
implementation guide.

**Key Points**:

1. **Detect Sequential vs Single**:

```dart
if (actionData['queue_info'] != null) {
  // Sequential orchestration
  handleSequentialVariant(actionData);
} else if (actionData['action_type'] == 'variant_selection') {
  // Single item (existing logic)
  handleSingleVariant(actionData);
}
```

2. **Show Queue Progress**:

```dart
// Show: "Selecting variants (1 of 2)"
Text('Selecting variants (${queueInfo['position']} of ${queueInfo['total']})')
```

3. **Send Confirmation**:

```dart
// After user selects variant
await http.post('/api/ai/variant-confirm', body: {
  'action': 'variant_selection',
  'status': 'success',
  'product_name': 'Lux',
  'variant_id': 456,
  'session_id': sessionId,
});
```

4. **Handle Next Product**:

```dart
final response = await confirmVariant(...);
if (response['has_more'] == true) {
  // Show next product variants
  showVariantDialog(response['next_action']['data']);
} else {
  // All done!
  showSuccess('All items added!');
}
```

---

## Benefits

✅ **Cleaner UX**: One product at a time, less overwhelming\
✅ **Predictable State**: No complex multi-state management\
✅ **Error Safety**: Partial failures don't break the whole flow\
✅ **Easy to Scale**: Can extend to other multi-step operations\
✅ **Conversational**: Mirrors natural assistant behavior\
✅ **Better Tracking**: Clear progress indication\
✅ **Simpler Debugging**: Easier to trace issues

---

## Migration Path

### Phase 1: Backend Implementation ✅

- Implement QueueService
- Add variant confirmation endpoint
- Update AI command handler
- Add timeout cleanup

### Phase 2: Frontend Update (Required)

- Add sequential variant detection
- Implement confirmation API call
- Show queue progress UI
- Handle cancellation

### Phase 3: Testing

- Test single item (existing)
- Test 2 items sequential
- Test 3+ items sequential
- Test cancellation
- Test timeout
- Test error recovery

### Phase 4: Production

- Replace in-memory queue with Redis
- Add monitoring/metrics
- Configure timeouts
- Deploy

---

## Future Enhancements

1. **Undo/Redo**: Allow users to go back to previous product
2. **Save Progress**: Persist queue across sessions
3. **Batch Operations**: Extend to remove, update, etc.
4. **Smart Defaults**: Remember user's variant preferences
5. **Voice Integration**: "Next", "Cancel", "Go back" commands

---

## Summary

The **Sequential Queue Orchestration Model** transforms multi-item variant
selection from a complex parallel operation into a simple, sequential flow. The
backend manages the queue, the frontend confirms one product at a time, and the
user enjoys a clean, predictable experience.

**Next Step**: Update frontend to implement the new handshake protocol (see
`FRONTEND_MULTI_VARIANT_SOLUTION.md`).

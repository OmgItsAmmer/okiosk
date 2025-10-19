# Sequential Variant Selection Debug Guide

## 🔧 Issue Fixed

### Problem Description

When users prompted "add xyz and abc to cart", the backend correctly sent a
message to select the variant of xyz first, but when the user selected a
variant, the system threw an error: **"no active queue found"** instead of:

1. Adding xyz to cart
2. Sending the next product (abc) for variant selection

### Root Cause Analysis

The frontend was implementing the sequential variant selection flow correctly
according to `FRONTEND_VARIANT_SELECTION_UPDATE.md`, but the error "no active
queue found" indicated one of the following issues:

1. **Backend Issue**: The backend is not properly maintaining the queue for the
   session_id
2. **Session Mismatch**: The session_id sent in the initial command doesn't
   match the one sent in the confirmation
3. **Queue Expiration**: The backend queue expired between the initial command
   and the variant confirmation
4. **Backend Restart**: The backend restarted and lost all in-memory queues

---

## ✅ What Was Fixed

### 1. Comprehensive Debug Logging

Added extensive debug logging throughout the entire flow to trace the session_id
and all requests/responses:

#### Initial AI Command (chat_controller.dart)

```dart
========== SENDING AI COMMAND ==========
ChatController: Message: add xyz and abc to cart
ChatController: Session ID: kiosk-1234567890
========================================
```

#### AI Command Request (ai_command_service.dart)

```dart
========== AI COMMAND REQUEST ==========
AiCommandService: Sending AI command
AiCommandService: Prompt: add xyz and abc to cart
AiCommandService: Session ID: kiosk-1234567890
AiCommandService: Request body: {prompt: add xyz and abc to cart, session_id: kiosk-1234567890}
========================================
```

#### Sequential Variant Detection (chat_controller.dart)

```dart
========== SEQUENTIAL VARIANT DETECTED ==========
ChatController: Sequential variant selection detected
ChatController: Queue position: 1/2
ChatController: Product: xyz
ChatController: Remaining: abc
ChatController: Session ID will be: kiosk-1234567890
=================================================
```

#### Variant Selection (variant_selection_bubble.dart)

```dart
========== VARIANT SELECTED ==========
VariantSelectionBubble: User selected a variant
VariantSelectionBubble: Product: xyz
VariantSelectionBubble: Variant ID: 123
VariantSelectionBubble: Queue Position: 1/2
VariantSelectionBubble: Remaining: abc
======================================
```

#### Variant Confirmation Request (ai_command_service.dart)

```dart
====== VARIANT CONFIRMATION REQUEST ======
AiCommandService: Confirming variant selection
AiCommandService: Product Name: xyz
AiCommandService: Session ID: kiosk-1234567890
AiCommandService: Variant ID: 123
AiCommandService: Full Request Body: {action: variant_selection, status: success, product_name: xyz, variant_id: 123, session_id: kiosk-1234567890}
==========================================
```

#### Variant Confirmation Response (ai_command_service.dart)

```dart
====== VARIANT CONFIRMATION RESPONSE ======
AiCommandService: Response success: false
AiCommandService: Response message: no active queue found
AiCommandService: Status code: 404
============================================
```

### 2. Enhanced Error Handling

Added better error handling to detect and explain the "no active queue found"
error:

```dart
// Check if it's a "no active queue found" error
final errorMsg = response.message.toLowerCase();
if (errorMsg.contains('no active queue') || errorMsg.contains('queue not found')) {
  _addErrorMessage(
    'Session expired or queue not found. This usually happens when:\n'
    '• The backend restarted\n'
    '• Too much time passed between selections\n'
    '• The session was cleared\n\n'
    'Please try your command again from the start.',
  );
}
```

### 3. Better Error Propagation

Added error field to `VariantConfirmResponse` class to capture backend error
details:

```dart
class VariantConfirmResponse {
  final bool success;
  final String message;
  final bool hasMore;
  final AiAction? nextAction;
  final String? error;  // NEW: Error details from backend
  
  // ...
}
```

---

## 🔍 How to Debug the Issue

### Step 1: Enable Debug Mode

Make sure the app is running in debug mode (not release mode) to see all the
debug logs.

### Step 2: Trigger the Issue

1. Open the app
2. Send command: "add xyz and abc to cart" (use actual product names that have
   multiple variants)
3. Wait for the variant selection UI to appear
4. Select a variant
5. Watch the console output

### Step 3: Analyze the Logs

Look for these key sections in the logs:

#### ✅ Verify Session ID Consistency

Check that the session_id is the SAME in all these logs:

1. Initial command: `ChatController: Session ID: kiosk-XXXXXXXXX`
2. AI command request: `AiCommandService: Session ID: kiosk-XXXXXXXXX`
3. Variant confirmation: `AiCommandService: Session ID: kiosk-XXXXXXXXX`

**If the session_id changes, this is a frontend bug.**

#### ✅ Verify Queue Info is Present

Check that queue_info is detected:

```
ChatController: Queue position: 1/2
ChatController: Remaining: abc
```

**If queue_info is missing, the backend is not sending it correctly.**

#### ✅ Verify Confirmation Request

Check that the confirmation request includes all required fields:

```
Full Request Body: {
  action: variant_selection, 
  status: success, 
  product_name: xyz, 
  variant_id: 123, 
  session_id: kiosk-1234567890
}
```

**If any field is missing or null, this is a frontend bug.**

#### ❌ Check Backend Response

Look at the confirmation response:

```
Response success: false
Response message: no active queue found
Status code: 404
```

**If you see this, the backend doesn't have a queue for this session_id.**

---

## 🐛 Common Issues and Solutions

### Issue 1: Session ID Changes Between Requests

**Symptoms:**

- Initial command uses `session_id: kiosk-123`
- Confirmation uses `session_id: kiosk-456`

**Cause:** The frontend is generating a new session_id or not maintaining it
properly.

**Solution:** Check `chat_controller.dart` line 43 where `_currentSessionId` is
initialized. Make sure it's not being reset.

---

### Issue 2: Backend Returns "no active queue found"

**Symptoms:**

- Session ID is consistent across all requests
- Backend responds with 404 and "no active queue found"

**Cause:** The backend is not maintaining the queue or it expired.

**Solution:** This is a **BACKEND ISSUE**. Check the backend logs to verify:

1. The backend created a queue when processing the initial command
2. The queue is stored in memory with the correct session_id
3. The queue didn't expire or get cleared

**Backend Debug Steps:**

1. Check if the backend is using in-memory storage for queues (not persistent)
2. Check if the backend restarted between the initial command and confirmation
3. Check if there's a queue expiration timeout
4. Verify the backend is correctly parsing the session_id from both requests

---

### Issue 3: Backend Doesn't Send queue_info

**Symptoms:**

- Frontend doesn't detect sequential variant selection
- No "Queue position: 1/2" in logs

**Cause:** Backend is not sending the `queue_info` field in the response.

**Solution:** This is a **BACKEND ISSUE**. The backend must include `queue_info`
in the action data:

```json
{
  "action_type": "variant_selection",
  "data": {
    "product_name": "xyz",
    "available_variants": [...],
    "queue_info": {
      "position": 1,
      "total": 2,
      "remaining": ["abc"]
    }
  }
}
```

---

### Issue 4: Confirmation Request Missing Fields

**Symptoms:**

- Confirmation request doesn't include all required fields
- Backend returns validation error

**Cause:** Frontend is not passing all parameters correctly.

**Solution:** Check the confirmation call in `variant_selection_bubble.dart`:

```dart
chatController.confirmSequentialVariant(
  productName: variantData.productName,  // Must not be null
  variantId: variant.variantId,           // Must not be null
);
```

---

## 📋 Expected Flow with Debug Logs

Here's what you should see in a successful flow:

```
========== SENDING AI COMMAND ==========
ChatController: Message: add lux and rice to cart
ChatController: Session ID: kiosk-1234567890
========================================

========== AI COMMAND REQUEST ==========
AiCommandService: Prompt: add lux and rice to cart
AiCommandService: Session ID: kiosk-1234567890
========================================

========== AI COMMAND RESPONSE ==========
AiCommandService: Response success: true
AiCommandService: Actions count: 1
=========================================

========== SEQUENTIAL VARIANT DETECTED ==========
ChatController: Queue position: 1/2
ChatController: Product: lux
ChatController: Remaining: rice
ChatController: Session ID will be: kiosk-1234567890
=================================================

[User selects variant]

========== VARIANT SELECTED ==========
VariantSelectionBubble: Product: lux
VariantSelectionBubble: Variant ID: 456
VariantSelectionBubble: Queue Position: 1/2
======================================

====== VARIANT CONFIRMATION REQUEST ======
AiCommandService: Product Name: lux
AiCommandService: Session ID: kiosk-1234567890
AiCommandService: Variant ID: 456
==========================================

====== VARIANT CONFIRMATION RESPONSE ======
AiCommandService: Response success: true
AiCommandService: Response message: Lux added! Now select variant for rice
AiCommandService: Has more items: true
============================================

========== CONFIRMATION RESPONSE ==========
ChatController: Response success: true
ChatController: Has more items: true
ChatController: Next position: 2/2
ChatController: Next product: rice
===========================================

[Next variant selection appears for rice]
```

---

## 🎯 Next Steps

1. **Run the app in debug mode**
2. **Trigger the issue** by adding multiple products with variants
3. **Capture the full console output** from initial command to error
4. **Analyze the logs** using this guide
5. **Determine if it's a frontend or backend issue**:
   - ✅ Session ID consistent? → Backend issue
   - ❌ Session ID changes? → Frontend issue
   - ✅ Queue info present? → Backend issue
   - ❌ Queue info missing? → Backend issue

---

## 💡 Tips for Backend Team

If this is a backend issue, here are common fixes:

### 1. Implement Queue Storage

```rust
// Use a global HashMap to store queues
static VARIANT_QUEUES: Lazy<Mutex<HashMap<String, VecDeque<ProductInfo>>>> = 
    Lazy::new(|| Mutex::new(HashMap::new()));

// On initial command
fn create_queue(session_id: &str, products: Vec<ProductInfo>) {
    let mut queues = VARIANT_QUEUES.lock().unwrap();
    let mut queue = VecDeque::new();
    for product in products {
        queue.push_back(product);
    }
    queues.insert(session_id.to_string(), queue);
}

// On confirmation
fn get_next_product(session_id: &str) -> Option<ProductInfo> {
    let mut queues = VARIANT_QUEUES.lock().unwrap();
    if let Some(queue) = queues.get_mut(session_id) {
        queue.pop_front()
    } else {
        None // This is where "no active queue found" happens
    }
}
```

### 2. Add Queue Expiration

```rust
struct QueueEntry {
    queue: VecDeque<ProductInfo>,
    created_at: Instant,
}

const QUEUE_TIMEOUT: Duration = Duration::from_secs(300); // 5 minutes

fn is_queue_expired(entry: &QueueEntry) -> bool {
    entry.created_at.elapsed() > QUEUE_TIMEOUT
}
```

### 3. Log Queue Operations

```rust
println!("Creating queue for session: {}", session_id);
println!("Queue contains {} products", products.len());

println!("Looking up queue for session: {}", session_id);
if let Some(queue) = queues.get(session_id) {
    println!("Found queue with {} remaining products", queue.len());
} else {
    println!("ERROR: No queue found for session: {}", session_id);
}
```

---

## ✨ Summary

The frontend has been enhanced with:

- ✅ Comprehensive debug logging
- ✅ Better error handling for queue errors
- ✅ User-friendly error messages
- ✅ Complete trace of session_id throughout the flow

The next step is to:

1. Run the app and capture logs
2. Determine if the issue is frontend or backend
3. Fix the appropriate layer based on the logs

Most likely, this is a **backend issue** where the queue is not being maintained
properly between the initial command and the confirmation request.

# AI Action Response Flow

## Overview

The AI system now handles two types of responses seamlessly:

1. **Action-based responses** (e.g., `add_to_cart`, `remove_from_cart`) -
   Execute actions locally
2. **Message-based responses** (e.g., `search_product`) - Display AI message in
   chat

## Architecture

```
User Input (Chat)
    ↓
ChatController.sendMessage()
    ↓
AiCommandService.processCommandAndExecute()
    ↓
Backend AI (Validates & Returns ActionResponse)
    ↓
AiActionExecutor.executeActions() [For cart actions]
    ↓
Display AI Message in Chat [For all responses]
```

## Response Format

### Backend AI Response Structure

```json
{
    "success": true,
    "message": "Added 2 Large Pizza to cart", // ← This is displayed in chat
    "actions_executed": [
        {
            "action_type": "add_to_cart",
            "success": true,
            "message": "Ready to add 2 Large Pizza to cart",
            "data": {
                "variant_id": 123,
                "product_name": "Large Pizza",
                "variant_name": "Large",
                "quantity": 2,
                "available_stock": 50,
                "sell_price": 15.99
            },
            "error": null
        }
    ],
    "error": null
}
```

## Flow Details

### 1. User Sends Message

```dart
// In ChatController
await sendMessage("add 2 large pizzas to cart");
```

### 2. Process Command & Execute Actions

```dart
// AiCommandService.processCommandAndExecute()
final result = await processCommandAndExecute(
  prompt: "add 2 large pizzas to cart",
  sessionId: "kiosk-session-123",
);

// Returns ProcessResult with:
// - success: bool
// - message: string (from AI response)
```

### 3. Execute Actions (If Any)

```dart
// AiActionExecutor automatically handles:
// - add_to_cart → Adds to local cart (skips validation)
// - remove_from_cart → Removes from cart
// - update_quantity → Updates quantity
// - clear_cart → Clears cart
```

### 4. Display Message in Chat

```dart
// ChatController displays the AI message
if (result.success) {
  _addAssistantMessage(result.message); // Shows AI's message
} else {
  _addErrorMessage(result.message);
}
```

## Example Scenarios

### Scenario 1: Add to Cart (Action + Message)

**User:** "add 2 large pizzas"

**Backend Response:**

```json
{
  "message": "Added 2 Large Pizza to your cart",
  "actions_executed": [{"action_type": "add_to_cart", ...}]
}
```

**Frontend:**

1. ✅ Executes `add_to_cart` action → Adds to local cart
2. ✅ Displays message in chat: "Added 2 Large Pizza to your cart"

### Scenario 2: Search Product (Message Only)

**User:** "search for pizza"

**Backend Response:**

```json
{
    "message": "Found 5 pizzas: Margherita Pizza ($12.99), Pepperoni Pizza ($14.99)...",
    "actions_executed": []
}
```

**Frontend:**

1. ✅ No actions to execute
2. ✅ Displays message in chat: "Found 5 pizzas: Margherita Pizza ($12.99)..."

### Scenario 3: View Cart (Message Only)

**User:** "what's in my cart?"

**Backend Response:**

```json
{
    "message": "Your cart has 3 items: 2x Large Pizza ($31.98), 1x Coke ($2.99). Total: $34.97",
    "actions_executed": []
}
```

**Frontend:**

1. ✅ No actions to execute
2. ✅ Displays message in chat with cart details

## Key Benefits

### ✅ Unified Response Handling

- Both action-based and message-based responses work seamlessly
- AI message is always displayed in chat
- Actions are executed automatically when present

### ✅ No Redundant Validation

- AI validates stock before returning actions
- Frontend skips validation when executing AI actions
- Faster response time, no duplicate API calls

### ✅ Clean User Experience

- AI messages appear in chat (not as snackbars)
- Actions execute silently in background
- Consistent chat interface for all interactions

## Code Components

### 1. AiCommandService

- `processCommand()` - Gets AI response from backend
- `processCommandAndExecute()` - Processes command and executes actions
- Returns `ProcessResult` with success status and AI message

### 2. AiActionExecutor

- Executes cart-related actions locally
- Skips validation (AI already validated)
- No snackbars (messages shown in chat)

### 3. ChatController

- Sends user messages to AI
- Displays AI messages in chat
- Handles both success and error cases

### 4. CartController

- `addToCartFromAI()` - Special function for AI-validated items
- `addToCart(skipValidation: true)` - Skips stock checks
- All cart operations work with AI actions

## Testing

### Test Case 1: Add to Cart

```
Input: "add 2 large pizzas"
Expected: 
- Cart updated with 2 pizzas
- Chat shows: "Added 2 Large Pizza to your cart"
```

### Test Case 2: Search Product

```
Input: "search for pizza"
Expected:
- No cart changes
- Chat shows: "Found 5 pizzas: ..."
```

### Test Case 3: Remove from Cart

```
Input: "remove pizza from cart"
Expected:
- Pizza removed from cart
- Chat shows: "Removed Large Pizza from your cart"
```

## Error Handling

### Backend Error

```dart
// If backend returns error
ProcessResult(
  success: false,
  message: "Product not found"
)
// Chat displays: "Product not found"
```

### Action Execution Error

```dart
// If action fails to execute
ProcessResult(
  success: false,
  message: "Failed to add item to cart"
)
// Chat displays error message
```

## Summary

The system now provides a **unified experience** where:

- **All AI responses** include a message that's displayed in chat
- **Action-based responses** execute actions automatically in the background
- **Message-based responses** just display the message (no actions)
- **No duplicate validation** - AI validates, frontend trusts the data
- **Clean UX** - Everything happens through the chat interface

This architecture supports both simple queries (search, view cart) and complex
operations (add to cart, checkout) with the same clean interface.

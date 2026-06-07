---

## AI Integration Section

### Overview

The AI integration provides voice command processing for cart operations in
kiosk mode. The backend validates stock availability and returns structured
action responses that the frontend can execute locally without persisting to the
database.

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Voice Input (Frontend)                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Speech     │  │   AI         │  │   Action     │      │
│  │ Recognition  │  │   Parser     │  │   Executor   │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼ HTTP/JSON
┌─────────────────────────────────────────────────────────────┐
│                    Rust Backend (Axum)                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   AI         │  │   Command    │  │   Stock      │      │
│  │   Service    │  │   Executor   │  │   Validator  │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼ SQL
                    ┌───────────────┐
                    │   PostgreSQL  │
                    │   (Supabase)  │
                    │  products     │
                    │  variants     │
                    └───────────────┘
```

### Key Principles

1. **No Database Persistence**: AI commands only validate stock, they don't save
   cart data
2. **Frontend Responsibility**: Frontend manages temporary cart state locally
3. **Stock Validation**: Backend validates product availability and pricing
4. **Generic Response Format**: All actions return consistent JSON structure

### API Endpoint

#### Process AI Command

**Endpoint:** `POST /api/ai/command`

**Description:** Processes voice commands and returns validated action responses
for frontend execution.

**Request Body:**

```json
{
  "prompt": "add 2 large pizzas to cart",
  "session_id": "550e8400-e29b-41d4-a716-446655440000",
  "customer_id": null
}
```

**Response Format:**

```json
{
  "success": true,
  "message": "Ready to add 2 Large Pizza to cart",
  "actions_executed": [
    "{\"action_type\":\"add_to_cart\",\"success\":true,\"message\":\"Ready to add 2 Large Pizza to cart\",\"data\":{\"variant_id\":123,\"product_name\":\"Large Pizza\",\"variant_name\":\"Large\",\"quantity\":2,\"available_stock\":50,\"sell_price\":15.99,\"session_id\":\"550e8400-e29b-41d4-a716-446655440000\",\"customer_id\":null},\"error\":null}"
  ],
  "error": null
}
```

### Action Types

#### 1. Add to Cart

**Action Type:** `add_to_cart`

**Validation:**

- Checks product availability
- Validates stock quantity
- Returns product details and pricing

**Response Data:**

```json
{
  "variant_id": 123,
  "product_name": "Large Pizza",
  "variant_name": "Large",
  "quantity": 2,
  "available_stock": 50,
  "sell_price": 15.99,
  "session_id": "session-uuid",
  "customer_id": null
}
```

#### 2. Remove from Cart

**Action Type:** `remove_from_cart`

**Validation:**

- Validates product exists
- Returns product details for removal

#### 3. Update Quantity

**Action Type:** `update_quantity`

**Validation:**

- Checks new quantity against available stock
- Returns updated product details

#### 4. Clear Cart

**Action Type:** `clear_cart`

**Response:** Cart summary with empty items array

#### 5. View Cart

**Action Type:** `view_cart`

**Response:** Cart summary structure for frontend to populate

#### 6. Search Product

**Action Type:** `search_product`

**Response Data:**

```json
{
  "query": "pizza",
  "results": [
    {
      "product_id": 1,
      "product_name": "Large Pizza",
      "variant_id": 0,
      "variant_name": "Default",
      "sell_price": 15.99,
      "stock": 50
    }
  ]
}
```

#### 7. Show Menu

**Action Type:** `show_menu`

**Response Data:**

```json
{
  "category": null,
  "products": [
    {
      "product_id": 1,
      "product_name": "Large Pizza",
      "variant_id": 0,
      "variant_name": "Default",
      "sell_price": 15.99,
      "stock": 50
    }
  ]
}
```

#### 8. Generate Bill

**Action Type:** `generate_bill`

**Response:** Cart summary for bill generation

#### 9. Checkout

**Action Type:** `checkout`

**Response:** Cart summary for checkout process

### Frontend Integration Guide

#### Step 1: Voice Command Processing

```dart
class VoiceCommandProcessor {
  Future<void> processVoiceCommand(String prompt) async {
    try {
      final response = await _apiService.post('/api/ai/command', {
        'prompt': prompt,
        'session_id': _kioskSessionId,
        'customer_id': null,
      });

      if (response['success']) {
        await _executeActions(response['actions_executed']);
      } else {
        _showError(response['message']);
      }
    } catch (e) {
      _showError('Failed to process voice command');
    }
  }
}
```

#### Step 2: Action Execution

```dart
class ActionExecutor {
  Future<void> executeActions(List<String> actionStrings) async {
    for (var actionString in actionStrings) {
      await _executeAction(actionString);
    }
  }

  Future<void> _executeAction(String actionString) async {
    try {
      // Parse the JSON string to get the action object
      final Map<String, dynamic> action = jsonDecode(actionString);
      final actionType = action['action_type'];
      final data = action['data'];

      switch (actionType) {
        case 'add_to_cart':
          await _addToLocalCart(data);
          break;
        case 'remove_from_cart':
          await _removeFromLocalCart(data);
          break;
        case 'update_quantity':
          await _updateLocalCartQuantity(data);
          break;
        case 'clear_cart':
          await _clearLocalCart();
          break;
        case 'view_cart':
          await _showCart();
          break;
        case 'search_product':
          await _showSearchResults(data);
          break;
        case 'show_menu':
          await _showMenu(data);
          break;
        case 'generate_bill':
          await _showBillGeneration();
          break;
        case 'checkout':
          await _initiateCheckout();
          break;
      }
    } catch (e) {
      print('Error parsing action: $e');
    }
  }
}
```

#### Step 3: Local Cart Management

```dart
class LocalCartManager {
  final List<CartItem> _cartItems = [];
  String? _kioskSessionId;

  Future<void> addToLocalCart(Map<String, dynamic> data) async {
    final item = CartItem(
      variantId: data['variant_id'],
      productName: data['product_name'],
      variantName: data['variant_name'],
      quantity: data['quantity'],
      sellPrice: data['sell_price'],
    );

    // Check if item already exists
    final existingIndex = _cartItems.indexWhere(
      (item) => item.variantId == data['variant_id']
    );

    if (existingIndex != -1) {
      // Update existing item
      _cartItems[existingIndex].quantity += data['quantity'];
    } else {
      // Add new item
      _cartItems.add(item);
    }

    _notifyCartUpdated();
  }

  Future<void> removeFromLocalCart(Map<String, dynamic> data) async {
    _cartItems.removeWhere(
      (item) => item.variantId == data['variant_id']
    );
    _notifyCartUpdated();
  }

  Future<void> updateLocalCartQuantity(Map<String, dynamic> data) async {
    final index = _cartItems.indexWhere(
      (item) => item.variantId == data['variant_id']
    );

    if (index != -1) {
      _cartItems[index].quantity = data['quantity'];
      _notifyCartUpdated();
    }
  }

  Future<void> clearLocalCart() async {
    _cartItems.clear();
    _notifyCartUpdated();
  }

  void _notifyCartUpdated() {
    // Notify UI of cart changes
    cartController.updateCart(_cartItems);
  }
}
```

#### Step 4: Error Handling

```dart
class ErrorHandler {
  void handleActionError(String actionString) {
    try {
      final Map<String, dynamic> action = jsonDecode(actionString);
      if (!action['success']) {
        final error = action['error'];
        final message = action['message'];

        switch (error) {
          case 'Insufficient stock':
            _showStockError(message, action['data']);
            break;
          case 'Product not found':
            _showProductNotFound(message);
            break;
          default:
            _showGenericError(message);
        }
      }
    } catch (e) {
      print('Error parsing action for error handling: $e');
    }
  }

  void _showStockError(String message, Map<String, dynamic> data) {
    // Show dialog with available stock and option to adjust quantity
    showDialog(
      context: context,
      builder: (context) => StockErrorDialog(
        message: message,
        availableStock: data['available_stock'],
        requestedQuantity: data['quantity'],
        onAdjustQuantity: (newQuantity) {
          // Update quantity to available stock
          _updateCartQuantity(data['variant_id'], newQuantity);
        },
      ),
    );
  }
}
```

### Example Voice Commands

#### Supported Commands:

1. **Add Items:**
   - "Add 2 large pizzas to cart"
   - "I want 3 burgers"
   - "Add a medium coke"

2. **Remove Items:**
   - "Remove pizza from cart"
   - "Take out the burger"

3. **Update Quantities:**
   - "Change pizza quantity to 1"
   - "Make it 5 burgers instead"

4. **Cart Operations:**
   - "Show my cart"
   - "Clear cart"
   - "What's in my cart?"

5. **Search & Menu:**
   - "Show me the menu"
   - "Search for pizza"
   - "What drinks do you have?"

6. **Checkout:**
   - "Generate bill"
   - "I want to checkout"
   - "Ready to pay"

### Best Practices

#### Frontend Implementation:

1. **Local State Management:**
   - Maintain cart state in memory/local storage
   - Don't rely on backend for cart persistence
   - Sync with backend only for stock validation

2. **Error Handling:**
   - Always check `success` field in action responses
   - Handle stock errors gracefully
   - Provide user-friendly error messages

3. **User Experience:**
   - Show loading states during AI processing
   - Provide immediate feedback for actions
   - Allow manual adjustments for stock conflicts

4. **Performance:**
   - Cache product data locally
   - Batch multiple actions when possible
   - Minimize API calls for repeated operations

#### Backend Considerations:

1. **Stock Validation:**
   - Always validate against current stock levels
   - Consider race conditions in high-traffic scenarios
   - Provide accurate stock information

2. **Response Format:**
   - Maintain consistent JSON structure
   - Include all necessary data for frontend execution
   - Provide clear error messages

3. **Security:**
   - Validate session IDs for kiosk mode
   - Sanitize user inputs
   - Rate limit API endpoints

### Testing

#### Manual Testing Commands:

```bash
# Test add to cart
curl -X POST http://localhost:3000/api/ai/command \
  -H "Content-Type: application/json" \
  -d '{"prompt": "add 2 large pizzas to cart", "session_id": "test-session-123"}'

# Test search
curl -X POST http://localhost:3000/api/ai/command \
  -H "Content-Type: application/json" \
  -d '{"prompt": "search for pizza", "session_id": "test-session-123"}'

# Test insufficient stock
curl -X POST http://localhost:3000/api/ai/command \
  -H "Content-Type: application/json" \
  -d '{"prompt": "add 1000 pizzas to cart", "session_id": "test-session-123"}'
```

#### Expected Responses:

- **Success:** `success: true` with actions_executed as array of JSON strings
- **Stock Error:** Individual action will have `success: false` with stock
  details
- **Parse Error:** Overall response will have `success: false` with error
  message
- **Greeting:** Special handling for hello/hi/hey commands returns greeting
  message

---

# AI Module - Natural Language Processing for Kiosk Backend

## Overview

The AI Module enables natural language processing for the KKS Online Backend
kiosk system. Users can give voice or text commands in English, Urdu, or mixed
languages, and the system will intelligently interpret and execute them using
Google Gemini Pro API.

## Features

- ✅ Natural language understanding (English + Urdu)
- ✅ Multi-action command support
- ✅ Intelligent product search and matching
- ✅ Cart management via voice/text commands
- ✅ Automatic confirmation message generation
- ✅ Error handling and graceful fallbacks
- ✅ Support for both kiosk and authenticated user modes

## Architecture

### Component Structure

```
src/
├── models/ai.rs              # AI models and data structures
├── services/
│   ├── ai_service.rs         # Gemini API communication
│   └── command_executor.rs   # Command execution logic (Queue-based)
└── handlers/ai_handlers.rs   # HTTP endpoint handler
```

### Data Flow (Queue-Based Processing)

```
User Command (Text/Voice)
    ↓
POST /api/ai/command
    ↓
AiService.parse_user_command()
    ↓
Google Gemini Pro API
    ↓
Structured JSON Actions (Multiple Items)
    ↓
CommandExecutor.execute_command() [QUEUE PROCESSING]
    ↓
    ├─→ Process ALL actions in queue
    ├─→ Separate completed vs variant selections
    ├─→ Completed actions → Execute immediately
    └─→ Variant selections → Queue for user choice
    ↓
Check if variant selections exist?
    ↓
    ├─→ YES: Return MultiVariantSelectionData
    │         (Show all variants at once)
    │         Frontend handles selection
    │         
    └─→ NO:  Generate confirmation message
              Return success response
    ↓
JSON Response to Client
```

## API Endpoint

### POST `/api/ai/command`

⚠️ **IMPORTANT:** The full endpoint URL is
`http://your-server:3000/api/ai/command`\
❌ **NOT** `http://your-server:3000/ai/command` (missing `/api`)

Process natural language commands and execute corresponding actions.

**Request Body:**

```json
{
    "prompt": "add 2 zinger burger to cart and bill bana do",
    "session_id": "kiosk-session-123", // Optional: For kiosk mode
    "customer_id": 28 // Optional: For authenticated users
}
```

**Response (Success):**

```json
{
    "success": true,
    "message": "Added 2 Zinger Burgers to your cart and generated the bill. Total: PKR 1200.00",
    "actions_executed": [
        "Added 2 zinger burger to cart",
        "Bill generated: 2 items, Total: PKR 1200.00. Ready for checkout."
    ],
    "error": null
}
```

**Response (Error):**

```json
{
    "success": false,
    "message": "Product 'xyz burger' not found",
    "actions_executed": [],
    "error": "Product 'xyz burger' not found"
}
```

## Queue-Based Multi-Item Processing

### Overview

The AI module now uses a **queue-based processing system** that handles multiple
items intelligently:

1. **All items are processed** even if some require variant selection
2. **Variant selections are collected** and returned together
3. **Frontend displays all variant options** at once for user selection
4. **No items are lost** in the queue

### How It Works

#### Example: "add lux and rice to cart"

**Step 1: AI Parsing**

```json
{
    "actions": [
        { "action": "add_to_cart", "item": "lux", "quantity": 1 },
        { "action": "add_to_cart", "item": "rice", "quantity": 1 }
    ]
}
```

**Step 2: Queue Processing**

- Backend processes BOTH items
- Lux has multiple variants → Added to variant selection queue
- Rice has multiple variants → Added to variant selection queue

**Step 3: Response**

```json
{
    "success": true,
    "message": "Please select variants for 2 item(s): lux, rice",
    "actions_executed": [
        "{
      \"pending_selections\": [
        {
          \"product_name\": \"lux\",
          \"quantity\": 1,
          \"available_variants\": [...]
        },
        {
          \"product_name\": \"rice\",
          \"quantity\": 1,
          \"available_variants\": [...]
        }
      ],
      \"total_items\": 2,
      \"message\": \"Please select variants for 2 item(s): lux, rice\"
    }"
    ]
}
```

### Multi-Variant Selection Response Structure

```typescript
interface MultiVariantSelectionData {
    pending_selections: Array<{
        product_id: number;
        product_name: string;
        quantity: number;
        session_id?: string;
        customer_id?: number;
        available_variants: Array<{
            variant_id: number;
            variant_name: string;
            sell_price: number;
            stock: number;
            attributes?: any;
        }>;
    }>;
    total_items: number;
    message: string;
}
```

## Supported Commands

### 1. Add to Cart

**Examples:**

- "add 2 zinger burger to cart"
- "3 pizza aur 2 coke add karo"
- "burger add kar do"

**Action:**

```json
{
    "action": "add_to_cart",
    "item": "zinger burger",
    "quantity": 2
}
```

### 2. Remove from Cart

**Examples:**

- "remove burger from cart"
- "burger cart se hata do"

**Action:**

```json
{
    "action": "remove_from_cart",
    "item": "burger"
}
```

### 3. Clear Cart

**Examples:**

- "clear cart"
- "cart khali kar do"
- "sab kuch hata do"

**Action:**

```json
{
    "action": "clear_cart"
}
```

### 4. Generate Bill / Checkout

**Examples:**

- "bill bana do"
- "generate bill"
- "checkout kar do"

**Action:**

```json
{
    "action": "generate_bill"
}
```

### 5. Show Menu

**Examples:**

- "show menu"
- "menu dikha do"
- "show burger menu" (category-specific)

**Action:**

```json
{
    "action": "show_menu",
    "category": null
}
```

### 6. Search Product

**Examples:**

- "burger search karo"
- "find pizza"

**Action:**

```json
{
    "action": "search_product",
    "query": "burger"
}
```

### 7. Update Quantity

**Examples:**

- "update burger quantity to 5"
- "burger ki quantity 3 kar do"

**Action:**

```json
{
    "action": "update_quantity",
    "item": "burger",
    "quantity": 3
}
```

### 8. View Cart

**Examples:**

- "show cart"
- "cart dikha do"

**Action:**

```json
{
    "action": "view_cart"
}
```

### 9. Multi-Action Commands

**Example:**

- "add 2 zinger burger to cart and bill bana do"

**Actions:**

```json
{
    "actions": [
        {
            "action": "add_to_cart",
            "item": "zinger burger",
            "quantity": 2
        },
        {
            "action": "generate_bill"
        }
    ]
}
```

## Client-Side Integration

⚠️ **CRITICAL:** Always use the full path `/api/ai/command` in your base URL!

```
✅ CORRECT: http://localhost:3000/api  (then call /ai/command)
❌ WRONG:   http://localhost:3000       (missing /api prefix)
```

### Handling Multi-Variant Selections (Frontend)

When the backend returns a multi-variant selection response, the frontend
should:

1. **Parse the response** from `actions_executed[0]`
2. **Display all variant options** for each product
3. **Allow user to select variants** for all items
4. **Call the appropriate cart endpoints** with selected variant IDs

#### Example Frontend Flow:

```typescript
// Step 1: Send AI command
const response = await fetch("/api/ai/command", {
    method: "POST",
    body: JSON.stringify({
        prompt: "add lux and rice to cart",
        session_id: "kiosk-123",
    }),
});

const data = await response.json();

// Step 2: Check if variant selection is needed
if (data.success && data.actions_executed.length > 0) {
    const actionData = JSON.parse(data.actions_executed[0]);

    if (actionData.pending_selections) {
        // Multi-variant selection needed
        const multiVariant = actionData as MultiVariantSelectionData;

        // Display variant selection UI for ALL items
        multiVariant.pending_selections.forEach((selection) => {
            console.log(`Product: ${selection.product_name}`);
            console.log(`Variants:`, selection.available_variants);

            // Show UI for variant selection
            // User selects variant_id for this product
        });

        // Step 3: After user selects all variants, add to cart
        // Call /api/cart/add for each selected variant
        await Promise.all(
            userSelectedVariants.map((variant) =>
                fetch("/api/cart/add", {
                    method: "POST",
                    body: JSON.stringify({
                        variant_id: variant.variant_id,
                        quantity: variant.quantity,
                        session_id: "kiosk-123",
                    }),
                })
            ),
        );
    }
}
```

### Flutter Example (with Multi-Variant Support)

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class AiCommandService {
  final String baseUrl = 'http://localhost:3000/api';
  
  Future<AiCommandResponse> processCommand({
    required String prompt,
    String? sessionId,
    int? customerId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ai/command'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'prompt': prompt,
        'session_id': sessionId,
        'customer_id': customerId,
      }),
    );
    
    if (response.statusCode == 200) {
      return AiCommandResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to process command');
    }
  }
  
  Future<void> addToCart({
    required int variantId,
    required int quantity,
    String? sessionId,
    int? customerId,
  }) async {
    await http.post(
      Uri.parse('$baseUrl/cart/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'variant_id': variantId,
        'quantity': quantity,
        'session_id': sessionId,
        'customer_id': customerId,
      }),
    );
  }
}

class AiCommandResponse {
  final bool success;
  final String message;
  final List<String> actionsExecuted;
  final String? error;
  
  AiCommandResponse({
    required this.success,
    required this.message,
    required this.actionsExecuted,
    this.error,
  });
  
  factory AiCommandResponse.fromJson(Map<String, dynamic> json) {
    return AiCommandResponse(
      success: json['success'],
      message: json['message'],
      actionsExecuted: List<String>.from(json['actions_executed']),
      error: json['error'],
    );
  }
  
  // Check if this response contains multi-variant selections
  MultiVariantSelectionData? getMultiVariantSelection() {
    if (actionsExecuted.isEmpty) return null;
    
    try {
      final actionData = jsonDecode(actionsExecuted[0]);
      if (actionData['pending_selections'] != null) {
        return MultiVariantSelectionData.fromJson(actionData);
      }
    } catch (e) {
      // Not a variant selection response
    }
    return null;
  }
}

class MultiVariantSelectionData {
  final List<VariantSelection> pendingSelections;
  final int totalItems;
  final String message;
  
  MultiVariantSelectionData({
    required this.pendingSelections,
    required this.totalItems,
    required this.message,
  });
  
  factory MultiVariantSelectionData.fromJson(Map<String, dynamic> json) {
    return MultiVariantSelectionData(
      pendingSelections: (json['pending_selections'] as List)
          .map((item) => VariantSelection.fromJson(item))
          .toList(),
      totalItems: json['total_items'],
      message: json['message'],
    );
  }
}

class VariantSelection {
  final int productId;
  final String productName;
  final int quantity;
  final List<ProductVariant> availableVariants;
  
  VariantSelection({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.availableVariants,
  });
  
  factory VariantSelection.fromJson(Map<String, dynamic> json) {
    return VariantSelection(
      productId: json['product_id'],
      productName: json['product_name'],
      quantity: json['quantity'],
      availableVariants: (json['available_variants'] as List)
          .map((item) => ProductVariant.fromJson(item))
          .toList(),
    );
  }
}

class ProductVariant {
  final int variantId;
  final String variantName;
  final double sellPrice;
  final int stock;
  
  ProductVariant({
    required this.variantId,
    required this.variantName,
    required this.sellPrice,
    required this.stock,
  });
  
  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      variantId: json['variant_id'],
      variantName: json['variant_name'],
      sellPrice: (json['sell_price'] as num).toDouble(),
      stock: json['stock'],
    );
  }
}

// Usage Example with Multi-Variant Handling
void main() async {
  final service = AiCommandService();
  
  try {
    // Step 1: Send AI command
    final response = await service.processCommand(
      prompt: 'add lux and rice to cart',
      sessionId: 'kiosk-session-123',
    );
    
    if (response.success) {
      // Step 2: Check for multi-variant selection
      final multiVariant = response.getMultiVariantSelection();
      
      if (multiVariant != null) {
        print('🔄 Variant selection needed for ${multiVariant.totalItems} items');
        
        // Step 3: Display variant options to user
        for (var selection in multiVariant.pendingSelections) {
          print('\nProduct: ${selection.productName}');
          print('Variants:');
          for (var variant in selection.availableVariants) {
            print('  - ${variant.variantName}: PKR ${variant.sellPrice}');
          }
          
          // In real app, show UI for user to select variant
          // For example, user selects first variant:
          final selectedVariant = selection.availableVariants.first;
          
          // Step 4: Add selected variant to cart
          await service.addToCart(
            variantId: selectedVariant.variantId,
            quantity: selection.quantity,
            sessionId: 'kiosk-session-123',
          );
        }
        
        print('✅ All items added to cart!');
      } else {
        // No variant selection needed
        print('✅ ${response.message}');
      }
    } else {
      print('❌ Error: ${response.error}');
    }
  } catch (e) {
    print('Failed to process command: $e');
  }
}
```

### JavaScript/TypeScript Example

```typescript
interface AiCommandRequest {
    prompt: string;
    session_id?: string;
    customer_id?: number;
}

interface AiCommandResponse {
    success: boolean;
    message: string;
    actions_executed: string[];
    error?: string;
}

class AiCommandService {
    private baseUrl = "http://localhost:3000/api";

    async processCommand(
        request: AiCommandRequest,
    ): Promise<AiCommandResponse> {
        const response = await fetch(`${this.baseUrl}/ai/command`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
            },
            body: JSON.stringify(request),
        });

        if (!response.ok) {
            throw new Error("Failed to process command");
        }

        return await response.json();
    }
}

// Usage Example
const service = new AiCommandService();

service.processCommand({
    prompt: "add 2 zinger burger to cart and bill bana do",
    session_id: "kiosk-session-123",
})
    .then((response) => {
        if (response.success) {
            console.log("✅", response.message);
            console.log("Actions:", response.actions_executed);
        } else {
            console.error("❌", response.error);
        }
    })
    .catch((error) => {
        console.error("Failed to process command:", error);
    });
```

### React Hook Example

```typescript
import { useState } from "react";

function useAiCommand() {
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);

    const processCommand = async (
        prompt: string,
        sessionId?: string,
        customerId?: number,
    ) => {
        setLoading(true);
        setError(null);

        try {
            const response = await fetch(
                "http://localhost:3000/api/ai/command",
                {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify({
                        prompt,
                        session_id: sessionId,
                        customer_id: customerId,
                    }),
                },
            );

            const data = await response.json();

            if (!data.success) {
                setError(data.error || "Command failed");
            }

            return data;
        } catch (err) {
            setError("Network error");
            throw err;
        } finally {
            setLoading(false);
        }
    };

    return { processCommand, loading, error };
}

// Usage in Component
function VoiceCommandButton() {
    const { processCommand, loading, error } = useAiCommand();

    const handleCommand = async (voiceInput: string) => {
        const result = await processCommand(voiceInput, "kiosk-123");
        if (result.success) {
            alert(result.message);
        }
    };

    return (
        <button
            onClick={() => handleCommand("add 2 burger")}
            disabled={loading}
        >
            {loading ? "Processing..." : "Voice Command"}
        </button>
    );
}
```

## Configuration

### Environment Variables

Add to your `.env` file:

```bash
# Required: Google Gemini Pro API Key
GEMINI_API_KEY=your-api-key-here

# Existing configuration
DATABASE_URL=your-database-url
PORT=3000
HOST=0.0.0.0
```

### Getting Gemini API Key

1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with your Google account
3. Click "Get API Key"
4. Create a new API key or use existing one
5. Copy the key and add to `.env` file

## Error Handling

The AI module handles various error scenarios:

### 1. Product Not Found

```json
{
    "success": false,
    "message": "Product 'xyz burger' not found",
    "actions_executed": [],
    "error": "Product 'xyz burger' not found"
}
```

### 2. Insufficient Stock

```json
{
    "success": false,
    "message": "Insufficient stock for burger (only 3 available)",
    "actions_executed": [],
    "error": "Insufficient stock for burger (only 3 available)"
}
```

### 3. Empty Cart

```json
{
    "success": false,
    "message": "Cart is empty. Add items first.",
    "actions_executed": [],
    "error": "Cart is empty. Add items first."
}
```

### 4. API Failure

```json
{
    "success": false,
    "message": "Sorry, I couldn't understand that command.",
    "actions_executed": [],
    "error": "Failed to call Gemini API: connection timeout"
}
```

## Urdu Language Support

The AI module understands common Urdu commands:

| Urdu Word         | English Meaning | Usage                       |
| ----------------- | --------------- | --------------------------- |
| karo / kar do     | do it           | "add karo", "remove kar do" |
| bana do / banao   | make/generate   | "bill bana do"              |
| dikha do / dikhao | show            | "menu dikha do"             |
| hata do / hatao   | remove          | "cart se hata do"           |
| aur               | and             | "2 burger aur 3 pizza"      |
| se                | from            | "cart se remove"            |
| khali kar do      | empty/clear     | "cart khali kar do"         |

## Testing

### Using cURL

```bash
# Add to cart
curl -X POST http://localhost:3000/api/ai/command \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "add 2 zinger burger to cart",
    "session_id": "test-session-123"
  }'

# Multiple actions
curl -X POST http://localhost:3000/api/ai/command \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "3 pizza aur 2 coke add karo aur bill bana do",
    "session_id": "test-session-123"
  }'

# View cart
curl -X POST http://localhost:3000/api/ai/command \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "cart dikha do",
    "session_id": "test-session-123"
  }'
```

### Using Postman

1. Create a new POST request to `http://localhost:3000/api/ai/command`
2. Set Headers: `Content-Type: application/json`
3. Set Body (raw JSON):

```json
{
    "prompt": "add 2 zinger burger to cart and bill bana do",
    "session_id": "kiosk-session-123"
}
```

4. Click Send

## Best Practices

### 1. Session Management

**Kiosk Mode:**

- Use unique `session_id` for each kiosk session
- Generate session ID when kiosk starts: `kiosk-${Date.now()}-${random}`

**Authenticated Mode:**

- Use `customer_id` for logged-in users
- Don't send `session_id` when using `customer_id`

### 2. Error Handling

```typescript
try {
    const response = await processCommand(prompt, sessionId);

    if (response.success) {
        // Show success message
        showNotification(response.message, "success");
    } else {
        // Show error message
        showNotification(response.error, "error");
    }
} catch (error) {
    // Handle network errors
    showNotification("Network error. Please try again.", "error");
}
```

### 3. User Feedback

- Show loading indicator while processing
- Display confirmation message from AI
- Refresh cart UI after successful actions
- Provide voice feedback in kiosk mode

### 4. Rate Limiting

The Gemini API has rate limits. Implement client-side throttling:

```typescript
let lastCommandTime = 0;
const MIN_COMMAND_INTERVAL = 1000; // 1 second

async function processCommandWithThrottle(prompt: string) {
    const now = Date.now();
    if (now - lastCommandTime < MIN_COMMAND_INTERVAL) {
        throw new Error("Please wait before sending another command");
    }
    lastCommandTime = now;
    return await processCommand(prompt);
}
```

## Extending the AI Module

### Adding New Actions

1. **Add action to `src/models/ai.rs`:**

```rust
#[derive(Debug, Deserialize, Serialize, Clone)]
#[serde(tag = "action", rename_all = "snake_case")]
pub enum Action {
    // ... existing actions
    ApplyCoupon {
        code: String,
    },
}
```

2. **Update system prompt in `src/services/ai_service.rs`:**

```rust
"9. apply_coupon - Apply discount coupon"
```

3. **Add parsing logic in `parse_gemini_response()`:**

```rust
"apply_coupon" => {
    let code = action_value
        .get("code")
        .and_then(|v| v.as_str())
        .unwrap_or("")
        .to_string();
    Action::ApplyCoupon { code }
}
```

4. **Implement execution in `src/services/command_executor.rs`:**

```rust
Action::ApplyCoupon { code } => {
    self.apply_coupon(&code, session_id, customer_id).await
}
```

## Performance Considerations

- **Gemini API latency:** ~1-3 seconds per request
- **Caching:** Consider caching product searches
- **Fallback:** Provide quick-action buttons for common commands
- **Offline:** Show "AI unavailable" message if API fails

## Security

- API key is server-side only (never exposed to client)
- All database operations use existing security measures
- Input validation on both client and server
- Rate limiting recommended for production

## Troubleshooting

### ⚠️ Issue: 404 Error - "Failed to parse response: FormatException: Unexpected end of input"

**Symptoms:**

- Client receives 404 error
- Flutter/Dart shows:
  `FormatException: Unexpected end of input (at character 1)`
- Backend logs show: `status=404`

**Cause:** Incorrect endpoint URL - missing `/api` prefix

**Solution:**

✅ **CORRECT URL:** `http://localhost:3000/api/ai/command`

❌ **WRONG URL:** `http://localhost:3000/ai/command` (missing `/api`)

**Flutter Fix:**

```dart
class AiCommandService {
  // CORRECT ✅
  final String baseUrl = 'http://localhost:3000/api';
  
  // WRONG ❌
  // final String baseUrl = 'http://localhost:3000';
  
  Future<AiCommandResponse> processCommand({
    required String prompt,
    String? sessionId,
    int? customerId,
  }) async {
    // This will correctly call /api/ai/command ✅
    final response = await http.post(
      Uri.parse('$baseUrl/ai/command'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'prompt': prompt,
        'session_id': sessionId,
        'customer_id': customerId,
      }),
    );
    
    if (response.statusCode == 200) {
      return AiCommandResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to process command: ${response.statusCode}');
    }
  }
}
```

**JavaScript/TypeScript Fix:**

```typescript
class AiCommandService {
    // CORRECT ✅
    private baseUrl = "http://localhost:3000/api";

    // WRONG ❌
    // private baseUrl = "http://localhost:3000";

    async processCommand(
        request: AiCommandRequest,
    ): Promise<AiCommandResponse> {
        // This will correctly call /api/ai/command ✅
        const response = await fetch(`${this.baseUrl}/ai/command`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(request),
        });

        if (!response.ok) {
            throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }

        return await response.json();
    }
}
```

**Quick Test:**

```bash
# Test the correct endpoint ✅
curl -X POST http://localhost:3000/api/ai/command \
  -H "Content-Type: application/json" \
  -d '{"prompt": "show menu", "session_id": "test-123"}'

# This will return 404 ❌
curl -X POST http://localhost:3000/ai/command \
  -H "Content-Type: application/json" \
  -d '{"prompt": "show menu", "session_id": "test-123"}'
```

---

### Issue: "GEMINI_API_KEY must be set"

**Solution:** Add `GEMINI_API_KEY` to your `.env` file

### Issue: "Failed to parse command"

**Solution:**

- Check Gemini API key is valid
- Verify internet connection
- Check API quota limits

### Issue: "Product not found"

**Solution:**

- Use exact or similar product names from your database
- Improve product search logic
- Add product aliases/synonyms

### Issue: Commands in Urdu not working

**Solution:**

- Ensure UTF-8 encoding in HTTP requests
- Use proper Urdu transliteration
- Common words should work: "karo", "bana do", etc.

## Queue-Based System Summary

### Backend Changes (✅ Implemented)

1. **CommandExecutor** now uses queue-based processing
2. **All actions are processed** before returning response
3. **Variant selections are collected** and returned together
4. **New model**: `MultiVariantSelectionData` for multi-variant responses
5. **CommandResult** includes `pending_variant_selections` field

### Frontend Requirements (⚠️ Action Required)

To support the new queue-based multi-variant system, the frontend needs to:

#### 1. **Parse Multi-Variant Responses**

```typescript
// Check if response contains variant selections
const actionData = JSON.parse(response.actions_executed[0]);
if (actionData.pending_selections) {
    // Handle multi-variant selection
    const multiVariant = actionData as MultiVariantSelectionData;
}
```

#### 2. **Display All Variant Options**

Show variant selection UI for **ALL** items that require selection, not just the
first one.

```typescript
multiVariant.pending_selections.forEach((selection) => {
    // Display UI for this product's variants
    showVariantSelectionUI(selection);
});
```

#### 3. **Collect User Selections**

Allow user to select variants for **ALL** products before proceeding.

#### 4. **Add All Items to Cart**

After user selects all variants, call the cart API for each item:

```typescript
await Promise.all(
    selectedVariants.map((variant) =>
        addToCart(variant.variant_id, variant.quantity, session_id)
    ),
);
```

### Key Differences from Previous System

| **Previous System**                        | **New Queue-Based System**              |
| ------------------------------------------ | --------------------------------------- |
| Stops at first variant selection           | Processes ALL items in queue            |
| Returns single variant selection           | Returns ALL variant selections together |
| Items get lost if variant selection needed | NO items are lost                       |
| Frontend shows one product at a time       | Frontend shows ALL products at once     |

### Testing the Queue System

#### Test Case 1: Multiple Items with Variants

```bash
curl -X POST http://localhost:3000/api/ai/command \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "add lux and rice to cart",
    "session_id": "test-session-123"
  }'
```

**Expected Response:**

```json
{
    "success": true,
    "message": "Please select variants for 2 item(s): lux, rice",
    "actions_executed": [
        "{\"pending_selections\":[{\"product_name\":\"lux\",\"available_variants\":[...]},{\"product_name\":\"rice\",\"available_variants\":[...]}],\"total_items\":2}"
    ]
}
```

#### Test Case 2: Mixed Items (Some with/without variants)

```bash
curl -X POST http://localhost:3000/api/ai/command \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "add lux and show menu",
    "session_id": "test-session-123"
  }'
```

**Expected:** Lux variants returned, menu displayed separately

## Future Enhancements

- [ ] Voice input integration (Speech-to-Text)
- [ ] Multi-language support (Arabic, Persian, etc.)
- [ ] Context-aware conversations
- [ ] Product recommendations based on past orders
- [ ] Fuzzy product matching improvements
- [ ] Offline mode with cached responses
- [ ] Analytics dashboard for AI usage
- [x] ✅ Queue-based multi-item processing
- [x] ✅ Multi-variant selection support

## Support

For issues or questions:

1. Check this documentation
2. Review example code
3. Test with cURL/Postman
4. Check server logs for detailed errors
5. Test queue-based multi-variant flows

## License

Part of KKS Online Backend - See main README for license information.

---

**Last Updated:** October 2025 **Version:** 2.0.0 (Queue-Based System)

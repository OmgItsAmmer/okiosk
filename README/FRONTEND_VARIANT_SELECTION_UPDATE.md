# Frontend Multi-Variant Selection Solution

## ⚠️ **NEW SEQUENTIAL ORCHESTRATION MODEL**

The backend has been **redesigned** to use a **Sequential Queue Orchestration**
approach instead of parallel multi-variant selection.

### What Changed?

**OLD APPROACH** (Parallel - Deprecated):

- Backend returns ALL product variants at once
- Frontend must handle multiple products simultaneously
- Complex state management

**NEW APPROACH** (Sequential - Active):

- Backend sends ONE product at a time
- Frontend confirms each product before getting the next
- Simple, predictable flow

---

## Complete Flow Overview

### The Sequential Queue System

```
User: "Add lux and rice to cart"
         ↓
POST /api/ai/command
         ↓
Backend detects 2 products
         ↓
Backend queues: ["Lux", "Rice"]
         ↓
Backend returns: ONLY "Lux" (with queue_info)
         ↓
Frontend: Shows Lux variants
         ↓
User: Selects Lux variant
         ↓
POST /api/ai/variant-confirm (with variant_id)
         ↓
Backend: Adds Lux to cart
Backend: Pops "Rice" from queue
         ↓
Backend returns: "Rice" variants
         ↓
Frontend: Shows Rice variants
         ↓
User: Selects Rice variant
         ↓
POST /api/ai/variant-confirm (with variant_id)
         ↓
Backend: Adds Rice to cart
Backend: Queue empty
         ↓
Backend returns: "All done!" message
         ↓
Frontend: Shows success message
```

---

## How It Works Now

### Example: "Add lux and rice to cart"

**Step 1**: User sends command

```
POST /api/ai/command
{ "prompt": "add lux and rice to cart", "session_id": "kiosk-123" }
```

**Step 2**: Backend returns FIRST product only (Lux)

```json
{
  "success": true,
  "message": "Please select variant for Lux (1 of 2 items)",
  "actions_executed": [
    "{
      \"action_type\": \"variant_selection\",
      \"data\": {
        \"product_name\": \"Lux\",
        \"available_variants\": [...],
        \"queue_info\": {
          \"position\": 1,
          \"total\": 2,
          \"remaining\": [\"Rice\"]
        }
      }
    }"
  ]
}
```

**Step 3**: Frontend shows Lux variants, user selects

**Step 4**: Frontend sends confirmation

```
POST /api/ai/variant-confirm
{
  "action": "variant_selection",
  "status": "success",
  "product_name": "Lux",
  "variant_id": 456,
  "session_id": "kiosk-123"
}
```

**Step 5**: Backend returns NEXT product (Rice)

```json
{
  "success": true,
  "message": "Lux added! Now select variant for Rice (2 of 2 items)",
  "has_more": true,
  "next_action": {
    "action_type": "variant_selection",
    "data": {
      "product_name": "Rice",
      "available_variants": [...]
    }
  }
}
```

**Step 6**: User selects Rice variant → Frontend confirms → Done!

---

## 🔑 Response Parsing Guide (CRITICAL)

### How to Detect Response Type

The backend will ALWAYS send `action_type: "variant_selection"` for both single
and multi-item scenarios. The **ONLY** way to distinguish them is by checking
for `queue_info`:

```dart
final actionData = jsonDecode(response.actionsExecuted[0]);

if (actionData['action_type'] == 'variant_selection') {
  final data = actionData['data'];
  
  // ✅ CORRECT: Check for queue_info
  if (data['queue_info'] != null) {
    // Multi-item sequential flow
    int position = data['queue_info']['position'];
    int total = data['queue_info']['total'];
    List<String> remaining = data['queue_info']['remaining'];
    
    handleSequentialVariantSelection(actionData);
  } else {
    // Single item flow
    handleSingleVariantSelection(actionData);
  }
}
```

### Response Structure Comparison

**Single Item Response** (NO queue_info):

```json
{
  "action_type": "variant_selection",
  "data": {
    "product_name": "Lux",
    "quantity": 1,
    "available_variants": [...]
    // ❌ NO queue_info field
  }
}
```

**Multi-Item Response** (HAS queue_info):

```json
{
  "action_type": "variant_selection",
  "data": {
    "product_name": "Lux",
    "quantity": 1,
    "available_variants": [...],
    "queue_info": {  // ✅ queue_info exists!
      "position": 1,
      "total": 2,
      "remaining": ["Rice"]
    }
  }
}
```

### After Confirmation Response

When you call `POST /api/ai/variant-confirm`, the response structure depends on
whether there are more items:

**More Items in Queue**:

```json
{
  "success": true,
  "message": "Lux added! Now select variant for Rice (2 of 2 items)",
  "actions_executed": [
    "{\"action_type\":\"variant_selection\",\"data\":{...}}"
  ]
}
```

**Queue Complete**:

```json
{
  "success": true,
  "message": "All items added to cart successfully!",
  "actions_executed": ["queue_completed"]
}
```

**User Cancelled**:

```json
{
  "success": false,
  "message": "Action cancelled. Queue cleared.",
  "error": "User cancelled"
}
```

---

## Frontend Implementation

### Step 1: Detect Sequential vs Single Variant

```dart
void handleAiResponse(AiCommandResponse response) {
  if (response.success && response.actionsExecuted.isNotEmpty) {
    try {
      final actionData = jsonDecode(response.actionsExecuted[0]);
      
      // Check if it's a variant selection
      if (actionData['action_type'] == 'variant_selection') {
        final data = actionData['data'];
        
        // Check if it's sequential (has queue_info)
        if (data['queue_info'] != null) {
          // Sequential multi-item variant selection
          handleSequentialVariantSelection(actionData);
        } else {
          // Single item variant selection (existing logic)
          handleSingleVariantSelection(actionData);
        }
      } else {
        // Standard success response
        handleStandardResponse(response);
      }
    } catch (e) {
      handleError('Failed to parse AI response: $e');
    }
  } else if (!response.success) {
    handleError(response.message);
  }
}
```

### Step 2: Handle Sequential Variant Selection

```dart
void handleSequentialVariantSelection(Map<String, dynamic> actionData) {
  try {
    final data = actionData['data'];
    final queueInfo = data['queue_info'];
    
    print('Sequential variant selection: ${queueInfo['position']} of ${queueInfo['total']}');
    
    // Show variant selection UI with queue progress
    showSequentialVariantDialog(
      productName: data['product_name'],
      quantity: data['quantity'],
      variants: (data['available_variants'] as List)
          .map((v) => ProductVariant.fromJson(v))
          .toList(),
      queueInfo: QueueInfo(
        position: queueInfo['position'],
        total: queueInfo['total'],
        remaining: List<String>.from(queueInfo['remaining']),
      ),
      onVariantSelected: (variantId) async {
        // Send confirmation to backend
        await confirmVariantSelection(
          productName: data['product_name'],
          variantId: variantId,
          sessionId: currentSessionId,
        );
      },
      onCancel: () async {
        // User cancelled - notify backend
        await cancelVariantSelection(currentSessionId);
      },
    );
  } catch (e) {
    print('Error handling sequential variant: $e');
    handleError('Failed to parse variant selection data');
  }
}
```

### Step 3: Create Sequential Variant Selection UI

```dart
void showSequentialVariantDialog({
  required String productName,
  required int quantity,
  required List<ProductVariant> variants,
  required QueueInfo queueInfo,
  required Function(int) onVariantSelected,
  required Function() onCancel,
}) {
  ProductVariant? selectedVariant;
  
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select Variant'),
                SizedBox(height: 4),
                // Queue progress indicator
                Text(
                  'Item ${queueInfo.position} of ${queueInfo.total}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: Colors.grey[600],
                  ),
                ),
                // Progress bar
                SizedBox(height: 8),
                LinearProgressIndicator(
                  value: queueInfo.position / queueInfo.total,
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text('Quantity: $quantity'),
                  SizedBox(height: 16),
                  Text(
                    'Select a variant:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 12),
                  // Show variant options
                  ...variants.map((variant) {
                    return RadioListTile<ProductVariant>(
                      title: Text(variant.variantName),
                      subtitle: Text(
                        'PKR ${variant.sellPrice} - Stock: ${variant.stock}',
                      ),
                      value: variant,
                      groupValue: selectedVariant,
                      onChanged: (ProductVariant? value) {
                        setState(() {
                          selectedVariant = value;
                        });
                      },
                    );
                  }).toList(),
                  // Show remaining items
                  if (queueInfo.remaining.isNotEmpty) ...[
                    SizedBox(height: 16),
                    Text(
                      'Next: ${queueInfo.remaining.join(", ")}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onCancel();
                },
                child: Text('Cancel All'),
              ),
              ElevatedButton(
                onPressed: selectedVariant != null
                    ? () {
                        Navigator.of(context).pop();
                        onVariantSelected(selectedVariant!.variantId);
                      }
                    : null,
                child: Text(queueInfo.position < queueInfo.total ? 'Next' : 'Add to Cart'),
              ),
            ],
          );
        },
      );
    },
  );
}
```

### Step 4: Send Confirmation to Backend

**This is the KEY part - send confirmation and handle next product!**

```dart
Future<void> confirmVariantSelection({
  required String productName,
  required int variantId,
  required String sessionId,
}) async {
  try {
    // Show loading
    showLoadingDialog('Adding $productName to cart...');
    
    // Send confirmation to backend
    final response = await http.post(
      Uri.parse('$baseUrl/ai/variant-confirm'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'action': 'variant_selection',
        'status': 'success',
        'product_name': productName,
        'variant_id': variantId,
        'session_id': sessionId,
      }),
    );
    
    hideLoadingDialog();
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // Check if there's more items in queue
      if (data['has_more'] == true) {
        // Show next product's variant selection
        final nextAction = data['next_action'];
        handleSequentialVariantSelection(nextAction);
      } else {
        // All done!
        showSuccessMessage(data['message'] ?? 'All items added to cart!');
        refreshCartUI();
      }
    } else {
      showErrorMessage('Failed to confirm variant selection');
    }
  } catch (e) {
    hideLoadingDialog();
    showErrorMessage('Network error: $e');
  }
}

Future<void> cancelVariantSelection(String sessionId) async {
  try {
    await http.post(
      Uri.parse('$baseUrl/ai/variant-confirm'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'action': 'variant_selection',
        'status': 'cancel',
        'product_name': '',
        'session_id': sessionId,
      }),
    );
    
    showMessage('Action cancelled');
  } catch (e) {
    showErrorMessage('Failed to cancel: $e');
  }
}
```

### Step 5: Add Required Data Models

```dart
class QueueInfo {
  final int position;
  final int total;
  final List<String> remaining;
  
  QueueInfo({
    required this.position,
    required this.total,
    required this.remaining,
  });
  
  factory QueueInfo.fromJson(Map<String, dynamic> json) {
    return QueueInfo(
      position: json['position'],
      total: json['total'],
      remaining: List<String>.from(json['remaining']),
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

class SelectedVariant {
  final int variantId;
  final int quantity;
  
  SelectedVariant({
    required this.variantId,
    required this.quantity,
  });
}
```

## Complete Implementation Example

Here's a complete working example:

```dart
class AiCommandService {
  Future<void> processAiCommand(String prompt, String sessionId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ai/command'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'prompt': prompt,
          'session_id': sessionId,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponse = AiCommandResponse.fromJson(data);
        
        // Handle the response
        handleAiResponse(aiResponse);
      } else {
        handleError('Failed to process command: ${response.statusCode}');
      }
    } catch (e) {
      handleError('Network error: $e');
    }
  }
  
  void handleAiResponse(AiCommandResponse response) {
    if (response.success && response.actionsExecuted.isNotEmpty) {
      try {
        final actionData = jsonDecode(response.actionsExecuted[0]);
        
        // Check if it's a variant selection
        if (actionData['action_type'] == 'variant_selection') {
          final data = actionData['data'];
          
          // IMPORTANT: Check for queue_info to detect sequential orchestration
          if (data['queue_info'] != null) {
            // Sequential multi-item variant selection (NEW FLOW)
            handleSequentialVariantSelection(actionData);
          } else {
            // Single item variant selection (EXISTING FLOW)
            handleSingleVariantSelection(actionData);
          }
        } else {
          // Standard success response (show menu, search results, etc.)
          handleStandardResponse(response);
        }
      } catch (e) {
        handleError('Failed to parse AI response: $e');
      }
    } else if (!response.success) {
      handleError(response.message);
    }
  }
}
```

## Testing

### Test Cases:

1. **Single Item**: "add lux to cart" → Should show single variant dialog
2. **Multiple Items**: "add lux and rice to cart" → Should show multi-variant
   dialog
3. **No Variants**: "add cola to cart" → Should add directly to cart

### Expected Behavior:

- ✅ Single items work with existing logic
- ✅ Multiple items show all variants in one dialog
- ✅ User can select variants for all items at once
- ✅ All items are added to cart after selection

---

## Summary of Changes Required

### What Changed in Backend:

1. ✅ **Sequential Queue System**: Products processed one at a time
2. ✅ **Queue Service**: Manages pending products per user/session
3. ✅ **New Endpoint**: `/api/ai/variant-confirm` for confirmations
4. ✅ **Queue Info**: Response includes position, total, remaining items

### What Frontend Must Implement:

#### 1. **Detection Logic**

```dart
if (data['queue_info'] != null) {
  // Sequential multi-item
  handleSequentialVariantSelection(actionData);
} else {
  // Single item (existing)
  handleSingleVariantSelection(actionData);
}
```

#### 2. **Sequential Variant Dialog**

- Show ONE product at a time
- Display queue progress (1 of 2, 2 of 2)
- Show progress bar
- Show remaining items preview
- "Next" button (or "Add to Cart" for last item)
- "Cancel All" button

#### 3. **Confirmation API Call**

```dart
POST /api/ai/variant-confirm
{
  "action": "variant_selection",
  "status": "success",
  "product_name": "Lux",
  "variant_id": 456,
  "session_id": "kiosk-123"
}
```

#### 4. **Handle Next Product**

```dart
if (response['has_more'] == true) {
  // Show next product
  showVariantDialog(response['next_action']['data']);
} else {
  // All done!
  showSuccess('All items added!');
}
```

#### 5. **Cancellation Handling**

```dart
// User clicks "Cancel All"
POST /api/ai/variant-confirm with status: "cancel"
// Backend clears entire queue
```

---

## Benefits of New Approach

| Feature                 | Old Parallel             | New Sequential            |
| ----------------------- | ------------------------ | ------------------------- |
| **User sees**           | All products at once     | One product at a time     |
| **Frontend complexity** | High (multi-state)       | Low (single-state)        |
| **Error handling**      | Complex partial failures | Simple per-product errors |
| **User experience**     | Overwhelming             | Clean and clear           |
| **State reliability**   | Inconsistent             | Predictable               |
| **Backend load**        | All at once              | Distributed               |
| **Progress tracking**   | Unclear                  | Clear (1 of 2)            |

---

## Testing Checklist

- [ ] Single item: "add lux to cart" → Works with existing logic
- [ ] Two items: "add lux and rice to cart" → Shows sequential dialogs
- [ ] Three items: "add lux, rice and soap to cart" → Shows 3 sequential dialogs
- [ ] Cancellation: User clicks "Cancel All" → Queue cleared
- [ ] Completion: All items confirmed → Success message
- [ ] Progress UI: Shows "1 of 2", "2 of 2", etc.
- [ ] Remaining preview: Shows next items ("Next: Rice")

---

## Migration Steps

1. **Update Detection Logic** (15 min)
   - Add `queue_info` check
   - Route to sequential handler

2. **Create Sequential UI** (1 hour)
   - Build dialog with progress indicators
   - Add cancel button
   - Show remaining items

3. **Implement Confirmation API** (30 min)
   - Create `/api/ai/variant-confirm` call
   - Handle `has_more` response
   - Show next product or complete

4. **Add Models** (15 min)
   - Create `QueueInfo` class

5. **Test** (1 hour)
   - Test all scenarios
   - Fix bugs

**Total Estimated Time**: ~3 hours

---

## Result

After implementing these changes, when user says:

**"Add lux and rice to cart"**

**User sees:**

1. Dialog: "Select variant for Lux (1 of 2)" → User selects
2. Dialog: "Select variant for Rice (2 of 2)" → User selects
3. Success: "All items added to cart!"

**Clean, simple, predictable.** ✨

---

**For complete backend architecture details, see**
`SEQUENTIAL_QUEUE_ARCHITECTURE.md`

# Queue-Based AI Command Processing - Implementation Summary

## Overview

Successfully implemented a **queue-based processing system** for the AI module
that handles multiple items intelligently, ensuring no items are lost when
variant selection is required.

## Problem Statement

### Previous System Issue:

When a user said "add lux and rice to cart":

- ❌ Backend would process "lux" first
- ❌ If lux had multiple variants, it would stop processing
- ❌ "rice" would never be processed
- ❌ User only saw lux variants, rice was lost

### New Queue-Based System:

When a user says "add lux and rice to cart":

- ✅ Backend processes **BOTH** lux and rice
- ✅ Collects variant selections for **ALL** items
- ✅ Returns **ALL** variant options together
- ✅ **NO items are lost** in the queue

---

## Backend Changes Implemented

### 1. **Updated Models** (`src/models/ai.rs`)

#### Added `pending_variant_selections` to `CommandResult`:

```rust
pub struct CommandResult {
    pub success: bool,
    pub message: String,
    pub actions_executed: Vec<String>,
    pub pending_variant_selections: Vec<ActionResponse>, // NEW
}
```

#### Added `MultiVariantSelectionData` model:

```rust
pub struct MultiVariantSelectionData {
    pub pending_selections: Vec<VariantSelectionActionData>,
    pub total_items: i32,
    pub message: String,
}
```

### 2. **Updated Command Executor** (`src/services/command_executor.rs`)

#### Queue-Based Processing Logic:

```rust
pub async fn execute_command(...) -> CommandResult {
    let mut completed_actions: Vec<String> = Vec::new();
    let mut variant_selections: Vec<ActionResponse> = Vec::new();

    // Process ALL actions in the queue
    for action in command.actions {
        match self.execute_action(action, session_id, customer_id).await {
            Ok(action_response_json) => {
                let action_response: ActionResponse = serde_json::from_str(&action_response_json)?;
                
                // Separate variant selections from completed actions
                if action_response.action_type == Some("variant_selection".to_string()) {
                    variant_selections.push(action_response);
                } else {
                    completed_actions.push(action_response_json);
                }
            }
            Err(e) => { /* handle error */ }
        }
    }

    // Return variant selections if any exist
    if !variant_selections.is_empty() {
        result.pending_variant_selections = variant_selections;
        result.message = format!(
            "{} action(s) completed. {} item(s) require variant selection.",
            completed_actions.len(),
            result.pending_variant_selections.len()
        );
    }
    
    result
}
```

### 3. **Updated AI Handlers** (`src/handlers/ai_handlers.rs`)

#### Multi-Variant Response Handling:

```rust
// Check if there are pending variant selections
if !result.pending_variant_selections.is_empty() {
    let mut pending_selections: Vec<VariantSelectionActionData> = Vec::new();
    
    for variant_response in &result.pending_variant_selections {
        if let Some(data) = &variant_response.data {
            if let Ok(selection_data) = serde_json::from_value::<VariantSelectionActionData>(data.clone()) {
                pending_selections.push(selection_data);
            }
        }
    }

    let multi_selection = MultiVariantSelectionData {
        pending_selections: pending_selections.clone(),
        total_items: pending_selections.len() as i32,
        message: format!("Please select variants for {} item(s): {}", ...),
    };

    return Ok(Json(AiCommandResponse {
        success: true,
        message: multi_selection.message.clone(),
        actions_executed: vec![serde_json::to_string(&multi_selection)?],
        error: None,
    }));
}
```

---

## API Response Structure

### Multi-Variant Selection Response

When multiple items require variant selection:

```json
{
    "success": true,
    "message": "Please select variants for 2 item(s): lux, rice",
    "actions_executed": [
        "{
      \"pending_selections\": [
        {
          \"product_id\": 123,
          \"product_name\": \"lux\",
          \"quantity\": 1,
          \"session_id\": \"kiosk-123\",
          \"customer_id\": null,
          \"available_variants\": [
            {
              \"variant_id\": 456,
              \"variant_name\": \"100g\",
              \"sell_price\": 50.0,
              \"stock\": 100,
              \"attributes\": null
            },
            {
              \"variant_id\": 457,
              \"variant_name\": \"200g\",
              \"sell_price\": 90.0,
              \"stock\": 50,
              \"attributes\": null
            }
          ]
        },
        {
          \"product_id\": 124,
          \"product_name\": \"rice\",
          \"quantity\": 1,
          \"session_id\": \"kiosk-123\",
          \"customer_id\": null,
          \"available_variants\": [
            {
              \"variant_id\": 458,
              \"variant_name\": \"1kg\",
              \"sell_price\": 120.0,
              \"stock\": 200,
              \"attributes\": null
            },
            {
              \"variant_id\": 459,
              \"variant_name\": \"5kg\",
              \"sell_price\": 550.0,
              \"stock\": 80,
              \"attributes\": null
            }
          ]
        }
      ],
      \"total_items\": 2,
      \"message\": \"Please select variants for 2 item(s): lux, rice\"
    }"
    ],
    "error": null
}
```

---

## Frontend Requirements

### ⚠️ **IMPORTANT: Frontend Changes Required**

To support the new queue-based system, the frontend must:

### 1. **Detect Multi-Variant Response**

```typescript
// Parse the response
const response = await fetch("/api/ai/command", {
    method: "POST",
    body: JSON.stringify({
        prompt: "add lux and rice to cart",
        session_id: "kiosk-123",
    }),
});

const data = await response.json();

// Check if it contains multi-variant selection
if (data.success && data.actions_executed.length > 0) {
    const actionData = JSON.parse(data.actions_executed[0]);

    if (actionData.pending_selections) {
        // Multi-variant selection needed
        handleMultiVariantSelection(actionData);
    }
}
```

### 2. **Display ALL Variant Options**

```typescript
function handleMultiVariantSelection(multiVariant: MultiVariantSelectionData) {
    // Show UI for ALL products at once
    multiVariant.pending_selections.forEach((selection) => {
        console.log(`Product: ${selection.product_name}`);

        // Display variant options for this product
        selection.available_variants.forEach((variant) => {
            console.log(
                `  - ${variant.variant_name}: PKR ${variant.sell_price}`,
            );
        });
    });

    // Wait for user to select variants for ALL products
    // Then add all to cart
}
```

### 3. **Add All Selected Items to Cart**

```typescript
// After user selects all variants
const selectedVariants = [
    { variant_id: 456, quantity: 1 }, // lux 100g
    { variant_id: 458, quantity: 1 }, // rice 1kg
];

// Add all items to cart
await Promise.all(
    selectedVariants.map((variant) =>
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
```

### 4. **TypeScript/Dart Models**

#### TypeScript:

```typescript
interface MultiVariantSelectionData {
    pending_selections: VariantSelection[];
    total_items: number;
    message: string;
}

interface VariantSelection {
    product_id: number;
    product_name: string;
    quantity: number;
    session_id?: string;
    customer_id?: number;
    available_variants: ProductVariant[];
}

interface ProductVariant {
    variant_id: number;
    variant_name: string;
    sell_price: number;
    stock: number;
    attributes?: any;
}
```

#### Dart/Flutter:

See complete implementation in `AI_MODULE.md` section "Flutter Example (with
Multi-Variant Support)"

---

## Testing

### Test Case 1: Multiple Items with Variants

```bash
curl -X POST http://localhost:3000/api/ai/command \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "add lux and rice to cart",
    "session_id": "test-123"
  }'
```

**Expected:** Both lux and rice variants returned together

### Test Case 2: Items with Single Variant

```bash
curl -X POST http://localhost:3000/api/ai/command \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "add cola to cart",
    "session_id": "test-123"
  }'
```

**Expected:** If cola has only one variant, it's added directly (no variant
selection)

### Test Case 3: Mixed Actions

```bash
curl -X POST http://localhost:3000/api/ai/command \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "add lux and show menu",
    "session_id": "test-123"
  }'
```

**Expected:** Lux variants returned, menu action completed separately

---

## Files Modified

1. ✅ `src/models/ai.rs` - Added queue models
2. ✅ `src/services/command_executor.rs` - Implemented queue logic
3. ✅ `src/handlers/ai_handlers.rs` - Multi-variant response handling
4. ✅ `AI_MODULE.md` - Complete documentation with examples

---

## Key Benefits

| Feature                 | Previous System        | Queue-Based System  |
| ----------------------- | ---------------------- | ------------------- |
| **Multi-item handling** | Stops at first variant | Processes ALL items |
| **Variant selection**   | One at a time          | All together        |
| **Items lost?**         | Yes, if variant needed | NO - all queued     |
| **User experience**     | Multiple steps         | Single step for all |
| **Frontend complexity** | Same                   | Slightly increased  |

---

## Next Steps for Frontend

1. **Update AI response parsing** to detect `pending_selections`
2. **Create multi-variant selection UI** that shows ALL products
3. **Implement batch cart addition** for selected variants
4. **Test with various scenarios** (1 item, 2 items, mixed items)

---

## Documentation

Full documentation available in:

- `AI_MODULE.md` - Complete API reference with examples
- `QUEUE_BASED_AI_IMPLEMENTATION.md` (this file) - Implementation summary

---

**Implementation Date:** October 2025\
**Version:** 2.0.0 (Queue-Based System)\
**Status:** ✅ Backend Complete | ⚠️ Frontend Integration Required

# Cart AI Module Documentation

## Overview

The Cart AI Module handles AI-driven cart operations with intelligent variant
selection. When a user requests to add a product to cart via AI without
specifying a variant, the system now returns all available variants instead of
automatically selecting the first one.

## Key Features

1. **Smart Variant Selection**: Returns available variants when none specified
2. **Automatic Single Variant Handling**: If product has only one variant,
   proceeds automatically
3. **Intelligent Variant Parsing**: Automatically parses variant selection from
   "Product Name (Variant Name)" format
4. **Stock Validation**: Checks availability before confirming actions
5. **Flexible Response Structure**: Different response types for different
   scenarios
6. **Error Recovery**: Provides available variants when invalid variant is
   selected

## API Response Structure

### ActionResponse Base Structure

```json
{
  "action_type": "string | null",
  "success": boolean,
  "message": "string",
  "data": "object | null",
  "error": "string | null"
}
```

## Add to Cart Scenarios

### Scenario 1: Product with Single Variant

**AI Request:**

```json
{
  "actions": [
    {
      "action": "add_to_cart",
      "item": "Coffee",
      "quantity": 2
    }
  ]
}
```

**Response (Single Variant - Auto-proceed):**

```json
{
  "action_type": "add_to_cart",
  "success": true,
  "message": "Ready to add 2 Coffee to cart",
  "data": {
    "variant_id": 123,
    "product_name": "Coffee",
    "variant_name": "Regular",
    "quantity": 2,
    "available_stock": 50,
    "sell_price": 3.99,
    "session_id": "session_123",
    "customer_id": null
  },
  "error": null
}
```

### Scenario 2: Product with Multiple Variants

**AI Request:**

```json
{
  "actions": [
    {
      "action": "add_to_cart",
      "item": "Pizza",
      "quantity": 1
    }
  ]
}
```

**Response (Multiple Variants - Selection Required):**

```json
{
  "action_type": "variant_selection",
  "success": true,
  "message": "Product 'Pizza' has 3 variants available. Please select a variant.",
  "data": {
    "product_id": 456,
    "product_name": "Pizza",
    "quantity": 1,
    "session_id": "session_123",
    "customer_id": null,
    "available_variants": [
      {
        "variant_id": 789,
        "variant_name": "Small",
        "sell_price": 12.99,
        "stock": 25,
        "attributes": null
      },
      {
        "variant_id": 790,
        "variant_name": "Medium",
        "sell_price": 15.99,
        "stock": 30,
        "attributes": null
      },
      {
        "variant_id": 791,
        "variant_name": "Large",
        "sell_price": 18.99,
        "stock": 20,
        "attributes": null
      }
    ]
  },
  "error": null
}
```

### Scenario 2.1: User Responds with Variant Selection

**AI Request (User selects variant):**

```json
{
  "actions": [
    {
      "action": "add_to_cart",
      "item": "Pizza (Medium)",
      "quantity": 1
    }
  ]
}
```

**Response (Variant Parsed and Added):**

```json
{
  "action_type": "add_to_cart",
  "success": true,
  "message": "Ready to add 1 Pizza to cart",
  "data": {
    "variant_id": 790,
    "product_name": "Pizza",
    "variant_name": "Medium",
    "quantity": 1,
    "available_stock": 30,
    "sell_price": 15.99,
    "session_id": "session_123",
    "customer_id": null
  },
  "error": null
}
```

### Scenario 2.2: Invalid Variant Selection

**AI Request (Invalid variant):**

```json
{
  "actions": [
    {
      "action": "add_to_cart",
      "item": "Pizza (Extra Large)",
      "quantity": 1
    }
  ]
}
```

**Response (Variant Not Found):**

```json
{
  "action_type": "variant_selection",
  "success": true,
  "message": "Variant 'Extra Large' not found for 'Pizza'. Available variants: Small, Medium, Large",
  "data": {
    "product_id": 456,
    "product_name": "Pizza",
    "quantity": 1,
    "session_id": "session_123",
    "customer_id": null,
    "available_variants": [
      {
        "variant_id": 789,
        "variant_name": "Small",
        "sell_price": 12.99,
        "stock": 25,
        "attributes": null
      },
      {
        "variant_id": 790,
        "variant_name": "Medium",
        "sell_price": 15.99,
        "stock": 30,
        "attributes": null
      },
      {
        "variant_id": 791,
        "variant_name": "Large",
        "sell_price": 18.99,
        "stock": 20,
        "attributes": null
      }
    ]
  },
  "error": null
}
```

### Scenario 3: Specific Variant Requested

**AI Request:**

```json
{
  "actions": [
    {
      "action": "add_to_cart",
      "item": "Pizza",
      "quantity": 1,
      "variant_id": 790
    }
  ]
}
```

**Response (Specific Variant):**

```json
{
  "action_type": "add_to_cart",
  "success": true,
  "message": "Ready to add 1 Pizza to cart",
  "data": {
    "variant_id": 790,
    "product_name": "Pizza",
    "variant_name": "Medium",
    "quantity": 1,
    "available_stock": 30,
    "sell_price": 15.99,
    "session_id": "session_123",
    "customer_id": null
  },
  "error": null
}
```

### Scenario 4: Insufficient Stock

**Response (Stock Issue):**

```json
{
  "action_type": "add_to_cart",
  "success": false,
  "message": "Insufficient stock for Pizza. Only 5 available",
  "data": {
    "variant_id": 789,
    "product_name": "Pizza",
    "variant_name": "Small",
    "quantity": 10,
    "available_stock": 5,
    "sell_price": 12.99,
    "session_id": "session_123",
    "customer_id": null
  },
  "error": "Insufficient stock"
}
```

### Scenario 5: Product Not Found

**Response (Product Not Found):**

```json
{
  "action_type": "add_to_cart",
  "success": false,
  "message": "Product 'NonExistentItem' not found",
  "data": null,
  "error": "Product not found"
}
```

## Data Models

### VariantSelectionActionData

```rust
pub struct VariantSelectionActionData {
    pub product_id: i32,
    pub product_name: String,
    pub quantity: i32,
    pub session_id: Option<String>,
    pub customer_id: Option<i32>,
    pub available_variants: Vec<ProductVariant>,
}
```

### ProductVariant

```rust
pub struct ProductVariant {
    pub variant_id: i32,
    pub variant_name: String,
    pub sell_price: f64,
    pub stock: i32,
    pub attributes: Option<serde_json::Value>, // For future extension
}
```

### CartActionData

```rust
pub struct CartActionData {
    pub variant_id: i32,
    pub product_name: String,
    pub variant_name: String,
    pub quantity: i32,
    pub available_stock: i32,
    pub sell_price: f64,
    pub session_id: Option<String>,
    pub customer_id: Option<i32>,
}
```

## Variant Parsing Logic

### How Variant Parsing Works

The system automatically detects and parses variant information from user input
in the format:

```
"Product Name (Variant Name)"
```

**Examples:**

- `"Pizza (Medium)"` → Product: "Pizza", Variant: "Medium"
- `"Burger (Large)"` → Product: "Burger", Variant: "Large"
- `"Coffee (Decaf)"` → Product: "Coffee", Variant: "Decaf"

### Parsing Process

1. **Input Detection**: System checks if item name contains parentheses pattern
2. **Product Search**: Searches for the base product name (before parentheses)
3. **Variant Matching**: Finds the specific variant within the product's
   variants (case-insensitive)
4. **Validation**: Proceeds with normal stock validation if variant found
5. **Error Handling**: Returns available variants if specified variant doesn't
   exist

### Frontend Implementation for Variant Parsing

The frontend doesn't need to do anything special - just send the user's input
as-is:

```dart
// User types: "Pizza (Medium)"
final request = {
  "actions": [
    {
      "action": "add_to_cart",
      "item": "Pizza (Medium)", // Send exactly as user typed
      "quantity": 1
    }
  ]
};
```

The backend will automatically parse this and return either:

- Success with specific variant added
- Variant selection if variant not found
- Product not found error

````
## Frontend Implementation Guide

### 1. Handling Variant Selection Response

When you receive an `action_type: "variant_selection"` response:

```dart
// Example Flutter/Dart implementation
void handleVariantSelection(ActionResponse response) {
  if (response.actionType == "variant_selection") {
    final data = VariantSelectionActionData.fromJson(response.data);
    
    // Show variant selection UI
    showVariantSelectionDialog(
      productName: data.productName,
      quantity: data.quantity,
      variants: data.availableVariants,
      onVariantSelected: (variantId) {
        // Make new AI request with selected variant
        makeAddToCartRequest(
          item: data.productName,
          quantity: data.quantity,
          variantId: variantId,
        );
      },
    );
  }
}
````

### 2. Variant Selection Dialog

```dart
Widget buildVariantSelectionDialog({
  required String productName,
  required int quantity,
  required List<ProductVariant> variants,
  required Function(int) onVariantSelected,
}) {
  return AlertDialog(
    title: Text('Select $productName Variant'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: variants.map((variant) {
        return ListTile(
          title: Text(variant.variantName),
          subtitle: Text('\$${variant.sellPrice} - Stock: ${variant.stock}'),
          onTap: () {
            onVariantSelected(variant.variantId);
            Navigator.of(context).pop();
          },
        );
      }).toList(),
    ),
  );
}
```

### 3. Making AI Request with Selected Variant

```dart
Future<void> makeAddToCartRequest({
  required String item,
  required int quantity,
  required int variantId,
}) async {
  final request = {
    "actions": [
      {
        "action": "add_to_cart",
        "item": item,
        "quantity": quantity,
        "variant_id": variantId,
      }
    ]
  };
  
  // Send to AI endpoint
  final response = await aiService.processCommand(request);
  handleAddToCartResponse(response);
}
```

### 4. Handling Success Response

```dart
void handleAddToCartResponse(ActionResponse response) {
  if (response.success && response.actionType == "add_to_cart") {
    final data = CartActionData.fromJson(response.data);
    
    // Add to cart
    cartService.addItem(
      variantId: data.variantId,
      productName: data.productName,
      variantName: data.variantName,
      quantity: data.quantity,
      price: data.sellPrice,
    );
    
    // Show success message
    showSnackBar(response.message);
  } else {
    // Handle error
    showErrorDialog(response.message);
  }
}
```

## Error Handling

### Common Error Scenarios

1. **Product Not Found**:
   `action_type: "add_to_cart", success: false, error: "Product not found"`
2. **No Variants Available**:
   `action_type: "add_to_cart", success: false, error: "No variations available"`
3. **Insufficient Stock**:
   `action_type: "add_to_cart", success: false, error: "Insufficient stock"`

### Error Response Handling

```dart
void handleError(ActionResponse response) {
  if (!response.success) {
    switch (response.error) {
      case "Product not found":
        showErrorDialog("The requested product was not found.");
        break;
      case "No variations available":
        showErrorDialog("This product has no available variants.");
        break;
      case "Insufficient stock":
        // Show stock info from data
        final data = CartActionData.fromJson(response.data);
        showErrorDialog(
          "Only ${data.availableStock} ${data.productName} available."
        );
        break;
      default:
        showErrorDialog(response.message);
    }
  }
}
```

## Testing Scenarios

### Test Cases for Frontend

1. **Single Variant Product**: Should proceed automatically without showing
   selection
2. **Multi-Variant Product**: Should show variant selection dialog
3. **Specific Variant Request**: Should bypass selection and add directly
4. **Variant Parsing**: Should correctly parse "Product (Variant)" format
5. **Invalid Variant**: Should show available variants when variant not found
6. **Out of Stock**: Should show appropriate error message
7. **Product Not Found**: Should show not found message
8. **Network Error**: Should handle gracefully

### Variant Parsing Test Cases

1. **Valid Variant Format**: `"Pizza (Medium)"` → Should add Medium pizza
2. **Case Insensitive**: `"pizza (medium)"` → Should work same as above
3. **Invalid Variant**: `"Pizza (Extra Large)"` → Should show available variants
4. **No Parentheses**: `"Pizza"` → Should show variant selection
5. **Malformed Format**: `"Pizza (Medium"` → Should treat as product name only
6. **Empty Variant**: `"Pizza ()"` → Should treat as product name only

### Sample Test Data

```json
{
  "single_variant_product": {
    "name": "Coffee",
    "variants": [
      { "id": 123, "name": "Regular", "price": 3.99, "stock": 50 }
    ]
  },
  "multi_variant_product": {
    "name": "Pizza",
    "variants": [
      { "id": 789, "name": "Small", "price": 12.99, "stock": 25 },
      { "id": 790, "name": "Medium", "price": 15.99, "stock": 30 },
      { "id": 791, "name": "Large", "price": 18.99, "stock": 20 }
    ]
  }
}
```

## Integration Notes

1. **Session Management**: Always include `session_id` for kiosk mode and
   `customer_id` for authenticated users
2. **Error Recovery**: Implement retry mechanisms for network failures
3. **UI Feedback**: Show loading states during AI processing
4. **Accessibility**: Ensure variant selection is accessible via screen readers
5. **Mobile Optimization**: Design variant selection for touch interfaces

## Future Enhancements

1. **Attributes Support**: Extend `ProductVariant.attributes` for size, color,
   etc.
2. **Favorites**: Remember user's preferred variants
3. **Smart Suggestions**: AI-powered variant recommendations
4. **Bulk Operations**: Handle multiple product additions with variant selection
5. **Price Comparison**: Show price differences between variants prominently

## Troubleshooting

### Common Issues

1. **Variant Selection Not Showing**: Check if `action_type` is
   "variant_selection"
2. **Wrong Variant Added**: Verify `variant_id` is correctly passed in follow-up
   request
3. **Stock Issues**: Always check `available_stock` before confirming addition
4. **Session Lost**: Ensure `session_id` is maintained across requests

### Debug Tips

1. Log all AI responses to understand the flow
2. Validate JSON structure before parsing
3. Check network connectivity for AI requests
4. Verify product and variant IDs in database

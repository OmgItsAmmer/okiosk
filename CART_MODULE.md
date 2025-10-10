# Cart Module Specification

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Backend Components (Rust)](#backend-components-rust)
4. [Frontend Components (Flutter/Dart)](#frontend-components-flutterdart)
5. [API Endpoints](#api-endpoints)
6. [Data Models](#data-models)
7. [Integration Guide](#integration-guide)
8. [Error Handling](#error-handling)
9. [Kiosk Mode](#kiosk-mode)

---

## Overview

The Cart Module provides a comprehensive shopping cart system for both
e-commerce and kiosk applications. It supports both customer-specific carts and
kiosk session-based carts with real-time synchronization capabilities.

### Key Features

- **Dual Cart System**: Separate handling for customer carts and kiosk carts
- **Stock Validation**: Real-time stock checking and adjustment recommendations
- **Cart Operations**: Add, update, remove, and clear cart items
- **Kiosk Integration**: Session-based carts for kiosk mode
- **Product Details**: Complete cart items with product and variant information
- **Cart Summary**: Automatic calculation of totals and item counts

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter/Dart Client                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Cart        │  │  Cart        │  │  Kiosk Cart  │      │
│  │  Controller  │  │  Repository  │  │  Realtime    │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼ HTTP/JSON
┌─────────────────────────────────────────────────────────────┐
│                    Rust Backend (Axum)                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Handlers   │  │    Models    │  │   Database   │      │
│  │  (Routing)   │  │ (Validation) │  │   Queries    │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼ SQL
                    ┌───────────────┐
                    │   PostgreSQL  │
                    │   (Supabase)  │
                    │  cart table   │
                    │ kiosk_cart    │
                    └───────────────┘
```

---

## Backend Components (Rust)

### File Structure

```
src/
├── models/
│   └── cart.rs                # Cart data models and DTOs
├── handlers/
│   └── cart_handlers.rs       # HTTP request handlers
├── database/
│   └── cart_queries.rs        # Database query functions
└── main.rs                    # Router configuration
```

### 1. Models (`src/models/cart.rs`)

#### Core Models

##### `Cart`

Represents a basic cart entry in the database.

```rust
pub struct Cart {
    pub cart_id: i32,
    pub variant_id: Option<i32>,
    pub quantity: String,
    pub customer_id: Option<i32>,
    pub kiosk_session_id: Option<String>,
}
```

**Field Descriptions:**

- `cart_id`: Unique identifier (Primary Key)
- `variant_id`: Foreign key to product_variants table
- `quantity`: String representation of item quantity
- `customer_id`: Foreign key to customers table (nullable for kiosk)
- `kiosk_session_id`: Optional session ID for kiosk mode

##### `KioskCart`

Represents a kiosk cart entry.

```rust
pub struct KioskCart {
    pub kiosk_id: i32,
    pub kiosk_session_id: String,
    pub variant_id: i32,
    pub quantity: i32,
    pub created_at: Option<DateTime<Utc>>,
}
```

##### `CartItem`

Complete cart item with product and variant details.

```rust
pub struct CartItem {
    // Cart data
    pub cart_id: i32,
    pub variant_id: Option<i32>,
    pub quantity: String,
    pub customer_id: Option<i32>,
    pub kiosk_session_id: Option<String>,
    
    // Product data
    pub product_name: String,
    pub product_description: Option<String>,
    pub base_price: String,
    pub sale_price: String,
    pub brand_id: Option<i32>,
    
    // Variant data
    pub variant_name: String,
    pub sell_price: Decimal,
    pub buy_price: Option<Decimal>,
    pub stock: i32,
    pub is_visible: bool,
}
```

##### `CartStockValidation`

Stock validation result for cart items.

```rust
pub struct CartStockValidation {
    pub cart_id: i32,
    pub variant_id: i32,
    pub product_name: String,
    pub variant_name: String,
    pub current_quantity: i32,
    pub available_stock: i32,
    pub suggested_quantity: i32,
    pub needs_adjustment: bool,
    pub adjustment_reason: String,
    pub should_remove: bool,
}
```

#### Request Models

##### `AddToCartRequest`

```rust
pub struct AddToCartRequest {
    pub variant_id: i32,
    pub quantity: i32,
}
```

##### `AddToKioskCartRequest`

```rust
pub struct AddToKioskCartRequest {
    pub kiosk_session_id: String,
    pub variant_id: i32,
    pub quantity: i32,
}
```

##### `UpdateCartQuantityRequest`

```rust
pub struct UpdateCartQuantityRequest {
    pub quantity: i32,
}
```

#### Response Models

##### `CartListResponse`

```rust
pub struct CartListResponse {
    pub items: Vec<CartItem>,
    pub total_items: i32,
    pub subtotal: f64,
    pub status: String,
}
```

##### `CartOperationResponse`

```rust
pub struct CartOperationResponse {
    pub success: bool,
    pub message: String,
}
```

##### `CartValidationResponse`

```rust
pub struct CartValidationResponse {
    pub has_issues: bool,
    pub adjustments: Vec<CartStockValidation>,
}
```

### 2. Database Queries (`src/database/cart_queries.rs`)

All database queries are implemented in the `CartQueries` struct:

#### Query Methods

| Method                                        | Description                       | SQL Behavior                   |
| --------------------------------------------- | --------------------------------- | ------------------------------ |
| `fetch_complete_cart_items(customer_id)`      | Fetch customer cart with details  | JOIN with products & variants  |
| `fetch_complete_kiosk_cart_items(session_id)` | Fetch kiosk cart with details     | JOIN with products & variants  |
| `add_to_cart(customer_id, variant, qty)`      | Add item to cart                  | INSERT or UPDATE if exists     |
| `add_to_kiosk_cart(session_id, variant, qty)` | Add item to kiosk cart            | INSERT or UPDATE if exists     |
| `update_cart_item_quantity(cart_id, qty)`     | Update cart item quantity         | UPDATE cart SET quantity       |
| `update_kiosk_cart_item_quantity(id, qty)`    | Update kiosk cart item quantity   | UPDATE kiosk_cart SET quantity |
| `remove_cart_item(cart_id)`                   | Remove item from cart             | DELETE FROM cart               |
| `remove_kiosk_cart_item(kiosk_id)`            | Remove item from kiosk cart       | DELETE FROM kiosk_cart         |
| `clear_cart(customer_id)`                     | Clear entire cart                 | DELETE all items for customer  |
| `clear_kiosk_cart(session_id)`                | Clear kiosk cart                  | DELETE all items for session   |
| `validate_variant_stock(variant_id, qty)`     | Check if variant has enough stock | CHECK stock >= quantity        |
| `validate_cart_stock(customer_id)`            | Validate entire cart stock        | CHECK all items against stock  |
| `can_add_to_cart(variant_id, qty)`            | Check if can add to cart          | Validate stock and visibility  |

### 3. Handlers (`src/handlers/cart_handlers.rs`)

HTTP request handlers that process incoming requests and return responses. See
[API Endpoints](#api-endpoints) section for detailed endpoint specifications.

---

## Frontend Components (Flutter/Dart)

### File Structure

```
flutter/
├── models/
│   ├── cart_model.dart
│   └── kiosk_cart_model.dart
└── controller/
    └── cart_controller.dart
```

### 1. Models

#### `CartModel` (`flutter/models/cart_model.dart`)

```dart
class CartModel {
  final int cartId;
  final int? variantId;
  final String quantity;
  final int? customerId;
  final String? kioskSessionId;
}
```

#### `KioskCartModel` (`flutter/models/kiosk_cart_model.dart`)

```dart
class KioskCartModel {
  final int kioskId;
  final String kioskSessionId;
  final int variantId;
  final int quantity;
  final DateTime? createdAt;
}
```

#### `CartItemModel`

```dart
class CartItemModel {
  final CartModel cart;
  final String productName;
  final String productDescription;
  final String basePrice;
  final String salePrice;
  final int? brandId;
  final String variantName;
  final double sellPrice;
  final double? buyPrice;
  final int stock;
  final bool isVisible;
}
```

### 2. Controllers

#### `CartController` (`flutter/controller/cart_controller.dart`)

Main controller for cart operations.

**State Variables:**

```dart
final RxBool isLoading
final RxList<CartItemModel> cartItems
final Rx<CartSummary> cartSummary
final RxList<CartStockValidation> stockAdjustments
final RxBool hasStockIssues
final RxString _kioskUUID
final RxString _scannedKioskSessionId
```

**Key Methods:**

| Method                                | Returns        | Description               |
| ------------------------------------- | -------------- | ------------------------- |
| `fetchCart()`                         | `Future<void>` | Fetch customer cart       |
| `fetchKioskCart()`                    | `Future<void>` | Fetch kiosk cart          |
| `addToCart(variantId, quantity)`      | `Future<bool>` | Add item to cart          |
| `addToKioskCart(variantId, quantity)` | `Future<bool>` | Add item to kiosk cart    |
| `updateCartItemQuantity(item, qty)`   | `Future<bool>` | Update cart item quantity |
| `removeCartItem(item)`                | `Future<bool>` | Remove item from cart     |
| `clearCart()`                         | `Future<bool>` | Clear entire cart         |
| `validateCartStock()`                 | `Future<bool>` | Validate cart stock       |
| `applyStockAdjustments()`             | `Future<bool>` | Apply stock adjustments   |

---

## API Endpoints

### Base URL

- **Development**: `http://localhost:3000`
- **Production**: Configure based on deployment

### Customer Cart Endpoints

#### 1. Get Cart Items

**Endpoint:** `GET /api/cart/:customer_id`

**Description:** Fetches all cart items for a customer with complete product
details.

**Path Parameters:**

| Parameter     | Type    | Description |
| ------------- | ------- | ----------- |
| `customer_id` | integer | Customer ID |

**Request Example:**

```
GET /api/cart/123
```

**Response:**

```json
{
    "items": [
        {
            "cart_id": 1,
            "variant_id": 456,
            "quantity": "2",
            "customer_id": 123,
            "kiosk_session_id": null,
            "product_name": "Premium T-Shirt",
            "product_description": "High quality cotton",
            "base_price": "25.00",
            "sale_price": "20.00",
            "brand_id": 3,
            "variant_name": "Medium Red",
            "sell_price": 20.00,
            "buy_price": 12.00,
            "stock": 50,
            "is_visible": true
        }
    ],
    "total_items": 2,
    "subtotal": 40.00,
    "status": "success"
}
```

**Status Codes:**

- `200 OK`: Success
- `500 Internal Server Error`: Database error

---

#### 2. Add Item to Cart

**Endpoint:** `POST /api/cart/:customer_id/add`

**Description:** Adds an item to the customer's cart. If item already exists,
increases quantity.

**Path Parameters:**

| Parameter     | Type    | Description |
| ------------- | ------- | ----------- |
| `customer_id` | integer | Customer ID |

**Request Body:**

```json
{
    "variant_id": 456,
    "quantity": 2
}
```

**Response:**

```json
{
    "success": true,
    "message": "Item added to cart successfully"
}
```

**Status Codes:**

- `200 OK`: Success
- `500 Internal Server Error`: Database error

---

#### 3. Update Cart Item Quantity

**Endpoint:** `PUT /api/cart/item/:cart_id`

**Description:** Updates the quantity of a specific cart item.

**Path Parameters:**

| Parameter | Type    | Description  |
| --------- | ------- | ------------ |
| `cart_id` | integer | Cart item ID |

**Request Body:**

```json
{
    "quantity": 5
}
```

**Response:**

```json
{
    "success": true,
    "message": "Cart item quantity updated"
}
```

**Status Codes:**

- `200 OK`: Success
- `500 Internal Server Error`: Database error

---

#### 4. Remove Cart Item

**Endpoint:** `DELETE /api/cart/item/:cart_id`

**Description:** Removes a specific item from the cart.

**Path Parameters:**

| Parameter | Type    | Description  |
| --------- | ------- | ------------ |
| `cart_id` | integer | Cart item ID |

**Response:**

```json
{
    "success": true,
    "message": "Item removed from cart"
}
```

**Status Codes:**

- `200 OK`: Success
- `500 Internal Server Error`: Database error

---

#### 5. Clear Cart

**Endpoint:** `DELETE /api/cart/:customer_id/clear`

**Description:** Removes all items from the customer's cart.

**Path Parameters:**

| Parameter     | Type    | Description |
| ------------- | ------- | ----------- |
| `customer_id` | integer | Customer ID |

**Response:**

```json
{
    "success": true,
    "message": "Cart cleared successfully"
}
```

**Status Codes:**

- `200 OK`: Success
- `500 Internal Server Error`: Database error

---

#### 6. Validate Cart Stock

**Endpoint:** `GET /api/cart/:customer_id/validate`

**Description:** Validates all cart items against current stock levels and
returns any adjustments needed.

**Path Parameters:**

| Parameter     | Type    | Description |
| ------------- | ------- | ----------- |
| `customer_id` | integer | Customer ID |

**Response:**

```json
{
    "has_issues": true,
    "adjustments": [
        {
            "cart_id": 1,
            "variant_id": 456,
            "product_name": "Premium T-Shirt",
            "variant_name": "Medium Red",
            "current_quantity": 10,
            "available_stock": 5,
            "suggested_quantity": 5,
            "needs_adjustment": true,
            "adjustment_reason": "Only 5 available",
            "should_remove": false
        }
    ]
}
```

**Status Codes:**

- `200 OK`: Success
- `500 Internal Server Error`: Database error

---

### Kiosk Cart Endpoints

#### 7. Get Kiosk Cart Items

**Endpoint:** `GET /api/cart/kiosk/:session_id`

**Description:** Fetches all cart items for a kiosk session.

**Path Parameters:**

| Parameter    | Type   | Description        |
| ------------ | ------ | ------------------ |
| `session_id` | string | Kiosk session UUID |

**Request Example:**

```
GET /api/cart/kiosk/550e8400-e29b-41d4-a716-446655440000
```

**Response:** Same format as customer cart.

**Status Codes:**

- `200 OK`: Success
- `500 Internal Server Error`: Database error

---

#### 8. Add Item to Kiosk Cart

**Endpoint:** `POST /api/cart/kiosk/add`

**Description:** Adds an item to a kiosk cart.

**Request Body:**

```json
{
    "kiosk_session_id": "550e8400-e29b-41d4-a716-446655440000",
    "variant_id": 456,
    "quantity": 2
}
```

**Response:**

```json
{
    "success": true,
    "message": "Item added to kiosk cart successfully"
}
```

**Status Codes:**

- `200 OK`: Success
- `500 Internal Server Error`: Database error

---

#### 9. Update Kiosk Cart Item

**Endpoint:** `PUT /api/cart/kiosk/item/:kiosk_id`

**Description:** Updates the quantity of a kiosk cart item.

**Path Parameters:**

| Parameter  | Type    | Description        |
| ---------- | ------- | ------------------ |
| `kiosk_id` | integer | Kiosk cart item ID |

**Request Body:**

```json
{
    "quantity": 5
}
```

**Response:**

```json
{
    "success": true,
    "message": "Kiosk cart item quantity updated"
}
```

**Status Codes:**

- `200 OK`: Success
- `500 Internal Server Error`: Database error

---

#### 10. Remove Kiosk Cart Item

**Endpoint:** `DELETE /api/cart/kiosk/item/:kiosk_id`

**Description:** Removes an item from kiosk cart.

**Path Parameters:**

| Parameter  | Type    | Description        |
| ---------- | ------- | ------------------ |
| `kiosk_id` | integer | Kiosk cart item ID |

**Response:**

```json
{
    "success": true,
    "message": "Item removed from kiosk cart"
}
```

**Status Codes:**

- `200 OK`: Success
- `500 Internal Server Error`: Database error

---

#### 11. Clear Kiosk Cart

**Endpoint:** `DELETE /api/cart/kiosk/:session_id/clear`

**Description:** Removes all items from a kiosk cart.

**Path Parameters:**

| Parameter    | Type   | Description        |
| ------------ | ------ | ------------------ |
| `session_id` | string | Kiosk session UUID |

**Response:**

```json
{
    "success": true,
    "message": "Kiosk cart cleared successfully"
}
```

**Status Codes:**

- `200 OK`: Success
- `500 Internal Server Error`: Database error

---

## Data Models

### Database Schema

#### Cart Table

```sql
CREATE TABLE cart (
    cart_id SERIAL PRIMARY KEY,
    variant_id INTEGER REFERENCES product_variants(variant_id),
    quantity VARCHAR(50) NOT NULL,
    customer_id INTEGER REFERENCES customers(customer_id),
    kiosk_session_id VARCHAR(255)
);
```

#### Kiosk Cart Table

```sql
CREATE TABLE kiosk_cart (
    kiosk_id SERIAL PRIMARY KEY,
    kiosk_session_id VARCHAR(255) NOT NULL,
    variant_id INTEGER NOT NULL REFERENCES product_variants(variant_id),
    quantity INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

---

## Integration Guide

### 1. Backend Setup (Rust)

#### Step 1: Configure Environment

Already done in main setup.

#### Step 2: Run the Server

```bash
cargo run --release
```

### 2. Flutter Client Setup

#### Step 1: Create Cart Repository

```dart
class CartRepository {
  final BackendService backend;
  
  CartRepository(this.backend);
  
  Future<CartListResponse> fetchCart(int customerId) async {
    final response = await backend.get('/api/cart/$customerId');
    
    if (response.statusCode == 200) {
      return CartListResponse.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load cart');
    }
  }
  
  Future<bool> addToCart(int customerId, int variantId, int quantity) async {
    final response = await backend.post(
      '/api/cart/$customerId/add',
      body: {'variant_id': variantId, 'quantity': quantity},
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['success'] ?? false;
    } else {
      throw Exception('Failed to add to cart');
    }
  }
}
```

---

## Error Handling

### Backend Error Responses

| Status Code                 | Meaning               | Response Format                 |
| --------------------------- | --------------------- | ------------------------------- |
| `200 OK`                    | Success               | JSON response with success/data |
| `500 Internal Server Error` | Server/database error | No body (logged server-side)    |

### Stock Validation

When adding to cart, the backend automatically validates stock:

```json
{
    "success": false,
    "message": "Insufficient stock or product not available"
}
```

---

## Kiosk Mode

### Overview

Kiosk mode allows customers to use a kiosk device without logging in. The kiosk
generates a unique session UUID which is used to track cart items.

### Workflow

1. **Kiosk Initialization**: Kiosk generates UUID on startup
2. **QR Code Display**: UUID is displayed as QR code
3. **Customer Scan**: Customer scans QR with mobile app
4. **Cart Sync**: Mobile app can now add items to kiosk cart
5. **Checkout**: Kiosk uses session UUID to retrieve cart

### Implementation

```dart
// In kiosk app
final kioskUUID = THelperFunctions.generateRandomUUID();

// Add to kiosk cart
await cartRepository.addToKioskCart(kioskUUID, variantId, quantity);

// In mobile app (after scanning QR)
await cartRepository.addToKioskCart(scannedUUID, variantId, quantity);
```

---

## Testing

### Backend Testing

```bash
# Get cart
curl http://localhost:3000/api/cart/123

# Add to cart
curl -X POST http://localhost:3000/api/cart/123/add \
  -H "Content-Type: application/json" \
  -d '{"variant_id": 456, "quantity": 2}'

# Update quantity
curl -X PUT http://localhost:3000/api/cart/item/1 \
  -H "Content-Type: application/json" \
  -d '{"quantity": 5}'

# Remove item
curl -X DELETE http://localhost:3000/api/cart/item/1

# Clear cart
curl -X DELETE http://localhost:3000/api/cart/123/clear

# Validate stock
curl http://localhost:3000/api/cart/123/validate
```

---

## Appendix

### Complete Endpoint Summary

| Method | Endpoint                            | Purpose                   |
| ------ | ----------------------------------- | ------------------------- |
| GET    | `/api/cart/:customer_id`            | Get cart items            |
| POST   | `/api/cart/:customer_id/add`        | Add item to cart          |
| PUT    | `/api/cart/item/:cart_id`           | Update cart item quantity |
| DELETE | `/api/cart/item/:cart_id`           | Remove cart item          |
| DELETE | `/api/cart/:customer_id/clear`      | Clear cart                |
| GET    | `/api/cart/:customer_id/validate`   | Validate cart stock       |
| GET    | `/api/cart/kiosk/:session_id`       | Get kiosk cart items      |
| POST   | `/api/cart/kiosk/add`               | Add item to kiosk cart    |
| PUT    | `/api/cart/kiosk/item/:kiosk_id`    | Update kiosk cart item    |
| DELETE | `/api/cart/kiosk/item/:kiosk_id`    | Remove kiosk cart item    |
| DELETE | `/api/cart/kiosk/:session_id/clear` | Clear kiosk cart          |

### Version Information

- **Specification Version:** 1.0
- **Last Updated:** 2024
- **Backend Framework:** Rust + Axum
- **Database:** PostgreSQL (Supabase)
- **Client Framework:** Flutter/Dart with GetX

---

**End of Cart Module Specification**

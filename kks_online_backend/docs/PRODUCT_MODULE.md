# Product Module Specification

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Backend Components (Rust)](#backend-components-rust)
4. [Frontend Components (Flutter/Dart)](#frontend-components-flutterdart)
5. [API Endpoints](#api-endpoints)
6. [Data Models](#data-models)
7. [Integration Guide](#integration-guide)
8. [Error Handling](#error-handling)

---

## Overview

The Product Module is a comprehensive system for managing products, product
variations, and related operations in an e-commerce and kiosk application. It
provides a complete backend API built with Rust/Axum and Flutter/Dart client
integration.

### Key Features

- **Product Management**: CRUD operations for products with pagination
- **Product Variations**: Support for multiple variants per product (sizes,
  colors, etc.)
- **Search & Filter**: Full-text search, category filtering, brand filtering
- **POS Integration**: Optimized endpoints for Point-of-Sale systems
- **Stock Management**: Real-time stock checking and availability
- **Performance**: Lazy loading, caching, and pagination support

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter/Dart Client                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Product     │  │  Variation   │  │  Product     │      │
│  │  Controller  │  │  Controller  │  │  Repository  │      │
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
                    └───────────────┘
```

---

## Backend Components (Rust)

### File Structure

```
src/
├── models/
│   └── product.rs          # Product data models and DTOs
├── handlers/
│   └── product_handlers.rs # HTTP request handlers
├── database/
│   └── product_queries.rs  # Database query functions
└── main.rs                 # Router configuration
```

### 1. Models (`src/models/product.rs`)

#### Core Models

##### `Product`

Represents a product in the system.

```rust
pub struct Product {
    pub product_id: i32,
    pub name: String,
    pub description: Option<String>,
    pub price_range: String,
    pub base_price: String,
    pub sale_price: String,
    pub category_id: Option<i32>,
    pub ispopular: bool,
    pub stock_quantity: i32,
    pub created_at: Option<DateTime<Utc>>,
    pub brand_id: Option<i32>,
    pub alert_stock: Option<i32>,
    pub is_visible: bool,
    pub tag: Option<String>,
}
```

**Field Descriptions:**

- `product_id`: Unique identifier (Primary Key)
- `name`: Product display name
- `description`: Optional product description
- `price_range`: String representing price range (e.g., "$10-$20")
- `base_price`: Original price as string
- `sale_price`: Current selling price as string
- `category_id`: Foreign key to category table
- `ispopular`: Flag indicating if product is marked as popular
- `stock_quantity`: Total stock across all variations
- `created_at`: Product creation timestamp
- `brand_id`: Foreign key to brand table
- `alert_stock`: Stock level that triggers low stock alerts
- `is_visible`: Whether product should be displayed to customers
- `tag`: Optional tags for categorization/filtering

##### `ProductVariation`

Represents a specific variant of a product.

```rust
pub struct ProductVariation {
    pub variant_id: i32,
    pub sell_price: Decimal,
    pub buy_price: Decimal,
    pub product_id: i32,
    pub variant_name: String,
    pub stock: i32,
    pub is_visible: bool,
}
```

**Field Descriptions:**

- `variant_id`: Unique identifier (Primary Key)
- `sell_price`: Price at which this variant is sold
- `buy_price`: Cost price of this variant
- `product_id`: Foreign key to parent product
- `variant_name`: Name/description of variant (e.g., "Medium Red")
- `stock`: Available stock for this specific variant
- `is_visible`: Whether variant should be shown to customers

#### Request Models

##### `ProductQueryParams`

Used for pagination with limit/offset or page-based approaches.

```rust
pub struct ProductQueryParams {
    pub limit: Option<i64>,
    pub offset: Option<i64>,
    pub page: Option<i64>,
    pub page_size: Option<i64>,
}
```

##### `SearchQueryParams`

Used for product search endpoints.

```rust
pub struct SearchQueryParams {
    pub query: String,
    pub page: Option<i64>,
    pub page_size: Option<i64>,
}
```

#### Response Models

##### `ProductListResponse`

Standard response for endpoints returning multiple products.

```rust
pub struct ProductListResponse {
    pub products: Vec<Product>,
    pub total_count: Option<i64>,
    pub fetched_count: i64,
    pub offset: Option<i64>,
    pub has_more: bool,
}
```

**Field Descriptions:**

- `products`: Array of product objects
- `total_count`: Total number of products matching criteria (if available)
- `fetched_count`: Number of products in current response
- `offset`: Current offset for pagination
- `has_more`: Boolean indicating if more products are available

##### `ProductDetailResponse`

Response for single product with all variations.

```rust
pub struct ProductDetailResponse {
    pub product: Product,
    pub product_variants: Vec<ProductVariation>,
}
```

### 2. Database Queries (`src/database/product_queries.rs`)

All database queries are implemented in the `ProductQueries` struct:

#### Query Methods

| Method                                                     | Description                            | SQL Behavior                                  |
| ---------------------------------------------------------- | -------------------------------------- | --------------------------------------------- |
| `get_popular_products_count()`                             | Count of popular products              | `WHERE ispopular = true AND isVisible = true` |
| `fetch_popular_products(limit, offset)`                    | Fetch popular products with pagination | Ordered by `created_at DESC`                  |
| `fetch_all_products_for_pos()`                             | Fetch all visible products             | Ordered by `name ASC`                         |
| `fetch_products_by_category(category_id, page, page_size)` | Products in a category                 | Filtered by `category_id`, paginated          |
| `fetch_products_by_brand(brand_id)`                        | All products for a brand               | Filtered by `brandID`                         |
| `search_products(query, page, page_size)`                  | Full-text search                       | `LIKE` search on `name` and `description`     |
| `fetch_product_by_id(product_id)`                          | Single product details                 | Fetched by `product_id`                       |
| `fetch_product_variations(product_id)`                     | All variations for a product           | Only visible variations                       |
| `fetch_variation_by_id(variant_id)`                        | Single variation details               | Fetched by `variant_id`                       |
| `fetch_variations_by_variant_id(variant_id)`               | All related variations                 | Gets product_id then fetches all variations   |
| `check_variant_stock(variant_id)`                          | Check stock for variant                | Returns stock count                           |
| `get_total_products_count()`                               | Total visible products                 | Count of all visible products                 |
| `get_category_products_count(category_id)`                 | Count in category                      | Count filtered by category                    |

### 3. Handlers (`src/handlers/product_handlers.rs`)

HTTP request handlers that process incoming requests and return responses. See
[API Endpoints](#api-endpoints) section for detailed endpoint specifications.

---

## Frontend Components (Flutter/Dart)

### File Structure

```
flutter/
├── models/
│   ├── product_model.dart
│   └── product_variation_model.dart
└── controller/
    ├── product_controller.dart
    └── product_variation_controller.dart
```

### 1. Models

#### `ProductModel` (`flutter/models/product_model.dart`)

Dart model matching the backend Product structure with JSON serialization.

```dart
class ProductModel {
  int productId;
  String name;
  String? description;
  String priceRange;
  String basePrice;
  String salePrice;
  int? categoryId;
  bool isPopular;
  int stockQuantity;
  DateTime? createdAt;
  int? brandID;
  int? alertStock;
  bool isVisible;
  String? tag;
  List<ProductVariationModel> productVariants;
}
```

**Key Methods:**

- `ProductModel.fromJson(Map<String, dynamic> json)` - Deserialize from API
  response
- `toJson({bool isInsert = false, bool isSerial = false})` - Serialize for API
  requests
- `ProductModel.empty()` - Create empty instance
- `copyWith({...})` - Create copy with modified fields

#### `ProductVariationModel` (`flutter/models/product_variation_model.dart`)

```dart
class ProductVariationModel {
  final int variantId;
  final String sellPrice;
  final String? buyPrice;
  final int productId;
  final String? variantName;
  final String stockQuantity;
  final bool isVisible;
}
```

**Key Methods:**

- `ProductVariationModel.fromJson(Map<String, dynamic> data)` - Deserialize from
  API
- `toJson()` - Serialize to JSON
- `ProductVariationModel.empty()` - Create empty instance

### 2. Controllers

#### `ProductController` (`flutter/controller/product_controller.dart`)

Main controller for product operations using GetX state management.

**State Variables:**

```dart
RxList<ProductModel> popularProducts        // Popular products list
RxList<ProductModel> filteredProducts       // Filtered/searched products
RxList<ProductModel> currentBrandProducts   // Products filtered by brand
RxList<ProductModel> allProducts            // All products (for POS)
Map<int, RxList<ProductModel>> categoryProducts  // Category-based cache
Rx<ProductModel> currentProduct             // Currently selected product
```

**Loading States:**

```dart
final isLoading = false.obs
final isLoadingMore = false.obs
final isSearching = false.obs
```

**Pagination Tracking:**

```dart
final RxInt totalPopularProductsCount = 0.obs
final RxInt fetchedPopularProductsCount = 0.obs
final RxInt currentPopularProductsOffset = 0.obs
```

**Key Methods:**

| Method                                           | Parameters         | Returns                | Description                              |
| ------------------------------------------------ | ------------------ | ---------------------- | ---------------------------------------- |
| `loadPopularProductsLazily()`                    | -                  | `Future<void>`         | Loads first batch of popular products    |
| `searchProducts(query)`                          | String query       | `Future<void>`         | Searches products, filters locally first |
| `loadProductsByCategory(categoryId, {loadMore})` | int, bool          | `Future<void>`         | Loads category products with pagination  |
| `loadProductsByBrand(brandId)`                   | int                | `Future<void>`         | Loads all products for a brand           |
| `loadAllProductsForPOS()`                        | -                  | `Future<void>`         | Loads all visible products for POS       |
| `fetchRequiredProductByProductId(productId)`     | int                | `Future<void>`         | Fetches specific product by ID           |
| `loadMoreProducts(type, {categoryId, brandId})`  | String, int?, int? | `Future<void>`         | Loads next page of products              |
| `refreshData({type, categoryId})`                | String?, int?      | `Future<void>`         | Clears cache and reloads                 |
| `getProductById(productId)`                      | int                | `ProductModel?`        | Gets product from cache                  |
| `getProductsByCategory(categoryId)`              | int                | `RxList<ProductModel>` | Returns observable category products     |
| `hasMoreData(type, {categoryId})`                | String, int?       | bool                   | Checks if more data available            |

#### `ProductVariationController` (`flutter/controller/product_variation_controller.dart`)

Controller for managing product variations and selections.

**State Variables:**

```dart
RxList<ProductVariationModel> allProductVariations  // All variations for current product
Rx<ProductVariationModel> selectedVariationProduct  // Currently selected variation
Rx<String> selectedVariant                          // Selected variant name
Rx<int> itemQuantity                                // Selected quantity
```

**Key Methods:**

| Method                                      | Parameters | Returns                          | Description                          |
| ------------------------------------------- | ---------- | -------------------------------- | ------------------------------------ |
| `fetchProductVariantByProductId(productId)` | int        | `Future<void>`                   | Fetches all variations for a product |
| `fetchProductVariantByVariantId(variantId)` | int        | `Future<ProductVariationModel?>` | Fetches variations via variant ID    |
| `selectVariant(variantName)`                | String     | void                             | Selects a specific variant           |
| `getVariationByName(variantName)`           | String     | `ProductVariationModel?`         | Gets variation by name               |
| `isVariationInStock(variantName)`           | String     | bool                             | Checks if variant has stock          |
| `isVariationVisible(variantName)`           | String     | bool                             | Checks if variant is visible         |
| `getVisibleVariants()`                      | -          | `List<String>`                   | Returns all visible variant names    |
| `getAvailableVariants()`                    | -          | `List<String>`                   | Returns in-stock variant names       |
| `getOutOfStockVariants()`                   | -          | `List<String>`                   | Returns out-of-stock variant names   |
| `hasValidSelectedVariant()`                 | -          | bool                             | Validates current selection          |
| `resetController()`                         | -          | void                             | Resets controller state              |
| `getVariantName(variantId)`                 | int?       | String                           | Gets variant name from ID            |
| `getProductId(variantId)`                   | int?       | int                              | Gets product ID from variant ID      |

---

## API Endpoints

### Base URL

- **Development**: `http://localhost:3000`
- **Production**: Configure based on deployment

### Product Endpoints

#### 1. Get Popular Products Count

**Endpoint:** `GET /api/products/popular/count`

**Description:** Returns the count of all popular products that are visible.

**Request Parameters:** None

**Response:**

```json
{
    "count": 42,
    "status": "success"
}
```

**Response Fields:**

- `count` (integer): Number of popular products
- `status` (string): Status indicator

**Status Codes:**

- `200 OK`: Success
- `500 Internal Server Error`: Database error

**Usage Example:**

```dart
final count = await productRepository.getPopularProductsCount();
```

---

#### 2. Fetch Popular Products

**Endpoint:** `GET /api/products/popular`

**Description:** Fetches popular products with pagination support.

**Query Parameters:**

| Parameter | Type    | Required | Default | Description                  |
| --------- | ------- | -------- | ------- | ---------------------------- |
| `limit`   | integer | No       | 10      | Number of products to return |
| `offset`  | integer | No       | 0       | Number of products to skip   |

**Request Example:**

```
GET /api/products/popular?limit=10&offset=0
```

**Response:**

```json
{
    "products": [
        {
            "product_id": 1,
            "name": "Premium T-Shirt",
            "description": "High quality cotton t-shirt",
            "price_range": "$20-$30",
            "base_price": "25.00",
            "sale_price": "20.00",
            "category_id": 5,
            "ispopular": true,
            "stock_quantity": 150,
            "created_at": "2024-01-15T10:30:00Z",
            "brandID": 3,
            "alert_stock": 10,
            "isVisible": true,
            "tag": "summer,casual"
        }
    ],
    "total_count": 42,
    "fetched_count": 10,
    "offset": 0,
    "has_more": true
}
```

**Response Fields:**

- `products` (array): Array of Product objects
- `total_count` (integer|null): Total count of popular products
- `fetched_count` (integer): Number of products in this response
- `offset` (integer|null): Current offset
- `has_more` (boolean): Whether more products are available

**Status Codes:**

- `200 OK`: Success
- `500 Internal Server Error`: Database error

---

#### 3. Fetch All Products for POS

**Endpoint:** `GET /api/products/pos/all`

**Description:** Fetches all visible products without pagination. Optimized for
POS systems.

**Request Parameters:** None

**Response:**

```json
{
  "products": [...],  // Array of all visible products
  "total_count": 150,
  "fetched_count": 150,
  "offset": null,
  "has_more": false
}
```

**Status Codes:**

- `200 OK`: Success
- `500 Internal Server Error`: Database error

**Note:** This endpoint returns ALL visible products at once. Use with caution
for systems with large product catalogs.

---

#### 4. Search Products

**Endpoint:** `GET /api/products/search`

**Description:** Full-text search on product name and description.

**Query Parameters:**

| Parameter   | Type    | Required | Default | Description             |
| ----------- | ------- | -------- | ------- | ----------------------- |
| `query`     | string  | Yes      | -       | Search term             |
| `page`      | integer | No       | 0       | Page number (0-indexed) |
| `page_size` | integer | No       | 20      | Products per page       |

**Request Example:**

```
GET /api/products/search?query=shirt&page=0&page_size=20
```

**Response:**

```json
{
  "products": [...],
  "total_count": null,
  "fetched_count": 15,
  "offset": 0,
  "has_more": false
}
```

**Search Behavior:**

- Case-insensitive search
- Searches in both `name` and `description` fields
- Uses SQL `LIKE` with `%query%` pattern
- Results prioritize name matches over description matches
- Only returns visible products

**Status Codes:**

- `200 OK`: Success
- `500 Internal Server Error`: Database error

---

#### 5. Fetch Products by Category

**Endpoint:** `GET /api/products/category/{category_id}`

**Description:** Fetches all products in a specific category with pagination.

**Path Parameters:**

| Parameter     | Type    | Description |
| ------------- | ------- | ----------- |
| `category_id` | integer | Category ID |

**Query Parameters:**

| Parameter   | Type    | Required | Default | Description             |
| ----------- | ------- | -------- | ------- | ----------------------- |
| `page`      | integer | No       | 0       | Page number (0-indexed) |
| `page_size` | integer | No       | 20      | Products per page       |

**Request Example:**

```
GET /api/products/category/5?page=0&page_size=20
```

**Response:**

```json
{
  "products": [...],
  "total_count": 45,
  "fetched_count": 20,
  "offset": 0,
  "has_more": true
}
```

**Status Codes:**

- `200 OK`: Success
- `500 Internal Server Error`: Database error

---

#### 6. Fetch Products by Brand

**Endpoint:** `GET /api/products/brand/{brand_id}`

**Description:** Fetches all products for a specific brand.

**Path Parameters:**

| Parameter  | Type    | Description |
| ---------- | ------- | ----------- |
| `brand_id` | integer | Brand ID    |

**Request Example:**

```
GET /api/products/brand/3
```

**Response:**

```json
{
  "products": [...],
  "total_count": 25,
  "fetched_count": 25,
  "offset": null,
  "has_more": false
}
```

**Status Codes:**

- `200 OK`: Success
- `500 Internal Server Error`: Database error

---

#### 7. Fetch Product by ID

**Endpoint:** `GET /api/products/{product_id}`

**Description:** Fetches a single product with all its variations.

**Path Parameters:**

| Parameter    | Type    | Description |
| ------------ | ------- | ----------- |
| `product_id` | integer | Product ID  |

**Request Example:**

```
GET /api/products/123
```

**Response:**

```json
{
    "product": {
        "product_id": 123,
        "name": "Premium T-Shirt",
        "description": "High quality cotton t-shirt",
        "price_range": "$20-$30",
        "base_price": "25.00",
        "sale_price": "20.00",
        "category_id": 5,
        "ispopular": true,
        "stock_quantity": 150,
        "created_at": "2024-01-15T10:30:00Z",
        "brandID": 3,
        "alert_stock": 10,
        "isVisible": true,
        "tag": "summer,casual"
    },
    "product_variants": [
        {
            "variant_id": 456,
            "sell_price": 20.00,
            "buy_price": 12.00,
            "product_id": 123,
            "variant_name": "Medium Red",
            "stock": 50,
            "is_visible": true
        },
        {
            "variant_id": 457,
            "sell_price": 20.00,
            "buy_price": 12.00,
            "product_id": 123,
            "variant_name": "Large Blue",
            "stock": 30,
            "is_visible": true
        }
    ]
}
```

**Status Codes:**

- `200 OK`: Success
- `404 Not Found`: Product doesn't exist
- `500 Internal Server Error`: Database error

---

#### 8. Fetch Product Variations

**Endpoint:** `GET /api/products/{product_id}/variations`

**Description:** Fetches all visible variations for a product.

**Path Parameters:**

| Parameter    | Type    | Description |
| ------------ | ------- | ----------- |
| `product_id` | integer | Product ID  |

**Request Example:**

```
GET /api/products/123/variations
```

**Response:**

```json
[
    {
        "variant_id": 456,
        "sell_price": 20.00,
        "buy_price": 12.00,
        "product_id": 123,
        "variant_name": "Medium Red",
        "stock": 50,
        "is_visible": true
    },
    {
        "variant_id": 457,
        "sell_price": 20.00,
        "buy_price": 12.00,
        "product_id": 123,
        "variant_name": "Large Blue",
        "stock": 30,
        "is_visible": true
    }
]
```

**Status Codes:**

- `200 OK`: Success (returns empty array if no variations)
- `500 Internal Server Error`: Database error

---

#### 9. Get Product Statistics

**Endpoint:** `GET /api/products/stats`

**Description:** Returns aggregate statistics about products.

**Request Parameters:** None

**Response:**

```json
{
    "total_products": 150,
    "popular_products": 42,
    "status": "success"
}
```

**Response Fields:**

- `total_products` (integer|null): Total visible products
- `popular_products` (integer|null): Total popular products
- `status` (string): Status indicator

**Status Codes:**

- `200 OK`: Success

---

### Product Variation Endpoints

#### 10. Fetch Variation by ID

**Endpoint:** `GET /api/variations/{variant_id}`

**Description:** Fetches a single variation by its ID.

**Path Parameters:**

| Parameter    | Type    | Description |
| ------------ | ------- | ----------- |
| `variant_id` | integer | Variant ID  |

**Request Example:**

```
GET /api/variations/456
```

**Response:**

```json
{
    "variant_id": 456,
    "sell_price": 20.00,
    "buy_price": 12.00,
    "product_id": 123,
    "variant_name": "Medium Red",
    "stock": 50,
    "is_visible": true
}
```

**Status Codes:**

- `200 OK`: Success
- `404 Not Found`: Variation doesn't exist
- `500 Internal Server Error`: Database error

---

#### 11. Fetch Related Variations

**Endpoint:** `GET /api/variations/{variant_id}/related`

**Description:** Fetches all variations related to a variant (all variations of
the same product).

**Path Parameters:**

| Parameter    | Type    | Description |
| ------------ | ------- | ----------- |
| `variant_id` | integer | Variant ID  |

**Request Example:**

```
GET /api/variations/456/related
```

**Response:**

```json
[
    {
        "variant_id": 456,
        "sell_price": 20.00,
        "buy_price": 12.00,
        "product_id": 123,
        "variant_name": "Medium Red",
        "stock": 50,
        "is_visible": true
    },
    {
        "variant_id": 457,
        "sell_price": 20.00,
        "buy_price": 12.00,
        "product_id": 123,
        "variant_name": "Large Blue",
        "stock": 30,
        "is_visible": true
    }
]
```

**Behavior:**

1. Looks up the `product_id` from the given `variant_id`
2. Fetches all visible variations for that product
3. Returns all related variations (including the original)

**Status Codes:**

- `200 OK`: Success
- `500 Internal Server Error`: Database error or variant not found

---

#### 12. Check Variant Stock

**Endpoint:** `GET /api/variations/{variant_id}/stock`

**Description:** Checks the current stock level for a specific variant.

**Path Parameters:**

| Parameter    | Type    | Description |
| ------------ | ------- | ----------- |
| `variant_id` | integer | Variant ID  |

**Request Example:**

```
GET /api/variations/456/stock
```

**Response:**

```json
{
    "variant_id": 456,
    "stock": 50,
    "in_stock": true,
    "status": "success"
}
```

**Response Fields:**

- `variant_id` (integer): The queried variant ID
- `stock` (integer): Current stock level
- `in_stock` (boolean): Whether stock is greater than 0
- `status` (string): Status indicator

**Status Codes:**

- `200 OK`: Success
- `500 Internal Server Error`: Database error or variant not found

---

## Data Models

### Database Schema

#### Products Table

```sql
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price_range VARCHAR(50),
    base_price DECIMAL(10,2),
    sale_price DECIMAL(10,2),
    category_id INTEGER REFERENCES categories(category_id),
    ispopular BOOLEAN DEFAULT FALSE,
    stock_quantity INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "brandID" INTEGER REFERENCES brands(brand_id),
    alert_stock INTEGER,
    "isVisible" BOOLEAN DEFAULT FALSE,
    tag TEXT
);
```

#### Product Variants Table

```sql
CREATE TABLE product_variants (
    variant_id SERIAL PRIMARY KEY,
    sell_price DECIMAL(10,2) NOT NULL,
    buy_price DECIMAL(10,2),
    product_id INTEGER REFERENCES products(product_id),
    variant_name VARCHAR(255),
    stock INTEGER DEFAULT 0,
    is_visible BOOLEAN DEFAULT TRUE
);
```

### JSON Response Formats

#### Product Object

```json
{
    "product_id": 123,
    "name": "Product Name",
    "description": "Product description",
    "price_range": "$20-$30",
    "base_price": "25.00",
    "sale_price": "20.00",
    "category_id": 5,
    "ispopular": true,
    "stock_quantity": 150,
    "created_at": "2024-01-15T10:30:00Z",
    "brandID": 3,
    "alert_stock": 10,
    "isVisible": true,
    "tag": "summer,casual"
}
```

#### Product Variation Object

```json
{
    "variant_id": 456,
    "sell_price": 20.00,
    "buy_price": 12.00,
    "product_id": 123,
    "variant_name": "Medium Red",
    "stock": 50,
    "is_visible": true
}
```

#### Product List Response

```json
{
    "products": [/* Array of Product objects */],
    "total_count": 100,
    "fetched_count": 20,
    "offset": 0,
    "has_more": true
}
```

#### Product Detail Response

```json
{
    "product": {/* Product object */},
    "product_variants": [/* Array of ProductVariation objects */]
}
```

---

## Integration Guide

### 1. Backend Setup (Rust)

#### Step 1: Configure Environment

Create `.env` file:

```env
DATABASE_URL=postgresql://user:password@host:port/database
HOST=0.0.0.0
PORT=3000
```

#### Step 2: Run the Server

```bash
cargo run --release
```

The server will start on `http://0.0.0.0:3000`

### 2. Flutter Client Setup

#### Step 1: Create Backend Service

```dart
class BackendService {
  final String baseUrl;
  
  BackendService(this.baseUrl);
  
  Future<http.Response> get(String endpoint, {Map<String, String>? queryParams}) async {
    var uri = Uri.parse('$baseUrl$endpoint');
    if (queryParams != null) {
      uri = uri.replace(queryParameters: queryParams);
    }
    return await http.get(uri);
  }
}
```

#### Step 2: Implement Product Repository

```dart
class ProductRepository {
  final BackendService backend;
  
  ProductRepository(this.backend);
  
  Future<List<ProductModel>> fetchPopularProducts({
    required int limit,
    required int offset,
  }) async {
    final response = await backend.get(
      '/api/products/popular',
      queryParams: {'limit': limit.toString(), 'offset': offset.toString()},
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['products'] as List)
          .map((json) => ProductModel.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load popular products');
    }
  }
  
  // Implement other methods similarly...
}
```

#### Step 3: Initialize in GetX

```dart
void main() {
  final backendService = BackendService('http://localhost:3000');
  final productRepository = ProductRepository(backendService);
  
  Get.put(backendService);
  Get.put(productRepository);
  Get.put(ProductController());
  Get.put(ProductVariationController());
  
  runApp(MyApp());
}
```

#### Step 4: Use in UI

```dart
class ProductListScreen extends StatelessWidget {
  final ProductController controller = Get.find();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value) {
          return CircularProgressIndicator();
        }
        
        return ListView.builder(
          itemCount: controller.popularProducts.length,
          itemBuilder: (context, index) {
            final product = controller.popularProducts[index];
            return ListTile(
              title: Text(product.name),
              subtitle: Text(product.salePrice),
            );
          },
        );
      }),
    );
  }
  
  @override
  void initState() {
    super.initState();
    controller.loadPopularProductsLazily();
  }
}
```

### 3. Common Usage Patterns

#### Loading Popular Products

```dart
await productController.loadPopularProductsLazily();
```

#### Searching Products

```dart
await productController.searchProducts('t-shirt');
```

#### Loading Products by Category

```dart
await productController.loadProductsByCategory(5);
```

#### Loading Product Variations

```dart
await variationController.fetchProductVariantByProductId(123);
```

#### Checking Stock

```dart
final inStock = variationController.isVariationInStock('Medium Red');
```

#### Loading More (Pagination)

```dart
if (productController.hasMoreData('popular')) {
  await productController.loadMoreProducts('popular');
}
```

---

## Error Handling

### Backend Error Responses

All endpoints may return these error status codes:

| Status Code                 | Meaning               | Response Format              |
| --------------------------- | --------------------- | ---------------------------- |
| `200 OK`                    | Success               | JSON response as documented  |
| `404 Not Found`             | Resource not found    | No body or error message     |
| `500 Internal Server Error` | Server/database error | No body (logged server-side) |

### Flutter Error Handling

The controllers use GetX's `TLoader.errorSnackBar` for displaying errors:

```dart
try {
  // API call
} catch (e) {
  TLoader.errorSnackBar(
    title: 'Error',
    message: e.toString()
  );
}
```

### Best Practices

1. **Always check loading states** before performing operations
2. **Handle null/empty cases** in UI
3. **Implement retry logic** for failed requests
4. **Cache data** when appropriate to reduce API calls
5. **Validate variant selection** before adding to cart:

```dart
if (variationController.hasValidSelectedVariant()) {
  // Proceed with add to cart
} else {
  // Show error - no variant selected
}
```

---

## Performance Considerations

### Backend Optimizations

1. **Database Indexing**: Ensure proper indexes on:
   - `product_id`, `category_id`, `brandID`, `ispopular`, `isVisible`
   - `variant_id`, `product_id` in variations table
2. **Query Optimization**: All queries use `COALESCE` for null handling
3. **Pagination**: All list endpoints support pagination
4. **Logging**: Comprehensive logging for debugging

### Frontend Optimizations

1. **Lazy Loading**: Products loaded only when needed
2. **Caching**: Category and brand products cached in memory
3. **Local Filtering**: Search filters locally before API call
4. **Pagination Tracking**: Prevents duplicate data fetches
5. **State Management**: GetX reactive state for efficient updates

### Caching Strategy

```dart
// Check cache before API call
if (categoryProducts.containsKey(categoryId) && 
    categoryDataLoaded[categoryId]!) {
  return categoryProducts[categoryId]!;
}

// Fetch from API and cache
final products = await repository.fetchProductsByCategory(categoryId);
categoryProducts[categoryId] = products.obs;
categoryDataLoaded[categoryId] = true;
```

---

## Testing

### Backend Testing

```bash
# Test popular products endpoint
curl http://localhost:3000/api/products/popular?limit=5&offset=0

# Test search
curl http://localhost:3000/api/products/search?query=shirt

# Test product detail
curl http://localhost:3000/api/products/123

# Test variant stock
curl http://localhost:3000/api/variations/456/stock
```

### Flutter Testing

See `Example/flutter_integration_example.dart` for comprehensive integration
examples.

---

## Migration Notes

When migrating from direct Supabase calls:

1. **Replace Supabase client calls** with `ProductRepository` methods
2. **Update base URL** in `BackendService` initialization
3. **Update response parsing** - responses now wrapped in standard formats
4. **Handle pagination differently** - use `has_more` flag instead of result
   length
5. **Error handling** - status codes instead of Supabase exceptions

Example migration:

```dart
// OLD (Supabase)
final response = await supabase
  .from('products')
  .select()
  .eq('ispopular', true)
  .limit(10);

// NEW (Backend API)
final response = await productRepository.fetchPopularProducts(
  limit: 10,
  offset: 0,
);
```

---

## Appendix

### Complete Endpoint Summary

| Method | Endpoint                       | Purpose                    |
| ------ | ------------------------------ | -------------------------- |
| GET    | `/api/products/popular/count`  | Count popular products     |
| GET    | `/api/products/popular`        | Fetch popular products     |
| GET    | `/api/products/pos/all`        | Fetch all products for POS |
| GET    | `/api/products/search`         | Search products            |
| GET    | `/api/products/stats`          | Get product statistics     |
| GET    | `/api/products/category/:id`   | Fetch products by category |
| GET    | `/api/products/brand/:id`      | Fetch products by brand    |
| GET    | `/api/products/:id`            | Get product by ID          |
| GET    | `/api/products/:id/variations` | Get product variations     |
| GET    | `/api/variations/:id`          | Get variation by ID        |
| GET    | `/api/variations/:id/related`  | Get related variations     |
| GET    | `/api/variations/:id/stock`    | Check variant stock        |

### Version Information

- **Specification Version:** 1.0
- **Last Updated:** 2024
- **Backend Framework:** Rust + Axum
- **Database:** PostgreSQL (Supabase)
- **Client Framework:** Flutter/Dart with GetX

---

**End of Product Module Specification**

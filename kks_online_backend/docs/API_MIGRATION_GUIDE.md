# Product API Migration Guide

## Overview

This document maps the Flutter client-side logic to the new Rust backend API
endpoints.

---

## API Endpoints

### 1. Popular Products

#### **Get Popular Products Count**

- **Endpoint**: `GET /api/products/popular/count`
- **Flutter Method**: `productRepository.getPopularProductsCount()`
- **Response**:

```json
{
  "count": 150,
  "status": "success"
}
```

#### **Fetch Popular Products (Paginated)**

- **Endpoint**: `GET /api/products/popular?limit=10&offset=0`
- **Flutter Method**:
  `productRepository.fetchPopularProducts(limit: 10, offset: 0)`
- **Query Parameters**:
  - `limit` (optional): Number of products to fetch (default: 10)
  - `offset` (optional): Offset for pagination (default: 0)
- **Response**:

```json
{
  "products": [...],
  "total_count": 150,
  "fetched_count": 10,
  "offset": 0,
  "has_more": true
}
```

---

### 2. POS System

#### **Get All Products for POS**

- **Endpoint**: `GET /api/products/pos/all`
- **Flutter Method**: `productRepository.fetchAllProductsForPOS()`
- **Description**: Returns all visible products (no pagination)
- **Response**:

```json
{
  "products": [...],
  "total_count": 500,
  "fetched_count": 500,
  "offset": null,
  "has_more": false
}
```

---

### 3. Category-Based Products

#### **Get Products by Category**

- **Endpoint**: `GET /api/products/category/{category_id}?page=0&page_size=20`
- **Flutter Method**:
  `productRepository.fetchProductsByCategory(categoryId, page: 0, pageSize: 20)`
- **Path Parameters**:
  - `category_id`: Category ID
- **Query Parameters**:
  - `page` (optional): Page number (default: 0)
  - `page_size` (optional): Items per page (default: 20)
- **Response**:

```json
{
  "products": [...],
  "total_count": 45,
  "fetched_count": 20,
  "offset": 0,
  "has_more": true
}
```

---

### 4. Brand-Based Products

#### **Get Products by Brand**

- **Endpoint**: `GET /api/products/brand/{brand_id}`
- **Flutter Method**: `productRepository.fetchProductsByBrand(brandId)`
- **Path Parameters**:
  - `brand_id`: Brand ID
- **Response**:

```json
{
  "products": [...],
  "total_count": 30,
  "fetched_count": 30,
  "offset": null,
  "has_more": false
}
```

---

### 5. Product Search

#### **Search Products**

- **Endpoint**: `GET /api/products/search?query=shirt&page=0&page_size=20`
- **Flutter Method**: `productRepository.searchProducts(query, page: 0)`
- **Query Parameters**:
  - `query` (required): Search query string
  - `page` (optional): Page number (default: 0)
  - `page_size` (optional): Items per page (default: 20)
- **Description**: Searches products by name or description (case-insensitive)
- **Response**:

```json
{
  "products": [...],
  "total_count": null,
  "fetched_count": 15,
  "offset": 0,
  "has_more": true
}
```

---

### 6. Product Details

#### **Get Product by ID**

- **Endpoint**: `GET /api/products/{product_id}`
- **Flutter Method**: `productRepository.fetchProductById(productId)`
- **Path Parameters**:
  - `product_id`: Product ID
- **Response**:

```json
{
  "product": {
    "product_id": 123,
    "name": "Product Name",
    "description": "Product description",
    "price_range": "10.00 - 50.00",
    "base_price": "10.00",
    "sale_price": "10.00",
    "category_id": 5,
    "ispopular": true,
    "stock_quantity": 100,
    "created_at": "2024-01-01T00:00:00",
    "brandID": 10,
    "alert_stock": 10,
    "isVisible": true,
    "tag": "new"
  },
  "product_variants": [...]
}
```

---

### 7. Product Variations

#### **Get Product Variations**

- **Endpoint**: `GET /api/products/{product_id}/variations`
- **Flutter Method**:
  `productRepository.fetchProductVariationsWithID(productId)`
- **Path Parameters**:
  - `product_id`: Product ID
- **Response**:

```json
[
  {
    "variant_id": 1,
    "sell_price": "25.00",
    "buy_price": "15.00",
    "product_id": 123,
    "variant_name": "Small",
    "stock": 50,
    "is_visible": true
  },
  ...
]
```

#### **Get Variation by ID**

- **Endpoint**: `GET /api/variations/{variant_id}`
- **Flutter Method**:
  `productRepository.fetchProductVariationsByVariantId(variantId)` (single)
- **Path Parameters**:
  - `variant_id`: Variant ID
- **Response**:

```json
{
  "variant_id": 1,
  "sell_price": "25.00",
  "buy_price": "15.00",
  "product_id": 123,
  "variant_name": "Small",
  "stock": 50,
  "is_visible": true
}
```

#### **Get Related Variations**

- **Endpoint**: `GET /api/variations/{variant_id}/related`
- **Flutter Method**:
  `productRepository.fetchProductVariationsByVariantId(variantId)` (all)
- **Description**: Gets all variations for the product that contains the given
  variant
- **Response**: Same as "Get Product Variations"

---

### 8. Stock Management

#### **Check Variant Stock**

- **Endpoint**: `GET /api/variations/{variant_id}/stock`
- **Path Parameters**:
  - `variant_id`: Variant ID
- **Response**:

```json
{
  "variant_id": 1,
  "stock": 50,
  "in_stock": true,
  "status": "success"
}
```

---

### 9. Statistics

#### **Get Product Statistics**

- **Endpoint**: `GET /api/products/stats`
- **Response**:

```json
{
  "total_products": 500,
  "popular_products": 150,
  "status": "success"
}
```

---

## Flutter Controller Migration

### Before (Client-Side)

```dart
// Direct Supabase calls in Flutter
final products = await productRepository.fetchPopularProducts(limit: 10, offset: 0);
```

### After (Backend API)

```dart
// HTTP calls to Rust backend
final response = await http.get(
  Uri.parse('$baseUrl/api/products/popular?limit=10&offset=0'),
);
final data = json.decode(response.body);
final products = (data['products'] as List)
    .map((json) => ProductModel.fromJson(json))
    .toList();
```

---

## Data Models

### Product Model

```rust
pub struct Product {
    pub product_id: i32,
    pub name: String,
    pub description: Option<String>,
    pub price_range: String,
    pub base_price: Decimal,
    pub sale_price: Decimal,
    pub category_id: Option<i32>,
    pub ispopular: bool,
    pub stock_quantity: i32,
    pub created_at: Option<NaiveDateTime>,
    pub brand_id: Option<i32>,
    pub alert_stock: Option<i32>,
    pub is_visible: bool,
    pub tag: Option<String>,
}
```

### Product Variation Model

```rust
pub struct ProductVariation {
    pub variant_id: i32,
    pub sell_price: Decimal,
    pub buy_price: Option<Decimal>,
    pub product_id: i32,
    pub variant_name: Option<String>,
    pub stock: i32,
    pub is_visible: bool,
}
```

---

## Database Schema Requirements

### Products Table

```sql
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    name VARCHAR NOT NULL,
    description TEXT,
    price_range VARCHAR NOT NULL,
    base_price DECIMAL NOT NULL,
    sale_price DECIMAL NOT NULL,
    category_id INTEGER REFERENCES categories(category_id),
    ispopular BOOLEAN DEFAULT false,
    stock_quantity INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP,
    "brandID" INTEGER REFERENCES brands(brand_id),
    alert_stock INTEGER,
    "isVisible" BOOLEAN DEFAULT true,
    tag VARCHAR
);

CREATE INDEX idx_products_popular ON products(ispopular) WHERE ispopular = true;
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_brand ON products("brandID");
CREATE INDEX idx_products_visible ON products("isVisible");
```

### Product Variants Table

```sql
CREATE TABLE product_variants (
    variant_id SERIAL PRIMARY KEY,
    sell_price DECIMAL NOT NULL,
    buy_price DECIMAL,
    product_id INTEGER NOT NULL REFERENCES products(product_id),
    variant_name VARCHAR,
    stock INTEGER NOT NULL DEFAULT 0,
    is_visible BOOLEAN DEFAULT true
);

CREATE INDEX idx_variants_product ON product_variants(product_id);
CREATE INDEX idx_variants_visible ON product_variants(is_visible);
```

---

## Error Handling

All endpoints return appropriate HTTP status codes:

- `200 OK`: Success
- `404 NOT FOUND`: Resource not found (e.g., product doesn't exist)
- `500 INTERNAL_SERVER_ERROR`: Database or server error

---

## Next Steps

1. **Update Flutter App**: Replace direct Supabase calls with HTTP requests to
   the backend
2. **Add Authentication**: Implement JWT or session-based auth
3. **Add Product Management**: Create POST/PUT/DELETE endpoints for CRUD
   operations
4. **Add Caching**: Implement Redis for frequently accessed data
5. **Add Rate Limiting**: Protect endpoints from abuse
6. **Add Logging**: Enhanced logging and monitoring

---

## Example Flutter Repository Update

```dart
class ProductRepository {
  final String baseUrl;
  
  ProductRepository(this.baseUrl);

  Future<List<ProductModel>> fetchPopularProducts({
    required int limit,
    required int offset,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/products/popular?limit=$limit&offset=$offset'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['products'] as List)
          .map((json) => ProductModel.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load products');
    }
  }

  Future<int> getPopularProductsCount() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/products/popular/count'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['count'] as int;
    } else {
      throw Exception('Failed to get count');
    }
  }

  // Add more methods for other endpoints...
}
```

# Category Module Specification

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

The Category Module provides a complete system for managing product categories
in the e-commerce and kiosk application. It offers a clean API for retrieving
categories with optional filtering by featured status.

### Key Features

- **Category Management**: Retrieve all categories or filter by featured status
- **Product Count**: Each category includes a product count
- **Statistics**: Get aggregate category statistics
- **Featured Categories**: Special filtering for featured categories
- **Lightweight**: Optimized for quick category listing

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter/Dart Client                      │
│  ┌──────────────┐  ┌──────────────┐                         │
│  │  Category    │  │  Category    │                         │
│  │  Controller  │  │  Repository  │                         │
│  └──────────────┘  └──────────────┘                         │
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
│   └── category.rs        # Category data models and DTOs
├── handlers/
│   └── category_handlers.rs # HTTP request handlers
├── database/
│   └── category_queries.rs  # Database query functions
└── main.rs                 # Router configuration
```

### 1. Models (`src/models/category.rs`)

#### Core Models

##### `Category`

Represents a product category in the system.

```rust
pub struct Category {
    pub category_id: i32,
    pub category_name: String,
    pub is_featured: bool,
    pub created_at: Option<DateTime<Utc>>,
    pub product_count: i32,
}
```

**Field Descriptions:**

- `category_id`: Unique identifier (Primary Key)
- `category_name`: Category display name
- `is_featured`: Whether category should be prominently displayed
- `created_at`: Category creation timestamp
- `product_count`: Number of products in this category

#### Request Models

##### `CategoryQueryParams`

Used for filtering categories.

```rust
pub struct CategoryQueryParams {
    pub featured_only: Option<bool>,
}
```

#### Response Models

##### `CategoryListResponse`

Standard response for endpoints returning multiple categories.

```rust
pub struct CategoryListResponse {
    pub categories: Vec<Category>,
    pub total_count: i64,
    pub status: String,
}
```

**Field Descriptions:**

- `categories`: Array of category objects
- `total_count`: Total number of categories returned
- `status`: Status indicator ("success")

##### `CategoryDetailResponse`

Response for single category.

```rust
pub struct CategoryDetailResponse {
    pub category: Category,
    pub status: String,
}
```

### 2. Database Queries (`src/database/category_queries.rs`)

All database queries are implemented in the `CategoryQueries` struct:

#### Query Methods

| Method                            | Description             | SQL Behavior                    |
| --------------------------------- | ----------------------- | ------------------------------- |
| `get_all_categories()`            | Fetch all categories    | Ordered by `category_name ASC`  |
| `get_featured_categories()`       | Fetch featured only     | `WHERE isFeatured = true`       |
| `get_category_by_id(id)`          | Get single category     | Fetched by `category_id`        |
| `get_categories_count()`          | Total category count    | Count of all categories         |
| `get_featured_categories_count()` | Featured category count | Count where `isFeatured = true` |

### 3. Handlers (`src/handlers/category_handlers.rs`)

HTTP request handlers that process incoming requests and return responses. See
[API Endpoints](#api-endpoints) section for detailed endpoint specifications.

---

## Frontend Components (Flutter/Dart)

### File Structure

```
flutter/
├── models/
│   └── category_model.dart
└── controller/
    └── category_controller.dart
```

### 1. Models

#### `CategoryModel` (`flutter/models/category_model.dart`)

Dart model matching the backend Category structure with JSON serialization.

```dart
class CategoryModel {
  int categoryId;
  String categoryName;
  bool isFeatured;
  DateTime? createdAt;
  final int productCount;
}
```

**Key Methods:**

- `CategoryModel.fromJson(Map<String, dynamic> json)` - Deserialize from API
  response
- `toJson({bool isInsert = false})` - Serialize for API requests
- `CategoryModel.empty()` - Create empty instance
- `copyWith({...})` - Create copy with modified fields

### 2. Controllers

#### `CategoryController` (`flutter/controller/category_controller.dart`)

Main controller for category operations using GetX state management.

**State Variables:**

```dart
final isLoading = false.obs
final RxList<CategoryModel> allCategories
final _selectedCategoryId = Rx<int?>(null)
final RxList<ProductModel> _filteredProducts
```

**Key Methods:**

| Method                     | Returns        | Description                             |
| -------------------------- | -------------- | --------------------------------------- |
| `fetchCategories()`        | `Future<void>` | Loads all categories from backend       |
| `selectCategory(id)`       | `void`         | Selects category and filters products   |
| `clearCategorySelection()` | `void`         | Clears selection and shows all products |
| `setProducts(products)`    | `void`         | Sets product list for filtering         |

---

## API Endpoints

### Base URL

- **Development**: `http://localhost:3000`
- **Production**: Configure based on deployment

### Category Endpoints

#### 1. Get All Categories

**Endpoint:** `GET /api/categories/all`

**Description:** Fetches all categories or only featured categories based on
query parameter.

**Query Parameters:**

| Parameter       | Type    | Required | Default | Description                               |
| --------------- | ------- | -------- | ------- | ----------------------------------------- |
| `featured_only` | boolean | No       | false   | If true, returns only featured categories |

**Request Examples:**

```
GET /api/categories/all
GET /api/categories/all?featured_only=true
```

**Response:**

```json
{
    "categories": [
        {
            "category_id": 1,
            "category_name": "Electronics",
            "isFeatured": true,
            "created_at": "2024-01-15T10:30:00Z",
            "product_count": 150
        },
        {
            "category_id": 2,
            "category_name": "Clothing",
            "isFeatured": false,
            "created_at": "2024-01-16T14:20:00Z",
            "product_count": 87
        }
    ],
    "total_count": 2,
    "status": "success"
}
```

**Response Fields:**

- `categories` (array): Array of Category objects
- `total_count` (integer): Number of categories returned
- `status` (string): Status indicator

**Status Codes:**

- `200 OK`: Success
- `500 Internal Server Error`: Database error

---

#### 2. Get Category by ID

**Endpoint:** `GET /api/categories/:category_id`

**Description:** Fetches a single category by its ID.

**Path Parameters:**

| Parameter     | Type    | Description |
| ------------- | ------- | ----------- |
| `category_id` | integer | Category ID |

**Request Example:**

```
GET /api/categories/5
```

**Response:**

```json
{
    "category": {
        "category_id": 5,
        "category_name": "Electronics",
        "isFeatured": true,
        "created_at": "2024-01-15T10:30:00Z",
        "product_count": 150
    },
    "status": "success"
}
```

**Status Codes:**

- `200 OK`: Success
- `404 Not Found`: Category doesn't exist
- `500 Internal Server Error`: Database error

---

#### 3. Get Category Statistics

**Endpoint:** `GET /api/categories/stats`

**Description:** Returns aggregate statistics about categories.

**Request Parameters:** None

**Response:**

```json
{
    "total_categories": 15,
    "featured_categories": 5,
    "status": "success"
}
```

**Response Fields:**

- `total_categories` (integer|null): Total number of categories
- `featured_categories` (integer|null): Number of featured categories
- `status` (string): Status indicator

**Status Codes:**

- `200 OK`: Success

---

## Data Models

### Database Schema

#### Categories Table

```sql
CREATE TABLE categories (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(255) NOT NULL,
    "isFeatured" BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    product_count INTEGER DEFAULT 0
);
```

### JSON Response Formats

#### Category Object

```json
{
    "category_id": 5,
    "category_name": "Electronics",
    "isFeatured": true,
    "created_at": "2024-01-15T10:30:00Z",
    "product_count": 150
}
```

#### Category List Response

```json
{
    "categories": [/* Array of Category objects */],
    "total_count": 15,
    "status": "success"
}
```

---

## Integration Guide

### 1. Backend Setup (Rust)

#### Step 1: Configure Environment

Create `.env` file (if not exists):

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

#### Step 2: Implement Category Repository

```dart
class CategoryRepository {
  final BackendService backend;
  
  CategoryRepository(this.backend);
  
  Future<List<CategoryModel>> getAllCategories({bool featuredOnly = false}) async {
    final response = await backend.get(
      '/api/categories/all',
      queryParams: featuredOnly ? {'featured_only': 'true'} : null,
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['categories'] as List)
          .map((json) => CategoryModel.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load categories');
    }
  }
}
```

#### Step 3: Use in Controller

```dart
class CategoryController extends GetxController {
  final CategoryRepository repository = Get.find();
  final RxList<CategoryModel> allCategories = <CategoryModel>[].obs;
  final isLoading = false.obs;

  Future<void> fetchCategories() async {
    try {
      isLoading.value = true;
      final categories = await repository.getAllCategories();
      allCategories.assignAll(categories);
    } catch (e) {
      print('Error: $e');
    } finally {
      isLoading.value = false;
    }
  }
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
  await fetchCategories();
} catch (e) {
  TLoader.errorSnackBar(
    title: 'Oh Snap',
    message: e.toString()
  );
}
```

---

## Testing

### Backend Testing

```bash
# Test all categories endpoint
curl http://localhost:3000/api/categories/all

# Test featured categories only
curl http://localhost:3000/api/categories/all?featured_only=true

# Test category by ID
curl http://localhost:3000/api/categories/5

# Test category statistics
curl http://localhost:3000/api/categories/stats
```

### Expected Responses

```bash
# All categories
{"categories":[...],"total_count":15,"status":"success"}

# Category by ID
{"category":{...},"status":"success"}

# Statistics
{"total_categories":15,"featured_categories":5,"status":"success"}
```

---

## Migration Notes

When migrating from direct Supabase calls:

1. **Replace Supabase client calls** with `CategoryRepository` methods
2. **Update base URL** in `BackendService` initialization
3. **Update response parsing** - responses now wrapped in standard formats
4. **Error handling** - status codes instead of Supabase exceptions

Example migration:

```dart
// OLD (Supabase)
final response = await supabase
  .from('categories')
  .select()
  .order('category_name');

// NEW (Backend API)
final response = await categoryRepository.getAllCategories();
```

---

## Appendix

### Complete Endpoint Summary

| Method | Endpoint                | Purpose                 |
| ------ | ----------------------- | ----------------------- |
| GET    | `/api/categories/all`   | Get all categories      |
| GET    | `/api/categories/stats` | Get category statistics |
| GET    | `/api/categories/:id`   | Get category by ID      |

### Version Information

- **Specification Version:** 1.0
- **Last Updated:** 2024
- **Backend Framework:** Rust + Axum
- **Database:** PostgreSQL (Supabase)
- **Client Framework:** Flutter/Dart with GetX

---

**End of Category Module Specification**

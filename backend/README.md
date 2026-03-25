# KKS Online Backend

A high-performance Rust backend for e-commerce and kiosk applications with
Supabase integration.

## Features

- **Product Management API**: Complete product catalog with variations, search,
  and filtering
- **Shopping Cart System**: Full cart management for customers and kiosk
  sessions
- **Secure Checkout**: Race-condition-safe checkout with inventory management
- **POS System Support**: Optimized endpoints for point-of-sale operations
- **Supabase Integration**: Direct PostgreSQL connection via Supabase
- **High Performance**: Built with Axum and async Rust for maximum throughput
- **Type-Safe**: Strongly typed models and database queries with SQLx
- **CORS Support**: Ready for Flutter app integration

## Architecture

```
src/
├── handlers/          # HTTP route handlers
│   ├── mod.rs        # Test endpoints (orders, button press)
│   └── product_handlers.rs   # Product API endpoints
├── database/          # Database layer
│   ├── mod.rs        # Database connection pool
│   └── product_queries.rs    # Product queries
├── models/            # Data models
│   ├── order.rs      # Order model
│   └── product.rs    # Product & ProductVariation models
├── config/            # Configuration management
└── main.rs           # Application entry point with routes
```

## Quick Start

1. **Setup Environment**
   ```bash
   cp .env.example .env
   ```

2. **Configure Supabase**
   - Get your Supabase connection string from: Project Settings → Database →
     Connection string
   - Update `DATABASE_URL` in `.env` file
   - Make sure your orders table exists in Supabase

3. **Run the Application**
   ```bash
   cargo run
   ```

4. **Test the Endpoints**
   ```bash
   # Test connection
   curl http://localhost:3000/

   # Get popular products
   curl http://localhost:3000/api/products/popular?limit=10&offset=0

   # Search products
   curl http://localhost:3000/api/products/search?query=shirt
   ```

## API Endpoints

### 🛒 Cart Endpoints

- `GET /api/cart/:customer_id` - Get cart items for customer
- `POST /api/cart/:customer_id/add` - Add item to cart
- `PUT /api/cart/item/:cart_id` - Update cart item quantity
- `DELETE /api/cart/item/:cart_id` - Remove cart item
- `DELETE /api/cart/:customer_id/clear` - Clear entire cart
- `GET /api/cart/:customer_id/validate` - Validate cart stock availability

### 🖥️ Kiosk Cart Endpoints

- `GET /api/cart/kiosk/:session_id` - Get kiosk cart items
- `POST /api/cart/kiosk/add` - Add item to kiosk cart
- `PUT /api/cart/kiosk/item/:kiosk_id` - Update kiosk cart item
- `DELETE /api/cart/kiosk/item/:kiosk_id` - Remove kiosk cart item
- `DELETE /api/cart/kiosk/:session_id/clear` - Clear kiosk cart

### 💳 Checkout Endpoint

- `POST /api/checkout` - **Secure checkout with race condition handling**
  - Supports cart checkout and direct "Buy Now"
  - Idempotency for duplicate prevention
  - Atomic inventory reservation
  - Server-side price validation
  - Multiple payment methods (COD, Pickup, etc.)
  - Works concurrently with Supabase Edge Function

**📖 See [CHECKOUT_MODULE.md](CHECKOUT_MODULE.md) for complete checkout
documentation.**

### 📦 Product Endpoints

- `GET /api/products/popular/count` - Get count of popular products
- `GET /api/products/popular?limit=10&offset=0` - Fetch popular products
  (paginated)
- `GET /api/products/pos/all` - Fetch all products for POS system
- `GET /api/products/search?query=...` - Search products by name/description
- `GET /api/products/stats` - Get product statistics
- `GET /api/products/category/:id` - Fetch products by category (paginated)
- `GET /api/products/brand/:id` - Fetch products by brand
- `GET /api/products/:id` - Get product details with variations
- `GET /api/products/:id/variations` - Get all variations for a product

### Product Variation Endpoints

- `GET /api/variations/:id` - Get variation by ID
- `GET /api/variations/:id/related` - Get all related variations
- `GET /api/variations/:id/stock` - Check variant stock availability

### Test Endpoints

- `GET /` - Welcome message
- `POST /test-button` - Test button press
- `GET /test-db` - Test database connection
- `GET /orders` - Fetch orders from Supabase

**📖 See [API_MIGRATION_GUIDE.md](API_MIGRATION_GUIDE.md) for complete API
documentation and Flutter integration examples.**

## Flutter Integration

### Quick Example

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

// Fetch popular products
final response = await http.get(
  Uri.parse('http://localhost:3000/api/products/popular?limit=10&offset=0'),
);

if (response.statusCode == 200) {
  final data = json.decode(response.body);
  final products = (data['products'] as List)
      .map((json) => ProductModel.fromJson(json))
      .toList();
}

// Search products
final searchResponse = await http.get(
  Uri.parse('http://localhost:3000/api/products/search?query=shirt'),
);
```

### Migration from Direct Supabase

**Before (Direct Supabase):**

```dart
final products = await supabase
  .from('products')
  .select()
  .eq('ispopular', true)
  .limit(10);
```

**After (Backend API):**

```dart
final response = await http.get(
  Uri.parse('$backendUrl/api/products/popular?limit=10&offset=0'),
);
final data = json.decode(response.body);
final products = data['products'];
```

See [API_MIGRATION_GUIDE.md](API_MIGRATION_GUIDE.md) for complete migration
guide.

## Environment Variables

| Variable       | Description                | Required | Default   |
| -------------- | -------------------------- | -------- | --------- |
| `DATABASE_URL` | Supabase connection string | Yes      | -         |
| `HOST`         | Server host                | No       | `0.0.0.0` |
| `PORT`         | Server port                | No       | `3000`    |

## Development

### Running the Application

```bash
cargo run
```

### Building for Production

```bash
cargo build --release
```

## Console Output

When you run the application, you'll see helpful debug messages:

```
✅ Configuration loaded successfully
✅ Database connected successfully
🚀 Server starting on 0.0.0.0:3000
📝 Test endpoints:
   GET  /            - Welcome message
   POST /test-button - Test button press
   GET  /test-db     - Test database connection
   GET  /orders      - Fetch orders from Supabase
```

When you call endpoints, you'll see logs like:

- `🚀 Button pressed! Test function called successfully!`
- `📦 Fetching orders from Supabase...`
- `✅ Successfully fetched 5 orders`

## Database Schema

The backend expects the following tables in your Supabase database:

### Products Table

```sql
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    name VARCHAR NOT NULL,
    description TEXT,
    price_range VARCHAR NOT NULL,
    base_price DECIMAL NOT NULL,
    sale_price DECIMAL NOT NULL,
    category_id INTEGER,
    ispopular BOOLEAN DEFAULT false,
    stock_quantity INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP,
    "brandID" INTEGER,
    alert_stock INTEGER,
    "isVisible" BOOLEAN DEFAULT true,
    tag VARCHAR
);
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
```

## Performance Features

- **Connection Pooling**: Efficient PostgreSQL connection management
- **Async Operations**: Non-blocking I/O for high concurrency
- **Optimized Queries**: Indexed database queries for fast lookups
- **Pagination Support**: Limit data transfer with offset-based pagination
- **Smart Filtering**: Server-side search and filtering

## Documentation

### Module Documentation

- 📦 [Product Module](PRODUCT_MODULE.md) - Product catalog and variations
- 📁 [Category Module](CATEGORY_MODULE.md) - Category management
- 🛒 [Cart Module](CART_MODULE.md) - Shopping cart functionality
- 💳 [Checkout Module](CHECKOUT_MODULE.md) - **Secure checkout with race
  condition handling**
- 🚀 [Quick Start Guide](QUICK_START.md) - Get started quickly
- 📋 [API Migration Guide](API_MIGRATION_GUIDE.md) - Migrate from Supabase
  direct
- 📝 [Implementation Summary](IMPLEMENTATION_SUMMARY.md) - Architecture overview
- ✅ [Checkout Implementation](CHECKOUT_IMPLEMENTATION_SUMMARY.md) - Checkout
  details

### Checkout Features 🔥

The checkout module includes:

- **Race Condition Prevention**: Multiple users can checkout simultaneously
  without overselling
- **Idempotency**: Duplicate order prevention using SHA-256 keys
- **Atomic Operations**: Database-level locking for inventory
- **Security**: Server-side price validation and audit logging
- **Dual App Support**: Works with both Edge Function and Rust backend
- **Payment Ready**: Extensible payment method framework

See [CHECKOUT_MODULE.md](CHECKOUT_MODULE.md) for complete details.

## Next Steps

### Completed ✅

- ✅ Product catalog API with variations
- ✅ Search and filtering
- ✅ Category and brand-based queries
- ✅ Shopping cart system
- ✅ **Secure checkout with race condition handling**
- ✅ POS system support
- ✅ Pagination
- ✅ Stock validation

### TODO

- [ ] Authentication & Authorization (JWT/Session)
- [ ] Product CRUD operations (Create, Update, Delete)
- [ ] Order management endpoints
- [ ] Payment gateway integration (Stripe, JazzCash)
- [ ] Refund logic for failed orders
- [ ] Redis caching layer
- [ ] Rate limiting
- [ ] API documentation (Swagger/OpenAPI)
- [ ] Unit and integration tests

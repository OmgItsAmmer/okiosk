# Quick Start Guide - Product Backend

## 🚀 Start the Backend

```bash
# 1. Make sure .env is configured with DATABASE_URL
cp .env.example .env

# 2. Run the backend
cargo run
```

Server will start on `http://localhost:3000` (or your configured HOST:PORT)

---

## 🧪 Test the API

### Using cURL

```bash
# Get popular products
curl "http://localhost:3000/api/products/popular?limit=10&offset=0"

# Search products
curl "http://localhost:3000/api/products/search?query=shirt"

# Get product by ID
curl "http://localhost:3000/api/products/1"

# Check stock
curl "http://localhost:3000/api/variations/5/stock"

# Get statistics
curl "http://localhost:3000/api/products/stats"
```

### Using a REST Client (Postman/Insomnia)

Import these endpoints:

```
GET  http://localhost:3000/api/products/popular?limit=10&offset=0
GET  http://localhost:3000/api/products/pos/all
GET  http://localhost:3000/api/products/search?query=shirt&page=0
GET  http://localhost:3000/api/products/category/5?page=0&page_size=20
GET  http://localhost:3000/api/products/brand/3
GET  http://localhost:3000/api/products/1
GET  http://localhost:3000/api/products/1/variations
GET  http://localhost:3000/api/variations/10
GET  http://localhost:3000/api/variations/10/related
GET  http://localhost:3000/api/variations/10/stock
GET  http://localhost:3000/api/products/stats
GET  http://localhost:3000/api/products/popular/count
```

---

## 📱 Flutter Integration

### 1. Add HTTP Package

```yaml
# pubspec.yaml
dependencies:
  http: ^1.1.0
```

### 2. Create Backend Service

```dart
class BackendService {
  final String baseUrl = 'http://localhost:3000'; // Change for production
  
  Future<http.Response> get(String endpoint) async {
    return await http.get(Uri.parse('$baseUrl$endpoint'));
  }
}
```

### 3. Update Product Repository

```dart
class ProductRepository {
  final BackendService backend;
  
  Future<List<ProductModel>> fetchPopularProducts({
    required int limit,
    required int offset,
  }) async {
    final response = await backend.get(
      '/api/products/popular?limit=$limit&offset=$offset'
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['products'] as List)
          .map((json) => ProductModel.fromJson(json))
          .toList();
    }
    throw Exception('Failed to load products');
  }
}
```

### 4. Your Controllers Stay the Same!

Your existing `ProductController` and `ProductVariationController` can remain
mostly unchanged - just update the repository they use.

---

## 📊 Database Setup

### Required Tables

Run these SQL commands in your Supabase SQL Editor:

```sql
-- Products table
CREATE TABLE IF NOT EXISTS products (
    product_id SERIAL PRIMARY KEY,
    name VARCHAR NOT NULL,
    description TEXT,
    price_range VARCHAR NOT NULL,
    base_price DECIMAL NOT NULL,
    sale_price DECIMAL NOT NULL,
    category_id INTEGER,
    ispopular BOOLEAN DEFAULT false,
    stock_quantity INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    "brandID" INTEGER,
    alert_stock INTEGER,
    "isVisible" BOOLEAN DEFAULT true,
    tag VARCHAR
);

-- Product variants table
CREATE TABLE IF NOT EXISTS product_variants (
    variant_id SERIAL PRIMARY KEY,
    sell_price DECIMAL NOT NULL,
    buy_price DECIMAL,
    product_id INTEGER NOT NULL REFERENCES products(product_id),
    variant_name VARCHAR,
    stock INTEGER NOT NULL DEFAULT 0,
    is_visible BOOLEAN DEFAULT true
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_products_popular ON products(ispopular);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_visible ON products("isVisible");
CREATE INDEX IF NOT EXISTS idx_variants_product ON product_variants(product_id);
```

---

## 🔍 API Response Examples

### Popular Products

```json
{
  "products": [
    {
      "product_id": 1,
      "name": "Product Name",
      "description": "Description",
      "price_range": "10.00 - 50.00",
      "base_price": "10.00",
      "sale_price": "10.00",
      "category_id": 5,
      "ispopular": true,
      "stock_quantity": 100,
      "isVisible": true
    }
  ],
  "total_count": 150,
  "fetched_count": 10,
  "offset": 0,
  "has_more": true
}
```

### Product Details

```json
{
  "product": {/* product object */},
  "product_variants": [
    {
      "variant_id": 1,
      "sell_price": "25.00",
      "buy_price": "15.00",
      "product_id": 1,
      "variant_name": "Small",
      "stock": 50,
      "is_visible": true
    }
  ]
}
```

### Stock Check

```json
{
  "variant_id": 1,
  "stock": 50,
  "in_stock": true,
  "status": "success"
}
```

---

## 🛠️ Troubleshooting

### Backend won't start

- ✅ Check `.env` file exists with `DATABASE_URL`
- ✅ Verify Supabase connection string is correct
- ✅ Run `cargo check` to see compilation errors

### API returns 500 error

- ✅ Check if tables exist in database
- ✅ Verify column names match (especially `"brandID"` and `"isVisible"`)
- ✅ Check backend console for error messages

### Flutter can't connect

- ✅ For Android emulator, use `http://10.0.2.2:3000`
- ✅ For iOS simulator, use `http://localhost:3000`
- ✅ For physical device, use your computer's IP (e.g.,
  `http://192.168.1.100:3000`)
- ✅ Make sure CORS is enabled (it is by default)

### Empty results

- ✅ Check if products have `"isVisible" = true` in database
- ✅ Verify products exist in the database
- ✅ Check filter conditions (ispopular, category_id, etc.)

---

## 📚 Next Steps

1. ✅ Backend is running
2. ✅ Database tables created
3. ✅ API tested with curl/Postman
4. ⏭️ Update Flutter ProductRepository
5. ⏭️ Test from Flutter app
6. ⏭️ Add authentication
7. ⏭️ Deploy to production

---

## 📖 Full Documentation

- **API Reference**: See `API_MIGRATION_GUIDE.md`
- **Implementation Details**: See `IMPLEMENTATION_SUMMARY.md`
- **Flutter Integration**: See `Example/flutter_integration_example.dart`
- **Project Overview**: See `README.md`

---

## 🆘 Need Help?

Check the console output when running `cargo run` - it shows:

- ✅ Database connection status
- 🚀 Server startup confirmation
- 📝 Complete list of available endpoints
- 🔍 Request logs when you call endpoints

Example output:

```
✅ Configuration loaded successfully
✅ Database connected successfully
🚀 Server starting on 0.0.0.0:3000

📝 Available Endpoints:

🛍️ Product Endpoints:
   GET  /api/products/popular?limit=10&offset=0
   GET  /api/products/search?query=...
   ...
```

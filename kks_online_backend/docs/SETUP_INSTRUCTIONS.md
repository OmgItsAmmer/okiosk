# KKS Online Rust Backend - Setup Instructions

## Quick Start

### 1. Prerequisites
- **Rust** (1.70 or higher): Install from https://rustup.rs/
- **PostgreSQL/Supabase**: Database connection
- **Git**: For cloning and version control

### 2. Environment Configuration

Create a `.env` file in the `kks_online_backend` directory:

```env
# Required: Supabase/PostgreSQL connection string
DATABASE_URL=postgresql://user:password@host:port/database

# Optional: Server configuration (defaults shown)
PORT=3000
HOST=0.0.0.0

# Optional: Only needed for AI features
# You can set a dummy value if not using AI features
GEMINI_API_KEY=your_api_key_here
```

**Getting your DATABASE_URL from Supabase:**
1. Go to your Supabase project dashboard
2. Navigate to Settings → Database
3. Copy the "Connection string" under "Connection pooling"
4. Replace `[YOUR-PASSWORD]` with your actual database password

### 3. Build and Run

```bash
# Navigate to backend directory
cd kks_online_backend

# Build the project (first time may take a few minutes)
cargo build --release

# Run the server
cargo run --release
```

Or for development with auto-reload:
```bash
# Install cargo-watch (one time)
cargo install cargo-watch

# Run with auto-reload
cargo watch -x run
```

### 4. Verify Installation

Once the server starts, you should see:
```
✅ Configuration loaded successfully
✅ Database connected successfully
✅ AI Service initialized successfully
🚀 Server starting on 0.0.0.0:3000
```

Test the API:
```bash
# Test root endpoint
curl http://localhost:3000/

# Test products endpoint
curl http://localhost:3000/api/v1/products/popular
```

## API Endpoints

### Frontend-Compatible Endpoints (Express format)

All endpoints return JSON with this structure:
```json
{
  "success": true,
  "data": { /* response data */ }
}
```

Or for paginated responses:
```json
{
  "success": true,
  "data": [ /* items */ ],
  "pagination": {
    "page": 1,
    "pageSize": 20,
    "total": 100,
    "totalPages": 5
  }
}
```

#### Products
- `GET /api/v1/products` - List products with filters
  - Query params: `q`, `categoryId`, `brandId`, `minPrice`, `maxPrice`, `isPopular`, `tag`, `sortBy`, `sortOrder`, `page`, `pageSize`
- `GET /api/v1/products/popular` - Popular products
  - Query params: `page`, `pageSize`
- `GET /api/v1/products/search/suggestions` - Search suggestions
  - Query params: `q` (query string)
- `GET /api/v1/products/category/:id` - Products by category
  - Query params: `page`, `pageSize`
- `GET /api/v1/products/brand/:id` - Products by brand
  - Query params: `limit`
- `GET /api/v1/products/:id` - Product details with variants
- `GET /api/v1/products/:id/variants` - Product variants only

#### Cart (Available but not connected to frontend)
- `GET /api/cart/:customer_id` - Get cart
- `POST /api/cart/:customer_id/add` - Add to cart
- `PUT /api/cart/item/:cart_id` - Update quantity
- `DELETE /api/cart/item/:cart_id` - Remove item
- `DELETE /api/cart/:customer_id/clear` - Clear cart

#### Checkout (Available but not connected to frontend)
- `POST /api/checkout` - Process checkout

#### Categories
- `GET /api/categories/all` - List all categories
  - Query params: `featured_only=true` (optional)

## Database Schema Requirements

Your PostgreSQL/Supabase database should have these tables:

### products
- `product_id` (PRIMARY KEY, integer)
- `name` (text)
- `description` (text, nullable)
- `price_range` (text)
- `base_price` (text)
- `sale_price` (text)
- `category_id` (integer, nullable)
- `brandID` (integer, nullable)
- `ispopular` (boolean)
- `stock_quantity` (integer)
- `alert_stock` (integer, nullable)
- `isVisible` (boolean)
- `tag` (text, nullable)
- `created_at` (timestamp with time zone)

### product_variants
- `variant_id` (PRIMARY KEY, integer)
- `product_id` (integer, FOREIGN KEY → products)
- `variant_name` (text)
- `buy_price` (numeric)
- `sell_price` (numeric)
- `stock` (integer)
- `is_visible` (boolean)

### categories
- `category_id` (PRIMARY KEY, integer)
- `category_name` (text)
- `description` (text, nullable)
- `is_featured` (boolean, nullable)

### cart
- `cart_id` (PRIMARY KEY, integer)
- `customer_id` (integer)
- `variant_id` (integer, FOREIGN KEY → product_variants)
- `quantity` (integer)
- `created_at` (timestamp with time zone)

## Troubleshooting

### Error: "DATABASE_URL must be set"
**Solution**: Create a `.env` file with your database connection string.

### Error: "GEMINI_API_KEY must be set"
**Solution**: Either:
1. Add `GEMINI_API_KEY=dummy_key` to `.env` (if not using AI features)
2. Or modify `src/config/mod.rs` to make it optional

### Error: "Connection refused" or database errors
**Solutions**:
- Verify your `DATABASE_URL` is correct
- Check your Supabase database is active
- Ensure you're using the correct password
- Try using the "Connection pooling" URL instead of "Direct connection"
- Check if your IP is allowed in Supabase settings

### Port 3000 already in use
**Solution**: Either:
1. Change `PORT=3001` in `.env` file
2. Or stop the process using port 3000:
   ```bash
   # Windows
   netstat -ano | findstr :3000
   taskkill /PID <pid> /F
   
   # Linux/Mac
   lsof -ti:3000 | xargs kill -9
   ```

### Slow compilation
**Note**: First build takes longer as it downloads and compiles dependencies. Subsequent builds are much faster.

**Speed up**:
```bash
# Use cargo check instead of build for faster validation
cargo check

# Or use release mode only when needed
cargo build  # debug mode (faster compilation)
```

### CORS errors in frontend
**Note**: CORS is already configured to allow all origins in development. If you still see errors:
1. Ensure backend is running on port 3000
2. Check frontend is pointing to correct URL
3. Verify no proxy is interfering

## Development Tips

### Hot Reload
```bash
cargo watch -x run
```

### Run with Logs
```bash
# Set log level
RUST_LOG=debug cargo run

# Or in .env file
RUST_LOG=kks_online_backend=debug,tower_http=debug
```

### Format Code
```bash
cargo fmt
```

### Run Linter
```bash
cargo clippy
```

### Run Tests
```bash
cargo test
```

## Production Deployment

### 1. Build for Production
```bash
cargo build --release
```

### 2. Binary Location
The compiled binary will be at:
```
target/release/kks_online_backend
```

### 3. Run Production Server
```bash
# Set production environment variables
export DATABASE_URL="your_production_db_url"
export PORT=3000
export HOST=0.0.0.0

# Run the binary
./target/release/kks_online_backend
```

### 4. Recommended: Use Process Manager
```bash
# Using systemd (Linux)
sudo systemctl start kks-backend

# Or PM2 (if available)
pm2 start target/release/kks_online_backend --name kks-backend
```

### 5. Reverse Proxy (nginx example)
```nginx
server {
    listen 80;
    server_name api.yourdomain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

## Performance Tuning

### Database Connection Pool
Adjust in code if needed (default is usually fine):
```rust
// src/database/mod.rs
.max_connections(10)
.min_connections(2)
```

### Increase File Limits (Linux)
```bash
ulimit -n 65535
```

## Additional Features

### AI Features (Optional)
To enable AI-powered features:
1. Get a Gemini API key from Google AI Studio
2. Add it to `.env`: `GEMINI_API_KEY=your_actual_key`
3. AI endpoints will be available at `/api/ai/*`

**Note**: AI features are not connected to the frontend by default.

## Getting Help

1. **Check Logs**: Terminal running `cargo run` shows detailed logs
2. **Database Issues**: Verify with `psql` or Supabase dashboard
3. **API Testing**: Use `curl`, Postman, or browser DevTools
4. **Rust Errors**: Run `cargo check` for detailed error messages

## Example Requests

### Get Popular Products
```bash
curl http://localhost:3000/api/v1/products/popular?page=1&pageSize=10
```

### Search Products
```bash
curl "http://localhost:3000/api/v1/products?q=mattress&page=1&pageSize=20"
```

### Get Product by ID
```bash
curl http://localhost:3000/api/v1/products/1
```

### Filter by Category and Price
```bash
curl "http://localhost:3000/api/v1/products?categoryId=1&minPrice=100&maxPrice=500&sortBy=price&sortOrder=asc"
```

### Get Search Suggestions
```bash
curl "http://localhost:3000/api/v1/products/search/suggestions?q=mat"
```

## Project Structure

```
kks_online_backend/
├── src/
│   ├── main.rs              # Entry point, routes
│   ├── config/              # Configuration
│   ├── database/            # Database queries
│   ├── handlers/            # Request handlers
│   ├── models/              # Data models
│   └── services/            # Business logic
├── Cargo.toml               # Dependencies
├── .env                     # Environment variables (create this)
└── .env.example             # Template
```

## Summary

This Rust backend provides:
- ✅ High performance
- ✅ Type safety
- ✅ Memory efficiency
- ✅ Express API compatibility
- ✅ Async/await support
- ✅ Built-in logging
- ✅ CORS configured
- ✅ Connection pooling

It's ready to serve your React frontend with improved performance and reliability!

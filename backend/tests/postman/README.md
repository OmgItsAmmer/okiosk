# KKS Online Products API - Postman Collection

This directory contains Postman collections for testing the KKS Online Backend Product APIs.

## Files

- `KKS_Products_API.postman_collection.json` - Complete Postman collection with all product endpoints

## Setup Instructions

### 1. Import Collection into Postman

1. Open Postman
2. Click **Import** button (top left)
3. Select **File** tab
4. Choose `KKS_Products_API.postman_collection.json`
5. Click **Import**

### 2. Configure Environment Variables

The collection uses a `base_url` variable. You can either:

**Option A: Use Collection Variable (Recommended)**
- The collection already has a default `base_url` variable set to `http://localhost:3000`
- You can modify it by:
  1. Right-click on the collection
  2. Select **Edit**
  3. Go to **Variables** tab
  4. Update `base_url` value if needed

**Option B: Create Postman Environment**
1. Click **Environments** in the left sidebar
2. Click **+** to create new environment
3. Name it "KKS Local" or "KKS Development"
4. Add variable:
   - Variable: `base_url`
   - Initial Value: `http://localhost:3000`
   - Current Value: `http://localhost:3000`
5. Save and select this environment from the dropdown

### 3. Start the Backend Server

Ensure the Rust backend is running:

```bash
cd kks_online_backend
cargo run
```

The server should start on `http://localhost:3000` by default (or the port specified in your `.env` file).

## Collection Structure

The collection is organized into three folders:

### 1. V1 API Endpoints (Recommended)
- **Get Products with Filters** - `/api/v1/products` - Get products with advanced filtering
- **Get Popular Products** - `/api/v1/products/popular` - Get popular products with pagination
- **Get Search Suggestions** - `/api/v1/products/search/suggestions` - Get search suggestions
- **Get Products by Category** - `/api/v1/products/category/:category_id` - Get products by category
- **Get Products by Brand** - `/api/v1/products/brand/:brand_id` - Get products by brand
- **Get Product by ID** - `/api/v1/products/:product_id` - Get product details
- **Get Product Variants** - `/api/v1/products/:product_id/variants` - Get product variants

### 2. Legacy Endpoints (Backwards Compatibility)
- **Get Popular Products Count** - `/api/products/popular/count` - Get count of popular products
- **Fetch Popular Products** - `/api/products/popular` - Legacy popular products endpoint
- **Fetch All Products for POS** - `/api/products/pos/all` - Get all products for POS system
- **Search Products** - `/api/products/search` - Legacy search endpoint
- **Get Product Statistics** - `/api/products/stats` - Get product statistics
- **Fetch Products by Category** - `/api/products/category/:category_id` - Legacy category endpoint
- **Fetch Products by Brand** - `/api/products/brand/:brand_id` - Legacy brand endpoint
- **Fetch Product by ID** - `/api/products/:product_id` - Legacy product details
- **Fetch Product Variations** - `/api/products/:product_id/variations` - Legacy variations endpoint

### 3. Product Variations
- **Get Variation by ID** - `/api/variations/:variant_id` - Get variation details
- **Get Related Variations** - `/api/variations/:variant_id/related` - Get related variations
- **Check Variant Stock** - `/api/variations/:variant_id/stock` - Check stock availability

## Testing Tips

### 1. Update Path Variables
Many requests use path variables like `:product_id`, `:category_id`, `:brand_id`, `:variant_id`. 
- Click on a request
- Go to **Params** tab
- Update the variable values with actual IDs from your database

### 2. Test Query Parameters
- Enable/disable query parameters as needed
- Modify values to test different scenarios
- Check the description for each parameter to understand its purpose

### 3. Common Test Scenarios

**Test Popular Products:**
1. Use "Get Popular Products" request
2. Modify `page` and `pageSize` parameters
3. Verify pagination works correctly

**Test Filtering:**
1. Use "Get Products with Filters" request
2. Enable `isPopular` parameter and set to `true`
3. Enable `categoryId` and set a valid category ID
4. Test sorting with `sortBy` and `sortOrder`

**Test Search:**
1. Use "Get Search Suggestions" request
2. Enter a search query (minimum 2 characters)
3. Verify suggestions are returned

## Response Format

### V1 API Responses

**Paginated Response:**
```json
{
  "success": true,
  "data": [
    {
      "product_id": 1,
      "name": "Product Name",
      "description": "Product description",
      "base_price": "100.00",
      "sale_price": "80.00",
      ...
    }
  ],
  "pagination": {
    "page": 1,
    "pageSize": 20,
    "total": 100,
    "totalPages": 5
  }
}
```

**Single Item Response:**
```json
{
  "success": true,
  "data": {
    "product_id": 1,
    "name": "Product Name",
    ...
  }
}
```

### Legacy API Responses

**Popular Products Count:**
```json
{
  "count": 150,
  "status": "success"
}
```

**Product List:**
```json
{
  "products": [...],
  "total_count": 100,
  "fetched_count": 20,
  "offset": 0,
  "has_more": true
}
```

## Troubleshooting

### Request Fails with Network Error
- Ensure backend server is running
- Check if the port matches your `base_url` variable
- Verify CORS is enabled in the backend

### 404 Not Found
- Check the endpoint path is correct
- Verify path variables are set (e.g., `:product_id`)
- Ensure the route exists in the backend

### 500 Internal Server Error
- Check backend logs for detailed error messages
- Verify database connection is working
- Check if required environment variables are set

### Empty Results
- Verify you have data in your database
- Check if filters are too restrictive
- Try different query parameters

## Additional Resources

- Backend Documentation: `../docs/PRODUCT_MODULE.md`
- API Migration Guide: `../API_MIGRATION_GUIDE.md`
- Backend README: `../../README.md`

## Notes

- All endpoints use GET method (read-only)
- No authentication required for these endpoints
- Responses are JSON formatted
- V1 API endpoints are recommended for new integrations
- Legacy endpoints are maintained for backwards compatibility

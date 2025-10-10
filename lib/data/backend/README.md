# Backend Integration Guide

This directory contains the backend integration layer for the OKiosk app,
replacing direct Supabase calls with proper backend API communication.

## Architecture

```
lib/data/backend/
├── config/
│   └── backend_config.dart          # Backend configuration
├── di/
│   └── backend_dependency_injection.dart  # Dependency injection setup
├── models/
│   ├── api_response.dart           # Generic API response models
│   └── product_api_models.dart      # Product and variation API models
├── services/
│   ├── api_client.dart             # Base HTTP client
│   ├── product_api_service.dart    # Product API service
│   └── variation_api_service.dart  # Variation API service
└── README.md                       # This file
```

## Setup Instructions

### 1. Configure Backend URL

Update the backend URL in `lib/data/backend/config/backend_config.dart`:

```dart
class BackendConfig {
  static const String baseUrl = 'https://your-backend-api.com'; // Replace with your actual backend URL
  // ... rest of config
}
```

### 2. Initialize Backend Services

In your `main.dart` or app initialization, add:

```dart
import 'package:okiosk/data/backend/di/backend_dependency_injection.dart';

void main() {
  // Initialize backend services
  BackendDependencyInjection.init();
  
  // ... rest of your app initialization
  runApp(MyApp());
}
```

### 3. API Endpoints Required

Your backend should implement these endpoints:

#### Product Endpoints:

- ✅ `GET /api/products/popular/count`
- ✅ `GET /api/products/popular?limit=10&offset=0`
- ✅ `GET /api/products/pos/all`
- ✅ `GET /api/products/search?query=...`
- ✅ `GET /api/products/stats`
- ✅ `GET /api/products/category/:id`
- ✅ `GET /api/products/brand/:id`
- ✅ `GET /api/products/:id`
- ✅ `GET /api/products/:id/variations`

#### Variation Endpoints:

- ✅ `GET /api/variations/:id`
- ✅ `GET /api/variations/:id/related`
- ✅ `GET /api/variations/:id/stock`

### 4. Response Format

All API endpoints should return responses in this format:

```json
{
  "success": true,
  "message": "Success",
  "data": { ... },
  "statusCode": 200
}
```

For paginated responses:

```json
{
  "success": true,
  "message": "Success",
  "data": [ ... ],
  "pagination": {
    "currentPage": 1,
    "totalPages": 10,
    "totalItems": 100,
    "itemsPerPage": 10,
    "hasNextPage": true,
    "hasPreviousPage": false
  }
}
```

## Migration from Supabase

The following files have been updated to use the new backend services:

1. **Controllers Updated:**
   - `lib/features/products/controller/product_controller.dart`
   - `lib/features/products/controller/product_varaintion_controller.dart`

2. **New Repository:**
   - `lib/data/repositories/products/backend_product_repository.dart`

3. **Services Created:**
   - `lib/data/backend/services/product_api_service.dart`
   - `lib/data/backend/services/variation_api_service.dart`

## Usage

The controllers and repositories work exactly the same as before. The only
change is that they now communicate with your backend API instead of directly
with Supabase.

### Example Usage:

```dart
// This will now use the backend API
final productController = Get.find<ProductController>();
await productController.loadPopularProductsLazily();

// This will also use the backend API
final variationController = Get.find<ProductVariationController>();
await variationController.fetchProductVariantByProductId(productId);
```

## Benefits

1. **Centralized Business Logic**: All product logic is now handled by your
   backend
2. **Better Security**: No direct database access from the mobile app
3. **Scalability**: Backend can handle complex operations and caching
4. **Consistency**: Same API for web and mobile
5. **Maintainability**: Easier to update business logic without app updates

## Error Handling

The backend integration includes comprehensive error handling:

- Network errors are caught and displayed to users
- API errors are properly formatted and shown
- Caching is maintained for offline functionality
- Fallback mechanisms are in place

## Caching

The backend repository maintains the same caching strategy as the original
Supabase repository:

- 30-minute cache expiry
- Automatic cache cleanup
- Smart cache invalidation
- Memory-efficient storage

## Testing

To test the backend integration:

1. Ensure your backend API is running
2. Update the `baseUrl` in `BackendConfig`
3. Run the app and test product loading
4. Check network requests in debug console
5. Verify data is being fetched from your backend

## Troubleshooting

### Common Issues:

1. **Network Errors**: Check if backend URL is correct and accessible
2. **API Format Errors**: Ensure your backend returns the expected JSON format
3. **CORS Issues**: Configure your backend to allow mobile app requests
4. **Authentication**: Add authentication headers if required

### Debug Mode:

Enable debug logging by setting `BackendConfig.enableDebugLogging = true` to see
detailed API request/response logs.

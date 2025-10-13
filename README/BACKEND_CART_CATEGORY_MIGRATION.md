# Cart and Category Backend Migration Guide

## Overview

This document details the migration of the Cart and Category modules from direct
Supabase calls to the new Rust backend API. The migration follows the
specifications in `CART_MODULE.md` and `CATEGORY_MODULE.md`.

## Changes Made

### 1. New Backend API Services

#### Cart API Service (`lib/data/backend/services/cart_api_service.dart`)

Implements all cart-related API endpoints:

**Customer Cart Endpoints:**

- `getCart(customerId)` - GET /api/cart/:customer_id
- `addToCart(customerId, variantId, quantity)` - POST /api/cart/:customer_id/add
- `updateCartItemQuantity(cartId, quantity)` - PUT /api/cart/item/:cart_id
- `removeCartItem(cartId)` - DELETE /api/cart/item/:cart_id
- `clearCart(customerId)` - DELETE /api/cart/:customer_id/clear
- `validateCartStock(customerId)` - GET /api/cart/:customer_id/validate

**Kiosk Cart Endpoints:**

- `getKioskCart(sessionId)` - GET /api/cart/kiosk/:session_id
- `addToKioskCart(sessionId, variantId, quantity)` - POST /api/cart/kiosk/add
- `updateKioskCartItemQuantity(kioskId, quantity)` - PUT
  /api/cart/kiosk/item/:kiosk_id
- `removeKioskCartItem(kioskId)` - DELETE /api/cart/kiosk/item/:kiosk_id
- `clearKioskCart(sessionId)` - DELETE /api/cart/kiosk/:session_id/clear

#### Category API Service (`lib/data/backend/services/category_api_service.dart`)

Implements all category-related API endpoints:

- `getAllCategories(featuredOnly)` - GET /api/categories/all
- `getCategoryById(categoryId)` - GET /api/categories/:category_id
- `getCategoryStats()` - GET /api/categories/stats

### 2. New Backend Repositories

#### Backend Cart Repository (`lib/data/repositories/cart/backend_cart_repository.dart`)

Replaces the old `CartRepository` with backend API calls:

- Uses `CartApiService` instead of direct Supabase calls
- Maintains the same interface as the old repository for compatibility
- Handles field name mapping between backend API and frontend models
- Implements proper error handling with user-friendly messages

**Key Features:**

- Complete cart item fetching with product and variant details
- Stock validation through backend API
- Support for both customer carts and kiosk carts
- Automatic field name mapping (product_name → name, brand_id → brandID, etc.)

#### Backend Category Repository (`lib/data/repositories/categories/backend_category_repository.dart`)

Replaces the old `CategoryRepository` with backend API calls:

- Uses `CategoryApiService` instead of direct Supabase calls
- Maintains category sorting (alphabetical with "More" category at end)
- Implements proper error handling

### 3. Updated Controllers

#### Cart Controller (`lib/features/cart/controller/cart_controller.dart`)

**Changed:**

- Import: `cart_repository.dart` → `backend_cart_repository.dart`
- Dependency: `CartRepository` → `BackendCartRepository`
- Injection: `Get.put(CartRepository())` → `Get.find<BackendCartRepository>()`

**No changes to:**

- Controller methods or business logic
- UI integration
- State management

#### Category Controller (`lib/features/categories/controller/category_controller.dart`)

**Changed:**

- Import: `category_repository.dart` → `backend_category_repository.dart`
- Dependency: `CategoroyRepostirory` → `BackendCategoryRepository`
- Injection: `Get.put(CategoroyRepostirory())` →
  `Get.find<BackendCategoryRepository>()`

**No changes to:**

- Controller methods or business logic
- UI integration
- State management

### 4. Dependency Injection

Updated `lib/data/backend/di/backend_dependency_injection.dart`:

**Added:**

- `CartApiService` registration
- `CategoryApiService` registration
- `BackendCartRepository` registration
- `BackendCategoryRepository` registration

## Setup Instructions

### 1. Initialize Backend Services

In your `main.dart`, ensure backend services are initialized:

```dart
import 'package:okiosk/data/backend/di/backend_dependency_injection.dart';

void main() {
  // Initialize backend services
  BackendDependencyInjection.init();
  
  // ... rest of your app initialization
  runApp(MyApp());
}
```

### 2. Configure Backend URL

Update the backend URL in `lib/data/backend/config/backend_config.dart`:

```dart
class BackendConfig {
  static const String baseUrl = 'http://localhost:3000'; // Development
  // static const String baseUrl = 'https://your-production-domain.com'; // Production
}
```

### 3. Ensure Backend is Running

Make sure your Rust backend is running and accessible at the configured URL:

```bash
cargo run --release
```

### 4. Test the Endpoints

Verify all endpoints are working:

**Cart Endpoints:**

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

# Kiosk cart
curl http://localhost:3000/api/cart/kiosk/550e8400-e29b-41d4-a716-446655440000
```

**Category Endpoints:**

```bash
# Get all categories
curl http://localhost:3000/api/categories/all

# Get featured categories only
curl http://localhost:3000/api/categories/all?featured_only=true

# Get category by ID
curl http://localhost:3000/api/categories/5

# Get category statistics
curl http://localhost:3000/api/categories/stats
```

## Field Mapping

The backend API returns data with different field names than the frontend models
expect. The repositories handle this mapping automatically:

### Cart Items

| Backend Field         | Frontend Field    |
| --------------------- | ----------------- |
| `product_name`        | `name`            |
| `product_description` | `description`     |
| `brand_id`            | `brandID`         |
| `kiosk_id`            | `cart_id` (kiosk) |

### Categories

| Backend Field   | Frontend Field |
| --------------- | -------------- |
| `category_id`   | `categoryId`   |
| `category_name` | `categoryName` |
| `isFeatured`    | `isFeatured`   |
| `created_at`    | `createdAt`    |
| `product_count` | `productCount` |

## Error Handling

Both repositories implement comprehensive error handling:

1. **Network Errors**: Automatically detected and handled gracefully
2. **API Errors**: Backend error messages are displayed to users
3. **Validation Errors**: Stock validation and cart validation errors are
   properly communicated
4. **Debug Logging**: Detailed logging in debug mode for troubleshooting

## Backward Compatibility

### Old Repository Files

The old repository files are still present but not used:

- `lib/data/repositories/cart/cart_repository.dart` (still uses Supabase)
- `lib/data/repositories/categories/category_repository.dart` (still uses
  Supabase)

You can keep these for reference or remove them once you confirm the migration
is successful.

### Migration Path

If you need to temporarily switch back to Supabase:

1. Update controllers to use old repositories:
   ```dart
   final _cartRepository = Get.put(CartRepository());
   ```

2. Update imports:
   ```dart
   import '../../../data/repositories/cart/cart_repository.dart';
   ```

## Testing

### Unit Tests

Test the repositories with mocked API responses:

```dart
// Mock the ApiClient
final mockClient = MockApiClient();
Get.put<ApiClient>(mockClient);

// Test repository methods
final repository = BackendCartRepository();
final result = await repository.fetchCompleteCartItems(123);
```

### Integration Tests

Test end-to-end with the actual backend:

1. Start the backend server
2. Run the Flutter app
3. Test cart operations (add, update, remove, clear)
4. Test category fetching and filtering
5. Test kiosk cart operations

## Troubleshooting

### Common Issues

**1. "Failed to fetch cart" error**

- Check if backend is running
- Verify backend URL in `backend_config.dart`
- Check network connectivity

**2. "Invalid response from backend"**

- Verify backend API is returning correct JSON format
- Check backend logs for errors
- Ensure all required endpoints are implemented

**3. "Cart items not displaying"**

- Check if field mapping is correct
- Verify `CartItemModel.fromMergedData` is working
- Check debug logs for parsing errors

**4. Dependency injection errors**

- Ensure `BackendDependencyInjection.init()` is called before using controllers
- Verify all services are registered in DI

### Debug Logging

Enable debug logging in `backend_config.dart`:

```dart
static const bool enableDebugLogging = true;
```

Check console for detailed API call logs:

- Request URLs and parameters
- Response status and data
- Error messages and stack traces

## Performance Considerations

### Caching

The backend repositories don't implement caching. Consider adding:

- Memory cache for frequently accessed data
- Cache invalidation on updates
- Time-based cache expiration

### Optimization

1. **Batch Operations**: Consider implementing batch endpoints for multiple
   operations
2. **Pagination**: Implement pagination for large cart lists
3. **Lazy Loading**: Load cart items on demand instead of all at once

## Next Steps

1. **Migration Verification**: Test all cart and category operations thoroughly
2. **Remove Old Code**: Once confident, remove old Supabase-based repositories
3. **Add Tests**: Implement unit and integration tests
4. **Performance Tuning**: Monitor and optimize API calls
5. **Documentation**: Update team documentation with new architecture

## Related Documentation

- `CART_MODULE.md` - Complete Cart API specification
- `CATEGORY_MODULE.md` - Complete Category API specification
- `BACKEND_MIGRATION_SUMMARY.md` - Overall backend migration summary
- `lib/data/backend/README.md` - Backend integration guide

---

**Migration completed on:** October 8, 2025 **Migrated modules:** Cart, Category
**Backend framework:** Rust + Axum **Frontend framework:** Flutter + GetX

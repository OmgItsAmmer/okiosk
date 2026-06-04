# Cart & Category Backend API - Quick Reference

## Quick Start

### 1. Initialize Backend Services

```dart
// In main.dart
import 'package:okiosk/data/backend/di/backend_dependency_injection.dart';

void main() {
  BackendDependencyInjection.init();
  runApp(MyApp());
}
```

### 2. Configure Backend URL

```dart
// lib/data/backend/config/backend_config.dart
class BackendConfig {
  static const String baseUrl = 'http://localhost:3000';
}
```

### 3. Controllers Automatically Use Backend

No changes needed in your UI code! Controllers now use backend APIs
automatically.

## API Endpoints Cheat Sheet

### Cart Endpoints

```bash
# Customer Cart
GET    /api/cart/:customer_id              # Get cart items
POST   /api/cart/:customer_id/add          # Add item
PUT    /api/cart/item/:cart_id             # Update quantity
DELETE /api/cart/item/:cart_id             # Remove item
DELETE /api/cart/:customer_id/clear        # Clear cart
GET    /api/cart/:customer_id/validate     # Validate stock

# Kiosk Cart
GET    /api/cart/kiosk/:session_id         # Get kiosk cart
POST   /api/cart/kiosk/add                 # Add to kiosk cart
PUT    /api/cart/kiosk/item/:kiosk_id      # Update kiosk item
DELETE /api/cart/kiosk/item/:kiosk_id      # Remove kiosk item
DELETE /api/cart/kiosk/:session_id/clear   # Clear kiosk cart
```

### Category Endpoints

```bash
GET /api/categories/all                    # Get all categories
GET /api/categories/all?featured_only=true # Get featured only
GET /api/categories/:id                    # Get category by ID
GET /api/categories/stats                  # Get category stats
```

## File Changes Summary

### New Files Created

```
lib/data/backend/services/
  ├── cart_api_service.dart              ✅ Cart API service
  └── category_api_service.dart          ✅ Category API service

lib/data/repositories/cart/
  └── backend_cart_repository.dart       ✅ Backend cart repository

lib/data/repositories/categories/
  └── backend_category_repository.dart   ✅ Backend category repository

Documentation/
  ├── BACKEND_CART_CATEGORY_MIGRATION.md ✅ Migration guide
  └── CART_CATEGORY_QUICK_REFERENCE.md   ✅ This file
```

### Modified Files

```
lib/features/cart/controller/cart_controller.dart
  - Import: cart_repository.dart → backend_cart_repository.dart
  - Uses: BackendCartRepository instead of CartRepository

lib/features/categories/controller/category_controller.dart
  - Import: category_repository.dart → backend_category_repository.dart
  - Uses: BackendCategoryRepository instead of CategoroyRepostirory

lib/data/backend/di/backend_dependency_injection.dart
  - Added: CartApiService registration
  - Added: CategoryApiService registration
  - Added: BackendCartRepository registration
  - Added: BackendCategoryRepository registration
```

## Code Examples

### Cart Operations

```dart
// Get cart controller (already using backend)
final cartController = Get.find<CartController>();

// Add to cart (backend API called automatically)
await cartController.addToCart(variantId, quantity: 2);

// Update quantity
await cartController.updateCartItemQuantity(cartItem, 5);

// Remove item
await cartController.removeCartItem(cartItem);

// Clear cart
await cartController.clearCart();

// Validate stock
await cartController.validateCartStock();
```

### Category Operations

```dart
// Get category controller (already using backend)
final categoryController = Get.find<CategoryController>();

// Fetch categories (backend API called automatically)
await categoryController.fetchCategories();

// Select category
categoryController.selectCategory(categoryId);

// Clear selection
categoryController.clearCategorySelection();

// Get selected category
final selected = categoryController.selectedCategory;
```

### Direct Repository Usage (Advanced)

```dart
// If you need to use repositories directly
final cartRepo = Get.find<BackendCartRepository>();
final categoryRepo = Get.find<BackendCategoryRepository>();

// Cart operations
final cartItems = await cartRepo.fetchCompleteCartItems(customerId);
final success = await cartRepo.addToCart(customerId, variantId, quantity);

// Category operations
final categories = await categoryRepo.getAllCategories();
final featured = await categoryRepo.getAllCategories(featuredOnly: true);
final category = await categoryRepo.getCategoryById(5);
final stats = await categoryRepo.getCategoryStats();
```

## Testing Commands

### Start Backend

```bash
cd path/to/rust/backend
cargo run --release
```

### Test Endpoints

```bash
# Test cart endpoint
curl http://localhost:3000/api/cart/123

# Test category endpoint
curl http://localhost:3000/api/categories/all

# Add to cart
curl -X POST http://localhost:3000/api/cart/123/add \
  -H "Content-Type: application/json" \
  -d '{"variant_id": 456, "quantity": 2}'
```

## Troubleshooting

| Issue                  | Solution                                             |
| ---------------------- | ---------------------------------------------------- |
| "Failed to fetch cart" | Check backend is running at `localhost:3000`         |
| "Dependency not found" | Ensure `BackendDependencyInjection.init()` is called |
| "Invalid response"     | Verify backend API returns correct JSON format       |
| Empty cart/categories  | Check backend database has data                      |

## Debug Logging

All API calls are logged in debug mode. Check console for:

```
CartApiService: Fetching cart for customer 123
CartApiService: Response - Success
CategoryApiService: Fetching categories (featured_only: false)
CategoryApiService: Response - Success
```

## Migration Checklist

- [x] Backend API services created
- [x] Backend repositories created
- [x] Controllers updated to use backend repositories
- [x] Dependency injection configured
- [x] Field mapping implemented
- [x] Error handling added
- [ ] Backend server running and accessible
- [ ] All endpoints tested and working
- [ ] UI tested with backend integration
- [ ] Old Supabase repositories removed (optional)

## Next Steps

1. **Start Backend**: `cargo run --release`
2. **Test Endpoints**: Use curl commands above
3. **Run Flutter App**: Test cart and category features
4. **Monitor Logs**: Check for any errors
5. **Production Deploy**: Update `BackendConfig.baseUrl` for production

## Support

- See `BACKEND_CART_CATEGORY_MIGRATION.md` for detailed migration guide
- See `CART_MODULE.md` for complete Cart API specification
- See `CATEGORY_MODULE.md` for complete Category API specification
- Check `lib/data/backend/README.md` for backend integration guide

# 🚀 Get Started Checklist - Cart & Category Backend

## Before You Start

Make sure you have:

- [ ] Rust backend project set up
- [ ] PostgreSQL database configured
- [ ] Flutter app environment ready

## Step-by-Step Setup

### 1️⃣ Start Your Backend (Required)

```bash
# Navigate to your Rust backend directory
cd path/to/your/rust/backend

# Run the backend server
cargo run --release

# You should see:
# Server running on http://0.0.0.0:3000
```

**Expected Output:**

```
🚀 Server started on http://0.0.0.0:3000
```

### 2️⃣ Verify Backend Endpoints

Test each endpoint to make sure they work:

**Test Cart:**

```bash
curl http://localhost:3000/api/cart/1
```

Expected: `{"items":[],"total_items":0,"subtotal":0.0,"status":"success"}`

**Test Categories:**

```bash
curl http://localhost:3000/api/categories/all
```

Expected: `{"categories":[...],"total_count":X,"status":"success"}`

### 3️⃣ Configure Flutter App

**Check backend URL:** Open `lib/data/backend/config/backend_config.dart` and
verify:

```dart
static const String baseUrl = 'http://localhost:3000';
```

**For Android Emulator, use:**

```dart
static const String baseUrl = 'http://10.0.2.2:3000';
```

**For iOS Simulator/Physical Device, use your computer's IP:**

```dart
static const String baseUrl = 'http://192.168.x.x:3000';
```

### 4️⃣ Run Flutter App

```bash
# Make sure you're in the Flutter project directory
cd path/to/okiosk

# Run the app
flutter run
```

### 5️⃣ Test Cart Operations in App

- [ ] Open the app
- [ ] Browse products
- [ ] Add a product to cart
- [ ] Check cart page
- [ ] Update quantity
- [ ] Remove item
- [ ] Check console for success messages

**Expected Console Output:**

```
CartApiService: Adding to cart - customer: X, variant: Y, qty: Z
CartApiService: Add to cart response - Success
BackendCartRepository: Received 1 items from API
```

### 6️⃣ Test Category Operations in App

- [ ] Open categories page
- [ ] Categories should load automatically
- [ ] Select a category
- [ ] Products should filter by category
- [ ] Check console for success messages

**Expected Console Output:**

```
CategoryApiService: Fetching categories (featured_only: false)
CategoryApiService: Response - Success
BackendCategoryRepository: Received X categories
```

## Quick Verification Commands

### Check if backend is running:

```bash
curl http://localhost:3000/api/categories/stats
```

### Test add to cart:

```bash
curl -X POST http://localhost:3000/api/cart/1/add \
  -H "Content-Type: application/json" \
  -d '{"variant_id": 1, "quantity": 1}'
```

### Test get cart:

```bash
curl http://localhost:3000/api/cart/1
```

## Troubleshooting

### ❌ "Failed to fetch cart"

**Problem:** Backend not running or wrong URL **Solution:**

1. Check backend is running: `curl http://localhost:3000/api/categories/stats`
2. Verify URL in `backend_config.dart`

### ❌ "Connection refused"

**Problem:** Backend URL not accessible from device **Solution:**

- Android Emulator: Use `http://10.0.2.2:3000`
- iOS Simulator: Use `http://localhost:3000`
- Physical Device: Use your computer's IP `http://192.168.x.x:3000`

### ❌ "Dependency not found"

**Problem:** Backend services not initialized **Solution:** Check `main.dart`
has `BackendDependencyInjection.init()`

### ❌ Empty cart/categories

**Problem:** Database has no data **Solution:** Add test data to your PostgreSQL
database

## Success Indicators

You know it's working when:

✅ Backend starts without errors ✅ Curl commands return valid JSON ✅ Flutter
app connects to backend (check console logs) ✅ Adding items to cart works ✅
Categories load and display ✅ No error snackbars appear in app ✅ Console shows
successful API calls

## Next Steps After Success

1. **Test thoroughly:**
   - Test all cart operations
   - Test all category operations
   - Test error scenarios

2. **Deploy backend:**
   - Update `backend_config.dart` with production URL
   - Test with production database

3. **Monitor:**
   - Watch for errors in logs
   - Check API performance
   - Gather user feedback

## Need Help?

- See `MIGRATION_COMPLETE_SUMMARY.md` for full details
- See `CART_CATEGORY_QUICK_REFERENCE.md` for code examples
- See `BACKEND_CART_CATEGORY_MIGRATION.md` for migration details

## Quick Start Script

Save this as `start_backend.sh`:

```bash
#!/bin/bash
cd path/to/rust/backend
cargo run --release
```

Make it executable:

```bash
chmod +x start_backend.sh
./start_backend.sh
```

---

**Last Updated:** October 8, 2025 **Status:** Ready for Testing ✅

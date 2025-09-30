# Kiosk Cart Realtime Debug Guide

## 🔧 Debugging Improvements Made

I've enhanced the kiosk cart realtime implementation with comprehensive
debugging features to help identify and resolve issues.

### ✅ Debug Enhancements Added:

1. **Enhanced Realtime Logging** - Detailed logs for subscription status and
   events
2. **Cart Controller Debug Methods** - Test realtime connection and data flow
3. **UI Debug Information** - Visual debug panel showing cart state
4. **Repository Debug Logging** - Detailed data processing logs
5. **POS Controller Synchronization Logging** - Track cart synchronization

## 🔍 Debug Features Overview

### 1. **Debug UI Panel** (Debug Mode Only)

- Shows current kiosk UUID
- Displays cart items count
- Shows scanned session ID
- Real-time updates

### 2. **Debug Buttons** (Debug Mode Only)

- **Debug Cart**: Check all kiosk cart items in database
- **Test RT**: Test realtime connection with direct database insertion

### 3. **Enhanced Console Logging**

All debug information is logged to console when `kDebugMode` is true.

## 🚀 Testing Steps

### Step 1: Verify Kiosk Initialization

1. Start the kiosk app
2. Check console logs for:
   ```
   CartController: Generated kiosk UUID: [UUID]
   KioskCartRealtime: Starting realtime subscription for session: [UUID]
   KioskCartRealtime: ✅ Successfully subscribed for session: [UUID]
   ```

### Step 2: Test Realtime Connection

1. In the empty cart view, click **"Test RT"** button
2. Check console logs for:
   ```
   CartController: === TESTING REALTIME CONNECTION ===
   CartController: Current kiosk UUID: [UUID]
   CartController: Testing direct database insertion...
   KioskCartRealtime: INSERT detected for session [UUID]
   CartController: ✅ Successfully fetched [N] items for session: [UUID]
   ```

### Step 3: Manual Database Test

1. Open your Supabase database
2. Insert a test row manually:
   ```sql
   INSERT INTO kiosk_cart (kiosk_session_id, variant_id, quantity)
   VALUES ('[your-kiosk-uuid]', 1, 2);
   ```
3. Check if the item appears in the UI within 1-2 seconds

### Step 4: E-commerce App Integration Test

1. Add items to your e-commerce app cart
2. Use the "Send to Kiosk" feature to scan the kiosk QR code
3. Verify items appear in the kiosk cart immediately

## 🔧 Common Issues & Solutions

### Issue 1: Realtime Not Starting

**Symptoms:**

- No subscription logs in console
- "KioskCartRealtime: Cannot start realtime - session ID is empty"

**Solutions:**

1. Check UUID generation in cart controller
2. Verify `THelperFunctions.generateRandomUUID()` is working
3. Ensure cart controller is properly initialized

### Issue 2: Realtime Subscription Fails

**Symptoms:**

- "KioskCartRealtime: ❌ Subscription error: [error]"
- "KioskCartRealtime: ⚠️ Subscription timed out"

**Solutions:**

1. Check internet connection
2. Verify Supabase configuration in `main.dart`
3. Ensure realtime is enabled in Supabase dashboard
4. Check if RLS policies are blocking access

### Issue 3: Database Inserts Not Triggering Realtime

**Symptoms:**

- Data is inserted in database but no realtime callback
- "KioskCartRealtime: INSERT detected" not appearing

**Solutions:**

1. Verify realtime is enabled for `kiosk_cart` table in Supabase
2. Check if UUID in database matches kiosk UUID
3. Ensure `kiosk_session_id` column matches exactly

### Issue 4: Data Fetched But UI Not Updating

**Symptoms:**

- "CartController: ✅ Successfully fetched [N] items" but empty cart UI
- Items fetched but POS controller not synchronized

**Solutions:**

1. Check POS controller synchronization logs
2. Verify `ever()` listener is working in POS controller
3. Check if cart items are being assigned correctly
4. Verify UI is using `Obx()` for reactive updates

### Issue 5: Cart Repository Data Processing Errors

**Symptoms:**

- "CartRepository: Error processing cart item: [error]"
- Data fetched but transformation fails

**Solutions:**

1. Check if product_variants and products tables have required data
2. Verify foreign key relationships
3. Check for null values in required fields
4. Ensure database schema matches model expectations

## 📊 Debug Console Output Examples

### ✅ Working Realtime Connection:

```
KioskCartRealtime: Attempting to start realtime...
KioskCartRealtime: Session ID: 550e8400-e29b-41d4-a716-446655440000
KioskCartRealtime: Starting realtime subscription for session: 550e8400-e29b-41d4-a716-446655440000
KioskCartRealtime: Subscription status: RealtimeSubscribeStatus.subscribed
KioskCartRealtime: ✅ Successfully subscribed for session: 550e8400-e29b-41d4-a716-446655440000

# When item is inserted:
KioskCartRealtime: INSERT detected for session 550e8400-e29b-41d4-a716-446655440000
CartController: Fetching kiosk cart for session: 550e8400-e29b-41d4-a716-446655440000
CartRepository: Simple query found 1 items
CartRepository: Join query found 1 items
CartController: ✅ Successfully fetched 1 items for session: 550e8400-e29b-41d4-a716-446655440000
PosController: CartController items changed - 1 items
PosController: Cart items synchronized - 1 items in POS controller
```

### ❌ Failed Connection Examples:

```
# Empty UUID
KioskCartRealtime: Session ID empty: true
KioskCartRealtime: Cannot start realtime - session ID is empty

# Subscription failure
KioskCartRealtime: ❌ Subscription error: [error details]

# Network/Supabase issues
CartRepository: Error in fetchCompleteKioskCartItems: [network error]
```

## 🛠️ Advanced Debugging

### Check Database Directly

```sql
-- Check if kiosk_cart table exists and has data
SELECT * FROM kiosk_cart ORDER BY created_at DESC LIMIT 10;

-- Check for specific session
SELECT * FROM kiosk_cart WHERE kiosk_session_id = '[your-uuid]';

-- Check realtime subscription status
SELECT * FROM realtime.subscription;
```

### Manual Testing with Supabase Client

```dart
// Test direct database access
final response = await supabase
    .from('kiosk_cart')
    .select('*')
    .eq('kiosk_session_id', 'your-uuid');
print('Direct query result: $response');
```

## 📞 Getting More Help

If issues persist:

1. **Check Supabase Dashboard**:
   - Verify realtime is enabled
   - Check logs in API section
   - Verify RLS policies

2. **Network Analysis**:
   - Use browser dev tools to monitor websocket connections
   - Check for CORS issues
   - Verify SSL certificates

3. **Flutter Analysis**:
   - Run `flutter analyze` for code issues
   - Check for memory leaks with `flutter doctor`

4. **Console Logs Priority**:
   - Focus on KioskCartRealtime logs first
   - Then CartController logs
   - Finally CartRepository logs

## 🎯 Key Success Indicators

The feature is working correctly when you see:

1. ✅ UUID generated on app start
2. ✅ Realtime subscription successful
3. ✅ INSERT events detected immediately
4. ✅ Cart data fetched and processed
5. ✅ UI updates with new items
6. ✅ POS controller synchronization working

Follow this guide systematically to identify and resolve any issues with the
kiosk cart realtime feature.

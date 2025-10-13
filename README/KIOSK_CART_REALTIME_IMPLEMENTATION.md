# Kiosk Cart Realtime Implementation

## Overview

This document explains the implementation of the real-time cart synchronization
between the e-commerce app and kiosk app, using the `kiosk_cart` table as the
shared data layer.

## Architecture

### Database Schema

```sql
CREATE TABLE public.kiosk_cart (
  kiosk_id SERIAL NOT NULL,
  kiosk_session_id UUID NOT NULL,
  variant_id INTEGER NOT NULL,
  quantity INTEGER NOT NULL,
  created_at TIMESTAMP WITHOUT TIME ZONE NULL DEFAULT NOW(),
  CONSTRAINT kiosk_cart_pkey PRIMARY KEY (kiosk_id)
);
```

### Key Components

1. **KioskCartModel** (`lib/features/cart/model/kiosk_cart_model.dart`)
   - Data model representing kiosk cart entries
   - Maps to the `kiosk_cart` database table

2. **Realtime Listener** (`lib/data/realtime/kiosk_cart_realtime.dart`)
   - Listens for INSERT, UPDATE, DELETE events on `kiosk_cart` table
   - Filters events by `kiosk_session_id` to ensure kiosk only receives its own
     data

3. **Cart Controller** (`lib/features/cart/controller/cart_controller.dart`)
   - Manages cart state and handles realtime updates
   - Generates unique UUID for each kiosk instance

4. **Cart Repository** (`lib/data/repositories/cart/cart_repository.dart`)
   - Provides methods to fetch, add, update, and delete kiosk cart items

5. **Cart Sidebar UI** (`lib/features/pos/widgets/cart_sidebar.dart`)
   - Displays QR code with kiosk UUID
   - Shows cart items and handles user interactions

## How It Works

### 1. Kiosk Initialization

When a kiosk app starts:

1. **UUID Generation**: The `CartController` generates a unique UUID for the
   kiosk instance
2. **QR Code Display**: The cart sidebar displays a QR code containing the kiosk
   UUID
3. **Realtime Subscription**: A Supabase realtime channel is created to listen
   for changes to the `kiosk_cart` table filtered by the kiosk's UUID

```dart
void startCartRealtime() {
  final cartController = Get.find<CartController>();
  final sessionId = cartController.kioskUUID; // Use kiosk's own UUID

  _cartChannel = Supabase.instance.client
      .channel('kiosk-cart-$sessionId')
    ..onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'kiosk_cart',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'kiosk_session_id',
        value: sessionId,
      ),
      callback: (payload) async {
        await cartController.fetchKioskCartBySession(sessionId);
      },
    ).subscribe();
}
```

### 2. E-commerce App Interaction

When a customer scans the kiosk QR code from their e-commerce app:

1. **QR Code Scan**: The e-commerce app scans the QR code and extracts the kiosk
   UUID
2. **Cart Transfer**: The e-commerce app inserts its cart items into the
   `kiosk_cart` table using the kiosk UUID as the `kiosk_session_id`
3. **Database Insert**: Items are inserted with the structure:
   ```sql
   INSERT INTO kiosk_cart (kiosk_session_id, variant_id, quantity)
   VALUES ('{kiosk_uuid}', {variant_id}, {quantity});
   ```

### 3. Real-time Updates

When items are inserted into the `kiosk_cart` table:

1. **Realtime Trigger**: The Supabase realtime system detects the INSERT event
2. **Filter Match**: The event passes the filter (kiosk_session_id = kiosk UUID)
3. **Callback Execution**: The realtime callback is triggered on the kiosk
4. **Cart Fetch**: The kiosk fetches the updated cart data from the database
5. **UI Update**: The cart sidebar automatically updates to show the new items

## Key Methods

### CartController

```dart
// Generates unique UUID for the kiosk
void generateKioskUUID()

// Initializes realtime subscription and performs initial cart fetch
void _initializeKioskCart()

// Fetches cart items for a specific session ID
Future<void> fetchKioskCartBySession(String sessionId)

// Cleans up realtime subscription
void onClose()
```

### CartRepository

```dart
// Fetches complete cart items with product details for kiosk session
Future<List<CartItemModel>> fetchCompleteKioskCartItems(String kioskSessionId)

// Adds item to kiosk cart
Future<bool> addToKioskCart(String kioskSessionId, int variantId, int quantity)

// Updates kiosk cart item quantity
Future<bool> updateKioskCartItemQuantity(int kioskId, int newQuantity)

// Removes item from kiosk cart
Future<bool> removeKioskCartItem(int kioskId)
```

## Flow Diagram

```
E-commerce App                 Database (kiosk_cart)           Kiosk App
     |                               |                            |
     |  1. Scan QR Code              |                            |
     |     (gets kiosk UUID)         |                            |
     |                               |                            |
     |  2. Insert cart items         |                            |
     |----------------------------->|                            |
     |  INSERT INTO kiosk_cart       |                            |
     |  (kiosk_session_id=UUID)      |                            |
     |                               |                            |
     |                               |  3. Realtime Event         |
     |                               |--------------------------->|
     |                               |  (INSERT detected)         |
     |                               |                            |
     |                               |  4. Fetch updated cart     |
     |                               |<---------------------------|
     |                               |  SELECT FROM kiosk_cart    |
     |                               |  WHERE session_id=UUID     |
     |                               |                            |
     |                               |  5. Return cart data       |
     |                               |--------------------------->|
     |                               |                            |
     |                               |                        6. Update UI
     |                               |                           |
```

## Configuration

### Required Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
   supabase_flutter: ^latest_version
   get: ^latest_version
   qr_flutter: ^latest_version
```

### Supabase Setup

1. Enable realtime on the `kiosk_cart` table
2. Configure Row Level Security (RLS) if needed
3. Ensure proper indexes on `kiosk_session_id` for performance

## Testing

### Manual Testing Steps

1. **Start Kiosk App**: Verify UUID generation and QR code display
2. **Simulate E-commerce Insert**: Manually insert data into `kiosk_cart` table
3. **Verify Realtime Update**: Check if kiosk cart updates immediately
4. **Test Cart Operations**: Add, update, remove items from kiosk

### Debug Information

The implementation includes extensive logging:

- UUID generation
- Realtime subscription status
- Cart fetch operations
- Error handling

Enable debug mode to see detailed logs:

```dart
if (kDebugMode) {
  print('CartController: Generated kiosk UUID: ${_kioskUUID.value}');
}
```

## Troubleshooting

### Common Issues

1. **Realtime Not Working**
   - Check Supabase realtime is enabled
   - Verify network connectivity
   - Check UUID matching between apps

2. **Cart Not Loading**
   - Verify `kiosk_session_id` matches kiosk UUID
   - Check database permissions
   - Review error logs

3. **UI Not Updating**
   - Ensure GetX reactive variables are used
   - Check if `cartItems.refresh()` is called
   - Verify UI is properly observing cart state

### Performance Considerations

1. **Database Indexing**: Add index on `kiosk_session_id` for faster queries
2. **Realtime Filters**: Use specific filters to reduce unnecessary events
3. **Cleanup**: Properly dispose realtime subscriptions to prevent memory leaks

## Security Notes

1. **UUID Generation**: Use cryptographically secure random UUIDs
2. **Session Management**: Consider session timeouts for kiosk carts
3. **Data Validation**: Validate all incoming cart data
4. **Access Control**: Implement proper RLS policies if needed

## E-commerce App Implementation Steps

Follow these steps to implement the kiosk cart feature in your e-commerce
Flutter app:

### 1. Add Dependencies

Add the following dependencies to your e-commerce app's `pubspec.yaml`:

```yaml
dependencies:
   qr_code_scanner: ^1.0.1 # For QR code scanning
   supabase_flutter: ^2.8.0 # If not already added
   uuid: ^4.5.1 # For UUID generation (if needed)
```

### 2. Create Kiosk Cart Transfer Service

Create a service class to handle cart transfer to kiosk:

```dart
// lib/services/kiosk_cart_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class KioskCartService {
  static final _supabase = Supabase.instance.client;

  /// Transfers current cart items to kiosk
  static Future<bool> transferCartToKiosk({
    required String kioskSessionId,
    required List<CartItem> cartItems,
  }) async {
    try {
      // Prepare batch insert data
      final List<Map<String, dynamic>> kioskCartData = cartItems.map((item) => {
        'kiosk_session_id': kioskSessionId,
        'variant_id': item.variantId,
        'quantity': item.quantity,
      }).toList();

      // Insert all cart items at once
      await _supabase.from('kiosk_cart').insert(kioskCartData);
      
      return true;
    } catch (e) {
      print('Error transferring cart to kiosk: $e');
      return false;
    }
  }
}
```

### 3. Add QR Scanner Widget

Create a QR scanner widget for scanning kiosk QR codes:

```dart
// lib/widgets/kiosk_qr_scanner.dart
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class KioskQRScanner extends StatefulWidget {
  final Function(String) onQRScanned;

  const KioskQRScanner({Key? key, required this.onQRScanned}) : super(key: key);

  @override
  State<KioskQRScanner> createState() => _KioskQRScannerState();
}

class _KioskQRScannerState extends State<KioskQRScanner> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Kiosk QR Code'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: Colors.green,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 300,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.black,
              child: const Center(
                child: Text(
                  'Point camera at kiosk QR code',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (scanData.code != null) {
        controller.pauseCamera();
        widget.onQRScanned(scanData.code!);
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
```

### 4. Add "Send to Kiosk" Button to Cart

Add a button to your cart screen to initiate kiosk transfer:

```dart
// In your cart screen widget
ElevatedButton.icon(
  onPressed: () => _sendToKiosk(context),
  icon: const Icon(Icons.qr_code),
  label: const Text('Send to Kiosk'),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.blue,
    foregroundColor: Colors.white,
  ),
)

void _sendToKiosk(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => KioskQRScanner(
        onQRScanned: (kioskSessionId) => _handleKioskQRScanned(context, kioskSessionId),
      ),
    ),
  );
}

Future<void> _handleKioskQRScanned(BuildContext context, String kioskSessionId) async {
  // Show loading dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const AlertDialog(
      content: Row(
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 16),
          Text('Sending cart to kiosk...'),
        ],
      ),
    ),
  );

  // Transfer cart to kiosk
  final success = await KioskCartService.transferCartToKiosk(
    kioskSessionId: kioskSessionId,
    cartItems: cartController.cartItems, // Your cart items
  );

  Navigator.pop(context); // Close loading dialog

  if (success) {
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cart sent to kiosk successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    
    // Optionally clear the mobile cart
    // cartController.clearCart();
  } else {
    // Show error message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Failed to send cart to kiosk. Please try again.'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

## Supabase Database Setup

### 1. Create Kiosk Cart Table

Run this SQL in your Supabase SQL editor:

```sql
-- Create kiosk_cart table
CREATE TABLE public.kiosk_cart (
  kiosk_id SERIAL NOT NULL,
  kiosk_session_id UUID NOT NULL,
  variant_id INTEGER NOT NULL,
  quantity INTEGER NOT NULL,
  created_at TIMESTAMP WITHOUT TIME ZONE NULL DEFAULT NOW(),
  CONSTRAINT kiosk_cart_pkey PRIMARY KEY (kiosk_id)
);

-- Add foreign key constraint to product_variants (optional)
ALTER TABLE public.kiosk_cart 
ADD CONSTRAINT fk_kiosk_cart_variant 
FOREIGN KEY (variant_id) REFERENCES public.product_variants(variant_id) 
ON DELETE CASCADE;

-- Create index for better performance
CREATE INDEX idx_kiosk_cart_session_id ON public.kiosk_cart(kiosk_session_id);
CREATE INDEX idx_kiosk_cart_created_at ON public.kiosk_cart(created_at);
```

### 2. Enable Realtime

Enable realtime for the `kiosk_cart` table in Supabase Dashboard:

1. Go to Database → Replication
2. Click on "0 tables" next to "kiosk_cart"
3. Toggle on the `kiosk_cart` table
4. Click "Save"

### 3. Set up Row Level Security (Optional but Recommended)

```sql
-- Enable RLS
ALTER TABLE public.kiosk_cart ENABLE ROW LEVEL SECURITY;

-- Create policy to allow all operations (adjust based on your needs)
CREATE POLICY "Allow all operations on kiosk_cart" ON public.kiosk_cart
FOR ALL USING (true) WITH CHECK (true);

-- Or create more restrictive policies based on your security requirements
-- Example: Only allow inserts from authenticated users
CREATE POLICY "Allow authenticated inserts" ON public.kiosk_cart
FOR INSERT WITH CHECK (auth.role() = 'authenticated');
```

### 4. Create Cleanup Function (Optional)

Create a function to automatically clean up old kiosk cart sessions:

```sql
-- Function to clean up old kiosk cart sessions
CREATE OR REPLACE FUNCTION cleanup_old_kiosk_carts()
RETURNS void AS $$
BEGIN
  DELETE FROM public.kiosk_cart 
  WHERE created_at < NOW() - INTERVAL '24 hours';
END;
$$ LANGUAGE plpgsql;

-- Create a cron job to run cleanup daily (requires pg_cron extension)
-- SELECT cron.schedule('cleanup-kiosk-carts', '0 2 * * *', 'SELECT cleanup_old_kiosk_carts();');
```

## Testing the Implementation

### Test Flow:

1. **Start Kiosk App**: Launch your kiosk app and verify UUID generation and QR
   code display
2. **Add Items to E-commerce Cart**: Add some items to your mobile e-commerce
   app cart
3. **Scan QR Code**: Use the "Send to Kiosk" feature to scan the kiosk QR code
4. **Verify Transfer**: Check that items appear in the kiosk cart within 1-2
   seconds
5. **Test Operations**: Try adding, updating, and removing items from the kiosk
6. **Verify Realtime**: Ensure all changes are reflected immediately

### Debug Steps:

1. **Check Database**: Verify data is being inserted into `kiosk_cart` table
2. **Monitor Realtime**: Check browser developer tools for realtime connection
   status
3. **Validate UUIDs**: Ensure UUIDs match between QR code and database entries
4. **Test Network**: Verify both apps have stable internet connection

## Troubleshooting

### Common Issues:

1. **Realtime Not Working**:
   - Ensure realtime is enabled in Supabase
   - Check network connectivity
   - Verify UUID matching

2. **QR Scanner Not Working**:
   - Add camera permissions to Android/iOS
   - Test on physical device (camera required)

3. **Cart Transfer Fails**:
   - Check authentication status
   - Verify RLS policies
   - Validate variant_id references

## Future Enhancements

1. **Session Expiry**: Implement automatic cleanup of old kiosk cart sessions
2. **Conflict Resolution**: Handle concurrent updates from multiple sources
3. **Offline Support**: Cache cart data for offline scenarios
4. **Analytics**: Track cart transfer success rates and performance metrics
5. **Multi-store Support**: Support multiple store locations with different
   kiosks

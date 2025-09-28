# Kiosk Cart Implementation

This document describes the changes made to implement kiosk-specific cart functionality with QR code scanning and local cart management.

## Overview

The kiosk app now supports two cart modes:
1. **Local Mode**: Temporary cart that doesn't sync to database (default for kiosk)
2. **Customer Mode**: Cart loaded from database when customer QR is scanned

## Key Changes Made

### 1. Cart Controller Modifications (`lib/features/cart/controller/cart_controller.dart`)

#### New Properties
- `isKioskMode`: Boolean flag to enable kiosk functionality
- `_scannedCustomerId`: Stores the customer ID from QR scan
- `_localCartIdCounter`: Generates unique local cart IDs

#### Enhanced Methods
- **`addToCart()`**: Now supports local cart for kiosk mode
- **`fetchCart()`**: Fetches customer cart only when QR is scanned
- **`updateCartItemQuantity()`**: Local updates with max quantity validation
- **`removeCartItem()`**: Local cart item removal
- **`clearCart()`**: Clears local cart without database operations
- **`validateCartStock()`**: Validates local cart against current stock

#### New Kiosk-Specific Methods
- **`scanCustomerQR()`**: Loads customer cart from database
- **`resetToKioskMode()`**: Clears cart and returns to local mode
- **`_addToLocalCart()`**: Adds items to local temporary cart
- **`_createLocalCartItem()`**: Creates local cart item models
- **`_validateVariantForLocalCart()`**: Validates variant stock for local operations
- **`_validateLocalCartStock()`**: Validates all local cart items before checkout

### 2. Cart Repository Updates (`lib/data/repositories/cart/cart_repository.dart`)

#### New Methods
- **`validateVariantStock()`**: Simple stock validation without RPC calls
  - Checks variant visibility and stock availability
  - Used for kiosk mode validation

### 3. QR Scanner Implementation

#### New Widget (`lib/common/widgets/qr_scanner/qr_scanner_widget.dart`)
- Full-screen QR scanner with camera controls
- Custom overlay with scanning frame
- Torch and camera switching functionality
- Error handling and retry capabilities

#### Dependencies Added
- `mobile_scanner: ^3.5.7` added to `pubspec.yaml`

### 4. Kiosk Header Integration (`lib/common/widgets/header/kiosk_header.dart`)

#### QR Scanner Integration
- Scanner icon now opens QR scanner
- Handles QR data parsing and customer ID extraction
- Automatic cart loading after successful scan

## Usage Flow

### 1. Default Kiosk Mode
1. Kiosk starts with empty local cart
2. Staff can add items to local cart
3. Items validate against max quantity limits from shop controller
4. Local cart exists only in memory (no database sync)

### 2. Customer QR Scan Flow
1. Customer opens mobile app and generates QR code with their customer ID
2. Staff scans QR code using scanner in kiosk header
3. Customer's cart is loaded from database
4. Staff can add more items or proceed to checkout

### 3. Validation Flow
- **Add to Cart**: Validates variant stock availability
- **Max Quantity**: Uses `ShopController.maxAllowedQuantity()` instead of RPC
- **Checkout**: Validates all cart items against current stock
- **Stock Adjustments**: Suggests quantity reductions or item removal

## Key Features

### ✅ Completed Requirements

1. **Local Cart**: ✓ Items added to kiosk don't sync to database
2. **QR Integration**: ✓ QR scanner loads customer cart from database
3. **RPC Removal**: ✓ Removed `add_to_cart_validation` from addToCart
4. **Variant Validation**: ✓ Added stock validation for add to cart and checkout
5. **Max Quantity**: ✓ Uses shop controller for quantity limits

### 🔧 Technical Implementation

- **State Management**: Reactive variables for cart state
- **Error Handling**: Comprehensive error handling with user feedback
- **Performance**: Optimized local cart operations
- **Validation**: Real-time stock validation
- **UI Integration**: Seamless QR scanning experience

## Configuration

The kiosk mode is enabled by default through:
```dart
final RxBool isKioskMode = true.obs; // Set to true for kiosk app
```

## Testing Recommendations

1. **Local Cart Operations**
   - Add items to cart without database sync
   - Update quantities with max limit validation
   - Remove items from local cart

2. **QR Functionality**
   - Generate QR codes with customer IDs
   - Test scanner with valid/invalid QR codes
   - Verify cart loading from database

3. **Stock Validation**
   - Test with out-of-stock items
   - Validate quantity limits
   - Test checkout validation flow

4. **Edge Cases**
   - Invalid QR codes
   - Network connectivity issues
   - Stock changes during cart session

## Future Enhancements

- QR code generation for kiosk sessions
- Offline cart persistence
- Enhanced validation with real-time stock updates
- Integration with POS checkout flow

# POS Kiosk System

A responsive Flutter POS (Point of Sale) kiosk application designed for screens between 15" and 32" with minimum resolution of 1366x768.

## Features

### ✅ Responsive Layout
- **Adaptive Grid**: Product grid adjusts from 2-5 columns based on screen size
- **Smart Categories**: Wrappable layout for large screens, scrollable for smaller screens
- **Fixed Sidebar**: 30-35% width cart area remains consistent across all sizes
- **Touch Optimized**: 48px+ touch targets, scales up to 56px on larger screens

### ✅ Complete POS Functionality
- **Category Selection**: Filter products by category with visual feedback
- **Product Management**: Display products with pricing, stock, and tags
- **Cart Operations**: Add, remove, update quantities with live total calculation
- **Payment Methods**: Cash, Card, Google Pay, Apple Pay selection
- **Checkout Process**: Complete transaction flow with loading states

### ✅ State Management
- **GetX Integration**: Reactive state management for real-time updates
- **Data Models**: Uses existing cart, product, category, and image models
- **Dummy Data**: 25 products across 6 categories for testing

### ✅ Design System
- **Color Scheme**: Uses app's existing TColors theme
- **Typography**: Responsive font sizes that scale with screen size
- **Components**: Reuses existing choice chips and UI components

## Usage

### Basic Setup

```dart
// Add to your app routes
import 'package:okiosk/features/pos/screens/pos_kiosk_screen.dart';

// In your routes
GetPage(
  name: '/pos-kiosk', 
  page: () => const PosKioskScreen(),
  binding: PosKioskBinding(),
),
```

### Navigation

```dart
// Navigate to POS screen
Get.toNamed('/pos-kiosk');

// Or direct navigation
Get.to(() => const PosKioskScreen());
```

### Debug Mode

```dart
// Use debug version with overlay information
Get.to(() => const PosKioskScreenDebug());
```

## Architecture

### Controller (`PosController`)
- Manages categories, products, and cart state
- Handles checkout process and payment method selection
- Provides reactive data for UI updates

### Widgets
- **CategorySelector**: Responsive category navigation
- **ProductGrid**: Adaptive product display with wrap functionality
- **CartSidebar**: Fixed-width cart with summary and checkout

### Layout Template (`PosLayoutTemplate`)
- Centralized responsive design decisions
- Breakpoint management (1366px, 1600px, 1920px)
- Consistent sizing and spacing calculations

## Screen Size Adaptations

### Large Screens (≥1920px)
- 5-column product grid
- Wrappable category layout
- 20% larger fonts and spacing
- 56px touch targets

### Medium Screens (1600px-1919px)
- 4-column product grid
- Wrappable category layout
- 10% larger fonts and spacing
- 48px touch targets

### Small Screens (1366px-1599px)
- 3-column product grid
- Horizontal scrollable categories
- Base font sizes and spacing
- 48px touch targets

### Warning System
Displays warnings for screens below 1366x768 with option to proceed anyway.

## Data Integration

The system is designed to easily swap dummy data with real Supabase data:

```dart
// Replace dummy data methods in PosController
void _loadCategoriesFromSupabase() async {
  // Your Supabase integration
}

void _loadProductsFromSupabase() async {
  // Your Supabase integration
}
```

## Customization

### Layout Ratios
```dart
// In PosLayoutTemplate
static const double productAreaWidthRatio = 0.65; // 65% for products
static const double cartAreaWidthRatio = 0.35;    // 35% for cart
```

### Breakpoints
```dart
static const double minKioskWidth = 1366.0;
static const double minKioskHeight = 768.0;
static const double largeKioskWidth = 1920.0;
static const double mediumKioskWidth = 1600.0;
```

### Grid Columns
```dart
// Modify in getProductGridCrossAxisCount()
if (productAreaWidth >= 1200) return 5;
if (productAreaWidth >= 900) return 4;
if (productAreaWidth >= 600) return 3;
return 2;
```

## Files Structure

```
lib/features/pos/
├── controller/
│   └── pos_controller.dart          # State management
├── screens/
│   └── pos_kiosk_screen.dart       # Main POS screen
├── widgets/
│   ├── category_selector.dart      # Category navigation
│   ├── product_grid.dart          # Product display
│   └── cart_sidebar.dart          # Cart and checkout
└── README.md                      # This file

lib/utils/layouts/
└── template.dart                  # Responsive layout configuration
```

## Testing

The system includes comprehensive dummy data:
- 6 categories (Electronics, Clothing, Books, Home & Garden, Sports, Food & Beverage)
- 25 products with realistic pricing and stock levels
- Various product tags (sale, featured, new_product)
- Multiple payment methods

## Development Notes

- All components use GetX for reactive state management
- Layout decisions are centralized in `PosLayoutTemplate`
- Touch targets meet accessibility standards (48px minimum)
- Supports both landscape and portrait orientations
- Optimized for kiosk/tablet usage patterns

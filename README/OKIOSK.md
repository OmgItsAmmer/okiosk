# OKIOSK Flutter Project Structure

## Overview
OKIOSK is a Flutter e-commerce application with a well-organized feature-based architecture. The project follows clean architecture principles with clear separation of concerns.

## Project Structure

### Root Files
```
lib/
├── main.dart (3.2KB, 106 lines) - Application entry point
└── app.dart (1.0KB, 35 lines) - Main app configuration
```

### Core Directories

#### 1. Features (`lib/features/`)
Feature-based modules following clean architecture:

**Cart Feature**
```
features/cart/
├── controller/
│   └── cart_controller.dart (0.0B, 0 lines)
├── model/
│   └── cart_model.dart (11KB, 384 lines)
├── screens/
│   └── cart_screen.dart (0.0B, 0 lines)
└── orders_manager/
    ├── controller/
    │   └── order_controller.dart (0.0B, 0 lines)
    └── models/
        ├── order_model.dart (3.7KB, 137 lines)
        └── order_item_model.dart (2.8KB, 106 lines)
```

**Checkout Feature**
```
features/checkout/
├── controller/
│   └── checkout_controller.dart (0.0B, 0 lines)
├── model/
│   └── checkout_model.dart (2.4KB, 90 lines)
└── screens/
    ├── checkout_screen.dart (0.0B, 0 lines)
    └── widgets/
```

**Categories Feature**
```
features/categories/
├── controller/
│   └── category_controller.dart (0.0B, 0 lines)
└── models/
    └── category_model.dart (1.8KB, 69 lines)
```

**Media Feature**
```
features/media/
├── controller/
│   └── media_controller.dart (11KB, 399 lines)
└── models/
    ├── image_entity_model.dart (2.1KB, 76 lines)
    └── image_model.dart (2.1KB, 87 lines)
```

**Products Feature**
```
features/products/
├── controller/
├── models/
│   └── product_model.dart (4.2KB, 150 lines)
└── screens/
    ├── product_screen.dart (0.0B, 0 lines)
    └── widgets/
```

**Network Manager**
```
features/network_manager/
└── network_manager.dart (3.5KB, 115 lines)
```

**Home Feature**
```
features/home/
```

**Onboarding Feature**
```
features/on_boarding/
```

#### 2. Data Layer (`lib/data/`)
Data access and repository layer:

```
data/repositories/
└── media/
    └── media_repository.dart (11KB, 403 lines)
```

#### 3. Supabase Integration (`lib/supabase/`)
Backend service integration:

```
supabase/
└── supabase_strings.dart (364B, 8 lines)
```

#### 4. Routing (`lib/routes/`)
Application navigation:

```
routes/
├── app_routes.dart (2.3KB, 44 lines)
└── routes.dart (158B, 9 lines)
```

#### 5. Common Components (`lib/common/`)
Shared UI components and utilities:

**Navigation**
```
common/navigation/
└── navigation_helper.dart (621B, 28 lines)
```

**Styles**
```
common/styles/
├── shadows.dart (522B, 21 lines)
└── spacingstyles.dart (334B, 12 lines)
```

**Widgets**
```
common/widgets/
├── appbar/
│   ├── TAppBar.dart (1.7KB, 57 lines)
│   └── tabbar.dart (949B, 31 lines)
├── brand/
│   └── brand_show_case.dart (1.7KB, 59 lines)
├── chips/
│   └── choice_chip.dart (3.4KB, 94 lines)
├── curved_edges/
│   ├── curved_edges_widget.dart (367B, 18 lines)
│   └── curved_edges.dart (1.1KB, 35 lines)
├── custom_shapes/containers/
│   ├── brand_card.dart (3.3KB, 91 lines)
│   ├── circular_container.dart (878B, 33 lines)
│   ├── primary_header_container.dart (1.1KB, 41 lines)
│   ├── rounded_container.dart (1.3KB, 48 lines)
│   └── search_container.dart (2.6KB, 84 lines)
├── icons/
│   └── t_circular_icon.dart (1.3KB, 54 lines)
├── image_text_widgets/
│   └── vertical_image_text.dart (2.4KB, 71 lines)
├── images/
│   ├── t_circular_image.dart (5.3KB, 140 lines)
│   └── t_rounded_image.dart (1.9KB, 68 lines)
├── layout/
│   └── grid_layout.dart (916B, 31 lines)
├── list_tile/
│   ├── settings_menu_tile.dart (906B, 40 lines)
│   └── user_profile_tile.dart (3.1KB, 90 lines)
├── loaders/
│   ├── animation_loader.dart (1.8KB, 60 lines)
│   └── tloaders.dart (12KB, 394 lines)
├── products/
│   ├── cart/
│   │   ├── add_remove_button.dart (7.7KB, 216 lines)
│   │   ├── cart_item.dart (15KB, 478 lines)
│   │   ├── cart_menu_icon.dart (7.3KB, 226 lines)
│   │   └── coupon_widget.dart (1.8KB, 54 lines)
│   ├── product_cards/
│   │   ├── dynamic_product_card_vertical.dart (4.9KB, 138 lines)
│   │   ├── product-attributes.dart (5.0KB, 149 lines)
│   │   ├── product_card_horizontal.dart (4.8KB, 129 lines)
│   │   ├── product_card_vertical.dart (7.1KB, 174 lines)
│   │   └── product_cart_with_dynamic_image.dart (1.6KB, 54 lines)
│   ├── ratings/
│   │   └── rating_indicator.dart (661B, 26 lines)
│   └── sortable/
│       └── sortable_products.dart (5.3KB, 153 lines)
├── shimmers/
│   └── category_shimmer.dart (1.2KB, 40 lines)
├── success_screen/
│   ├── checkout_success_screen.dart (7.3KB, 192 lines)
│   └── success_screen.dart (1.9KB, 68 lines)
├── texts/
│   ├── brand_title_text.dart (1.2KB, 42 lines)
│   ├── brand_title_with_verification.dart (3.1KB, 95 lines)
│   ├── currency_text.dart (977B, 32 lines)
│   ├── heading_text.dart (1.2KB, 45 lines)
│   ├── product_title_text.dart (689B, 29 lines)
│   └── sections_heading.dart (912B, 32 lines)
├── form_divider.dart (974B, 40 lines)
├── network_aware_widget.dart (2.0KB, 81 lines)
├── network_status_widget.dart (2.0KB, 68 lines)
└── sociol_buttons.dart (1.8KB, 56 lines)
```

#### 6. Utilities (`lib/utils/`)
Application utilities and helpers:

**Constants**
```
utils/constants/
├── api_constants.dart (256B, 9 lines)
├── colors.dart (1.6KB, 51 lines)
├── enums.dart (2.0KB, 113 lines)
├── image_strings.dart (12KB, 264 lines)
├── sizes.dart (1.9KB, 74 lines)
└── text_strings.dart (3.5KB, 72 lines)
```

**Theme**
```
utils/theme/
├── theme.dart (2.0KB, 42 lines)
└── custom_themes/
    ├── appbar_theme.dart (996B, 30 lines)
    ├── bottom_sheet_theme.dart (762B, 21 lines)
    ├── checkbox_theme.dart (1.2KB, 40 lines)
    ├── chip_theme.dart (689B, 20 lines)
    ├── elevated_button_theme.dart (1.3KB, 35 lines)
    ├── outlined_button._theme.dart (1.1KB, 30 lines)
    ├── text_field_theme.dart (2.9KB, 71 lines)
    └── text_theme.dart (2.6KB, 42 lines)
```

**Helpers**
```
utils/helpers/
├── cloud_helper_functions.dart (3.4KB, 89 lines)
├── helper_functions.dart (11KB, 337 lines)
├── network_manager.dart (1.9KB, 53 lines)
└── pricing_calculator.dart (1.7KB, 45 lines)
```

**Exceptions**
```
utils/exceptions/
├── firebase_auth_exceptions.dart (1.5KB, 38 lines)
├── TFirebaseException.dart (718B, 22 lines)
└── TFormatException.dart (582B, 22 lines)
```

**Device & Effects**
```
utils/device/
└── device_utility.dart (3.1KB, 117 lines)

utils/effects/
└── shimmer effect.dart (1.0KB, 33 lines)
```

**Formatters**
```
utils/formatters/
└── formatter.dart (1.8KB, 67 lines)
```

**HTTP & Storage**
```
utils/http/
└── http_client.dart (1.5KB, 48 lines)

utils/local_storage/
└── storage_utility.dart (1.1KB, 53 lines)
```

**Logging**
```
utils/logging/
└── logger.dart (546B, 26 lines)
```

**Popups**
```
utils/popups/
└── full_screen_loader.dart (1.1KB, 42 lines)
```

**Models**
```
utils/model/
```

**Supabase Models**
```
utils/supabase_models/
└── supabase_user_model.dart (0.0B, 0 lines)
```

**Validators**
```
utils/validators/
└── validation.dart (1.8KB, 69 lines)
```

## Architecture Overview

### Feature-Based Architecture
- Each feature is self-contained with its own models, controllers, and screens
- Clear separation between business logic and UI components
- Modular design for easy maintenance and scalability

### Key Features
1. **Cart Management** - Shopping cart functionality with order management
2. **Checkout Process** - Complete checkout flow
3. **Product Catalog** - Product listing and details
4. **Category Management** - Product categorization
5. **Media Handling** - Image and media management
6. **Network Management** - Connectivity and API handling

### Common Components
- Reusable UI widgets for consistent design
- Shared utilities for common functionality
- Theme system for consistent styling
- Navigation helpers for routing

### Data Layer
- Repository pattern for data access
- Supabase integration for backend services
- Local storage utilities for offline functionality

### Utilities
- Comprehensive helper functions
- Exception handling
- Form validation
- Device utilities
- Logging system

## File Size Summary
- **Largest Files:**
  - `cart_item.dart` (15KB) - Complex cart item widget
  - `tloaders.dart` (12KB) - Loading animations
  - `image_strings.dart` (12KB) - Image assets constants
  - `helper_functions.dart` (11KB) - Utility functions
  - `cart_model.dart` (11KB) - Cart data model
  - `media_controller.dart` (11KB) - Media management
  - `media_repository.dart` (11KB) - Media data access

- **Empty Files (0.0B):**
  - Several controller files (cart, checkout, category, order)
  - Screen files (cart, checkout, product)
  - Supabase user model

This structure indicates a well-organized Flutter e-commerce application with comprehensive UI components, proper separation of concerns, and a scalable architecture.

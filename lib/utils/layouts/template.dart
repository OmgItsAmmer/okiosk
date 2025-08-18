import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../helpers/helper_functions.dart';

/// Responsive Layout Template for POS Kiosk Application
///
/// This template provides centralized layout decisions for screens between 15" and 32"
/// with minimum resolution of 1366x768.
class PosLayoutTemplate {
  // Screen size breakpoints for POS kiosk systems
  static const double minKioskWidth = 1366.0;
  static const double minKioskHeight = 768.0;
  static const double largeKioskWidth = 1920.0;
  static const double mediumKioskWidth = 1600.0;

  // Layout ratios for different sections
  static const double productAreaWidthRatio = 0.65; // 65% for product grid
  static const double cartAreaWidthRatio = 0.35; // 35% for cart sidebar

  // Responsive font size multipliers
  static double getResponsiveFontSize(BuildContext context, double baseSize) {
    final screenWidth = THelperFunctions.screenWidth();

    if (screenWidth >= largeKioskWidth) {
      return baseSize * 1.2; // 20% larger for large screens
    } else if (screenWidth >= mediumKioskWidth) {
      return baseSize * 1.1; // 10% larger for medium screens
    } else {
      return baseSize; // Base size for smaller screens
    }
  }

  // Responsive padding
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final screenWidth = THelperFunctions.screenWidth();

    if (screenWidth >= largeKioskWidth) {
      return const EdgeInsets.all(24.0);
    } else if (screenWidth >= mediumKioskWidth) {
      return const EdgeInsets.all(20.0);
    } else {
      return const EdgeInsets.all(16.0);
    }
  }

  // Grid cross axis count based on screen size
  static int getProductGridCrossAxisCount(BuildContext context) {
    final screenWidth = THelperFunctions.screenWidth();
    final productAreaWidth = screenWidth * productAreaWidthRatio;

    if (productAreaWidth >= 1200) {
      return 5; // 5 columns for very wide screens
    } else if (productAreaWidth >= 900) {
      return 4; // 4 columns for wide screens
    } else if (productAreaWidth >= 600) {
      return 3; // 3 columns for medium screens
    } else {
      return 2; // 2 columns for narrow screens
    }
  }

  // Category layout type based on screen size
  static bool shouldUseCategoryWrap(BuildContext context) {
    final screenWidth = THelperFunctions.screenWidth();
    return screenWidth >= mediumKioskWidth; // Use wrap for larger screens
  }

  // Touch target size for kiosk interface
  static double getTouchTargetSize(BuildContext context) {
    final screenWidth = THelperFunctions.screenWidth();

    if (screenWidth >= largeKioskWidth) {
      return 56.0; // Larger touch targets for large screens
    } else {
      return 48.0; // Standard touch target size
    }
  }

  // Cart item height
  static double getCartItemHeight(BuildContext context) {
    final screenHeight = THelperFunctions.screenHeight();

    if (screenHeight >= 1080) {
      return 80.0; // Taller items for high-resolution screens
    } else {
      return 70.0; // Standard height
    }
  }

  // Button sizes
  static Size getCheckoutButtonSize(BuildContext context) {
    final screenWidth = THelperFunctions.screenWidth();
    final cartAreaWidth = screenWidth * cartAreaWidthRatio;

    return Size(
      cartAreaWidth * 0.9, // 90% of cart area width
      getTouchTargetSize(context) + 8, // Touch target + extra padding
    );
  }

  // Responsive spacing
  static double getResponsiveSpacing(BuildContext context, double baseSpacing) {
    final screenWidth = THelperFunctions.screenWidth();

    if (screenWidth >= largeKioskWidth) {
      return baseSpacing * 1.5;
    } else if (screenWidth >= mediumKioskWidth) {
      return baseSpacing * 1.2;
    } else {
      return baseSpacing;
    }
  }

  // Product card size
  static Size getProductCardSize(BuildContext context) {
    final screenWidth = THelperFunctions.screenWidth();
    final productAreaWidth = screenWidth * productAreaWidthRatio;
    final crossAxisCount = getProductGridCrossAxisCount(context);
    final spacing = getResponsiveSpacing(context, 12.0);

    final cardWidth =
        (productAreaWidth - (spacing * (crossAxisCount + 1))) / crossAxisCount;
    final cardHeight = cardWidth * 1.2; // Aspect ratio of 1:1.2

    return Size(cardWidth, cardHeight);
  }

  // Cart sidebar width
  static double getCartSidebarWidth(BuildContext context) {
    final screenWidth = THelperFunctions.screenWidth();
    return screenWidth * cartAreaWidthRatio;
  }

  // Product grid area width
  static double getProductGridWidth(BuildContext context) {
    final screenWidth = THelperFunctions.screenWidth();
    return screenWidth * productAreaWidthRatio;
  }

  // Category bar height
  static double getCategoryBarHeight(BuildContext context) {
    return getTouchTargetSize(context) + 16; // Touch target + padding
  }

  // Main content height (excluding category bar)
  static double getMainContentHeight(BuildContext context) {
    final screenHeight = THelperFunctions.screenHeight();
    final categoryBarHeight = getCategoryBarHeight(context);
    return screenHeight - categoryBarHeight;
  }

  // Responsive border radius
  static double getResponsiveBorderRadius(BuildContext context) {
    final screenWidth = THelperFunctions.screenWidth();

    if (screenWidth >= largeKioskWidth) {
      return 12.0;
    } else if (screenWidth >= mediumKioskWidth) {
      return 10.0;
    } else {
      return 8.0;
    }
  }

  // Check if screen meets minimum kiosk requirements
  static bool isValidKioskScreen(BuildContext context) {
    final screenWidth = THelperFunctions.screenWidth();
    final screenHeight = THelperFunctions.screenHeight();

    // In debug mode, be more flexible with screen size requirements
    if (kDebugMode) {
      // Allow smaller screens in debug mode for development
      return screenWidth >= 1024 && screenHeight >= 600;
    }

    return screenWidth >= minKioskWidth && screenHeight >= minKioskHeight;
  }

  // Get layout warnings for debug purposes
  static List<String> getLayoutWarnings(BuildContext context) {
    final warnings = <String>[];
    final screenWidth = THelperFunctions.screenWidth();
    final screenHeight = THelperFunctions.screenHeight();

    if (kDebugMode) {
      // In debug mode, use more lenient requirements
      if (screenWidth < 1024) {
        warnings.add(
            'Screen width ($screenWidth) is below recommended development width (1024)');
      }
      if (screenHeight < 600) {
        warnings.add(
            'Screen height ($screenHeight) is below recommended development height (600)');
      }
    } else {
      // In production, use strict kiosk requirements
      if (screenWidth < minKioskWidth) {
        warnings.add(
            'Screen width ($screenWidth) is below minimum kiosk width ($minKioskWidth)');
      }
      if (screenHeight < minKioskHeight) {
        warnings.add(
            'Screen height ($screenHeight) is below minimum kiosk height ($minKioskHeight)');
      }
    }

    return warnings;
  }
}

/// Extension on BuildContext for easier access to responsive values
extension ResponsiveContext on BuildContext {
  double responsiveFontSize(double baseSize) =>
      PosLayoutTemplate.getResponsiveFontSize(this, baseSize);
  EdgeInsets get responsivePadding =>
      PosLayoutTemplate.getResponsivePadding(this);
  int get productGridCrossAxisCount =>
      PosLayoutTemplate.getProductGridCrossAxisCount(this);
  bool get shouldUseCategoryWrap =>
      PosLayoutTemplate.shouldUseCategoryWrap(this);
  double get touchTargetSize => PosLayoutTemplate.getTouchTargetSize(this);
  double get cartItemHeight => PosLayoutTemplate.getCartItemHeight(this);
  Size get checkoutButtonSize => PosLayoutTemplate.getCheckoutButtonSize(this);
  Size get productCardSize => PosLayoutTemplate.getProductCardSize(this);
  double get cartSidebarWidth => PosLayoutTemplate.getCartSidebarWidth(this);
  double get productGridWidth => PosLayoutTemplate.getProductGridWidth(this);
  double get categoryBarHeight => PosLayoutTemplate.getCategoryBarHeight(this);
  double get mainContentHeight => PosLayoutTemplate.getMainContentHeight(this);
  double get responsiveBorderRadius =>
      PosLayoutTemplate.getResponsiveBorderRadius(this);
  bool get isValidKioskScreen => PosLayoutTemplate.isValidKioskScreen(this);
  List<String> get layoutWarnings => PosLayoutTemplate.getLayoutWarnings(this);
}

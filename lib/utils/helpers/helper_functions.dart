import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:okiosk/utils/constants/image_strings.dart';
import 'package:okiosk/utils/constants/enums.dart';

/// Helper Functions for the E-commerce App
///
/// This file contains utility functions for common operations including:
/// - Device type detection (Mobile vs Tablet)
/// - Dynamic orientation management
/// - UI utilities and formatters
///
/// Usage Examples:
///
/// ```dart
/// // Check device type
/// bool isTablet = THelperFunctions.isTablet();
/// String deviceType = THelperFunctions.getDeviceType();
///
/// // Manage orientation
/// await THelperFunctions.setOrientationBasedOnDevice(); // Auto-detect and set
/// await OrientationManager.lockOrientation(); // Lock based on device type
/// await OrientationManager.unlockOrientation(); // Allow all orientations
/// await OrientationManager.toggleOrientationLock(); // Toggle lock state
///
/// // Check orientation status
/// bool isLocked = OrientationManager.isOrientationLocked;
/// String deviceType = OrientationManager.currentDeviceType;
/// ```

class THelperFunctions {
  static Color? getColor(String value) {
    /// Define your product specific colors here and it will match the attribute colors and show specific 🟠🟡🟢🔵🟣🟤

    if (value == 'Green') {
      return Colors.green;
    } else if (value == 'Green') {
      return Colors.green;
    } else if (value == 'Red') {
      return Colors.red;
    } else if (value == 'Blue') {
      return Colors.blue;
    } else if (value == 'Pink') {
      return Colors.pink;
    } else if (value == 'Grey') {
      return Colors.grey;
    } else if (value == 'Purple') {
      return Colors.purple;
    } else if (value == 'Black') {
      return Colors.black;
    } else if (value == 'White') {
      return Colors.white;
    } else if (value == 'Yellow') {
      return Colors.yellow;
    } else if (value == 'Orange') {
      return Colors.deepOrange;
    } else if (value == 'Brown') {
      return Colors.brown;
    } else if (value == 'Teal') {
      return Colors.teal;
    } else if (value == 'Indigo') {
      return Colors.indigo;
    } else {
      return null;
    }
  }

  static void showSnackBar(String message) {
    ScaffoldMessenger.of(Get.context!).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  static void showAlert(String title, String message) {
    showDialog(
      context: Get.context!,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  static void navigateToScreen(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    } else {
      return '${text.substring(0, maxLength)}...';
    }
  }

  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Size screenSize() {
    return MediaQuery.of(Get.context!).size;
  }

  static double screenHeight() {
    return MediaQuery.of(Get.context!).size.height;
  }

  static double screenWidth() {
    return MediaQuery.of(Get.context!).size.width;
  }

  static String getFormattedDate(DateTime date,
      {String format = 'dd MMM yyyy'}) {
    return DateFormat(format).format(date);
  }

  static List<T> removeDuplicates<T>(List<T> list) {
    return list.toSet().toList();
  }

  static List<Widget> wrapWidgets(List<Widget> widgets, int rowSize) {
    final wrappedList = <Widget>[];
    for (var i = 0; i < widgets.length; i += rowSize) {
      final rowChildren = widgets.sublist(
          i, i + rowSize > widgets.length ? widgets.length : i + rowSize);
      wrappedList.add(Row(children: rowChildren));
    }
    return wrappedList;
  }

  static String getPaymentMethodIcon(PaymentMethods method) {
    switch (method) {
      case PaymentMethods.paypal:
        return TImages.paypal;
      case PaymentMethods.pickup:
        return TImages.pickup;
      case PaymentMethods.googlePay:
        return TImages.googlePay;
      case PaymentMethods.applePay:
        return TImages.applePay;
      case PaymentMethods.visa:
        return TImages.visa;
      case PaymentMethods.masterCard:
        return TImages.masterCard;
      case PaymentMethods.creditCard:
        return TImages.creditCard;
      case PaymentMethods.paystack:
        return TImages.paystack;

      case PaymentMethods.paytm:
        return TImages.paytm;
      default:
        return TImages.visa; // Default to Visa if no match
    }
  }

  static String calculateDiscountPercentage(
      String basePrice, String salePrice) {
    double base = double.parse(basePrice);
    double sale = double.parse(salePrice);
    double discount = ((base - sale) / base) * 100;
    return discount.toStringAsFixed(0);
  }

  /// Simple mobile detection - only mobile phones get locked orientation
  static bool isMobile() {
    final context = Get.context;
    if (context == null) return false;

    final platform = Theme.of(context).platform;
    final size = MediaQuery.of(context).size;
    final shortestSide = size.shortestSide;

    // Only lock orientation for actual mobile phones (iOS/Android with small screens)
    return (platform == TargetPlatform.iOS ||
            platform == TargetPlatform.android) &&
        shortestSide < 600; // Standard mobile breakpoint
  }

  /// Sets the preferred orientation based on device type
  /// - Mobile phones: Portrait mode only
  /// - Everything else: Free orientation
  static Future<void> setOrientationBasedOnDevice() async {
    if (isMobile()) {
      // Only lock mobile phones to portrait
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } else {
      // Everything else gets free orientation
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  /// Resets orientation to allow all orientations
  static Future<void> resetOrientation() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  /// Gets the current device type as a string
  static String getDeviceType() {
    final context = Get.context;
    if (context == null) return 'Unknown';

    final platform = Theme.of(context).platform;

    // For desktop platforms, return the specific platform
    if (platform == TargetPlatform.windows) return 'Windows';
    if (platform == TargetPlatform.macOS) return 'macOS';
    if (platform == TargetPlatform.linux) return 'Linux';

    // For mobile platforms, check if it's mobile or tablet
    if (platform == TargetPlatform.iOS || platform == TargetPlatform.android) {
      return isMobile() ? 'Mobile' : 'Tablet';
    }

    // For web platform
    if (kIsWeb) return 'Web';

    return 'Unknown';
  }
}

/// Utility class for managing screen orientation
class OrientationManager {
  static bool _isOrientationLocked = false;
  static String _currentDeviceType = '';

  /// Locks orientation based on device type
  static Future<void> lockOrientation() async {
    await THelperFunctions.setOrientationBasedOnDevice();
    _isOrientationLocked = true;
    _currentDeviceType = THelperFunctions.getDeviceType();
  }

  /// Unlocks orientation to allow all orientations
  static Future<void> unlockOrientation() async {
    await THelperFunctions.resetOrientation();
    _isOrientationLocked = false;
  }

  /// Checks if orientation is currently locked
  static bool get isOrientationLocked => _isOrientationLocked;

  /// Gets the current device type
  static String get currentDeviceType => _currentDeviceType;

  /// Toggles orientation lock
  static Future<void> toggleOrientationLock() async {
    if (_isOrientationLocked) {
      await unlockOrientation();
    } else {
      await lockOrientation();
    }
  }
}

/// Example widget showing how to use orientation management
/// This can be used in settings screens or debug panels
class OrientationControlWidget extends StatelessWidget {
  const OrientationControlWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Orientation Control',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Device Type: ${OrientationManager.currentDeviceType}'),
            Text(
                'Orientation Locked: ${OrientationManager.isOrientationLocked ? "Yes" : "No"}'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => OrientationManager.lockOrientation(),
                    child: const Text('Lock'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => OrientationManager.unlockOrientation(),
                    child: const Text('Unlock'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => OrientationManager.toggleOrientationLock(),
                child: const Text('Toggle Lock'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

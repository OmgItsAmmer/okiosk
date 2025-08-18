// import 'package:okiosk/utils/constants/colors.dart';
// import 'package:okiosk/utils/helpers/helper_functions.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:get/get_core/src/get_main.dart';
// import 'package:iconsax/iconsax.dart';

// class TLoader {
//   static hideSnackBar() =>
//       ScaffoldMessenger.of(Get.context!).hideCurrentSnackBar();

//   static customToast({required message}) {
//     ScaffoldMessenger.of(Get.context!).showSnackBar(
//       SnackBar(
//         elevation: 0,
//         duration: const Duration(seconds: 1),
//         backgroundColor: Colors.transparent,
//         content: Container(
//           padding: const EdgeInsets.all(12.0),
//           margin: const EdgeInsets.symmetric(horizontal: 30),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(30),
//             color: THelperFunctions.isDarkMode(Get.context!)
//                 ? TColors.darkerGrey.withOpacity(0.9)
//                 : TColors.grey.withOpacity(0.9),
//           ),
//           child: Center(
//               child: Text(
//             message,
//             style: Theme.of(Get.context!).textTheme.labelLarge,
//           )),
//         ),
//       ),
//     );
//   }

//   static successSnackBar({required title, message = '', duration = 1}) {
//     Get.snackbar(title, message,
//         isDismissible: true,
//         shouldIconPulse: true,
//         colorText: TColors.white,
//         backgroundColor: TColors.primary,
//         snackPosition: SnackPosition.BOTTOM,
//         duration: Duration(seconds: duration),
//         margin: const EdgeInsets.all(20),
//         icon: const Icon(
//           Iconsax.warning_2,
//           color: TColors.white,
//         ));
//   }

//   static warningSnackBar({required title, message = ''}) {
//     Get.snackbar(
//       title,
//       message,
//       isDismissible: true,
//       shouldIconPulse: true,
//       colorText: TColors.white,
//       backgroundColor: Colors.orange,
//       snackPosition: SnackPosition.BOTTOM,
//       duration: const Duration(seconds: 1),
//       margin: const EdgeInsets.all(20),
//       icon: const Icon(Iconsax.warning_2, color: TColors.white),
//     );
//   }

//   static errorSnackBar({required title, message = ''}) {
//     Get.snackbar(
//       title,
//       message,
//       isDismissible: true,
//       shouldIconPulse: true,
//       colorText: TColors.white,
//       backgroundColor: Colors.red.shade600,
//       snackPosition: SnackPosition.BOTTOM,
//       duration: const Duration(seconds: 1),
//       margin: const EdgeInsets.all(20),
//       icon: const Icon(Iconsax.warning_2, color: TColors.white),
//     );
//   }
// }
import 'package:okiosk/utils/constants/colors.dart';
import 'package:okiosk/utils/helpers/helper_functions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class TLoader {
  // Queue to prevent rapid successive calls from interfering
  static bool _isShowingSnackbar = false;
  static final List<Function> _snackbarQueue = [];

  static Future<void> _processQueue() async {
    if (_isShowingSnackbar || _snackbarQueue.isEmpty) return;

    _isShowingSnackbar = true;
    final action = _snackbarQueue.removeAt(0);

    try {
      await action();
      await Future.delayed(
          const Duration(milliseconds: 100)); // Small delay between snackbars
    } catch (e) {
      print('Queued snackbar failed: $e');
    }

    _isShowingSnackbar = false;

    // Process next in queue
    if (_snackbarQueue.isNotEmpty) {
      _processQueue();
    }
  }

  static bool _isContextValid(BuildContext? context) {
    if (context == null) return false;
    try {
      // Try to access context properties to verify it's valid
      return context.mounted && context.widget != null;
    } catch (e) {
      return false;
    }
  }

  static bool _isGetXReady() {
    try {
      return Get.key.currentContext != null || Get.context != null;
    } catch (e) {
      return false;
    }
  }

  static hideSnackBar() {
    try {
      // Try multiple approaches
      if (_isGetXReady()) {
        Get.closeAllSnackbars();
      }
      if (Get.context != null && _isContextValid(Get.context)) {
        ScaffoldMessenger.of(Get.context!).hideCurrentSnackBar();
      }
    } catch (e) {
      print('Failed to hide snackbar: $e');
    }
  }

  static customToast({required String message, BuildContext? context}) {
    _snackbarQueue.add(() async {
      final ctx = context ?? Get.context;

      if (!_isContextValid(ctx)) {
        print('No valid context for toast: $message');
        return;
      }

      try {
        ScaffoldMessenger.of(ctx!).showSnackBar(
          SnackBar(
            elevation: 0,
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.transparent,
            content: Container(
              padding: const EdgeInsets.all(12.0),
              margin: const EdgeInsets.symmetric(horizontal: 30),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: THelperFunctions.isDarkMode(ctx)
                    ? TColors.darkerGrey.withOpacity(0.9)
                    : TColors.grey.withOpacity(0.9),
              ),
              child: Center(
                  child: Text(
                message,
                style: Theme.of(ctx).textTheme.labelLarge,
              )),
            ),
          ),
        );
      } catch (e) {
        // Fallback to GetX snackbar
        if (_isGetXReady()) {
          Get.snackbar('Info', message,
              backgroundColor: TColors.grey.withOpacity(0.9),
              colorText: TColors.white,
              duration: const Duration(seconds: 1));
        } else {
          print('Toast completely failed: $message');
        }
      }
    });

    _processQueue();
  }

  static successSnackBar(
      {required String title, String message = '', int duration = 1}) {
    _snackbarQueue.add(() async {
      try {
        if (_isGetXReady()) {
          Get.snackbar(title, message,
              isDismissible: true,
              shouldIconPulse: true,
              colorText: TColors.white,
              backgroundColor: TColors.primary,
              snackPosition: SnackPosition.BOTTOM,
              duration: Duration(seconds: duration),
              margin: const EdgeInsets.all(20),
              icon: const Icon(Iconsax.check, color: TColors.white));
        } else {
          throw Exception('GetX not ready');
        }
      } catch (e) {
        print('Success snackbar failed, trying fallback: $e');
        _showFallbackDialog(title, message, 'success');
      }
    });

    _processQueue();
  }

  static warningSnackBar({required String title, String message = ''}) {
    _snackbarQueue.add(() async {
      try {
        if (_isGetXReady()) {
          Get.snackbar(
            title,
            message,
            isDismissible: true,
            shouldIconPulse: true,
            colorText: TColors.white,
            backgroundColor: Colors.orange,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 3),
            margin: const EdgeInsets.all(20),
            icon: const Icon(Iconsax.warning_2, color: TColors.white),
          );
        } else {
          throw Exception('GetX not ready');
        }
      } catch (e) {
        print('Warning snackbar failed: $e');
        _showFallbackDialog(title, message, 'warning');
      }
    });

    _processQueue();
  }

  static errorSnackBar({required String title, String message = ''}) {
    _snackbarQueue.add(() async {
      try {
        if (_isGetXReady()) {
          Get.snackbar(
            title,
            message,
            isDismissible: true,
            shouldIconPulse: true,
            colorText: TColors.white,
            backgroundColor: Colors.red.shade600,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 3),
            margin: const EdgeInsets.all(20),
            icon: const Icon(Iconsax.warning_2, color: TColors.white),
          );
        } else {
          throw Exception('GetX not ready');
        }
      } catch (e) {
        print('Error snackbar failed: $e');
        _showFallbackDialog(title, message, 'error');
      }
    });

    _processQueue();
  }

  static void _showFallbackDialog(String title, String message, String type) {
    try {
      final context = Get.context ?? Get.key.currentContext;
      if (_isContextValid(context)) {
        showDialog(
          context: context!,
          builder: (BuildContext dialogContext) {
            Color bgColor;
            IconData icon;

            switch (type) {
              case 'success':
                bgColor = TColors.primary;
                icon = Iconsax.check;
                break;
              case 'warning':
                bgColor = Colors.orange;
                icon = Iconsax.warning_2;
                break;
              case 'error':
              default:
                bgColor = Colors.red.shade600;
                icon = Iconsax.warning_2;
                break;
            }

            return AlertDialog(
              backgroundColor: bgColor,
              title: Row(
                children: [
                  Icon(icon, color: TColors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(color: TColors.white),
                    ),
                  ),
                ],
              ),
              content: message.isNotEmpty
                  ? Text(message, style: const TextStyle(color: TColors.white))
                  : null,
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child:
                      const Text('OK', style: TextStyle(color: TColors.white)),
                ),
              ],
            );
          },
        );
      } else {
        // Ultimate fallback - just print
        print('NOTIFICATION ($type): $title - $message');
      }
    } catch (e) {
      print('Even fallback dialog failed: $e');
      print('NOTIFICATION ($type): $title - $message');
    }
  }

  // Emergency method for critical notifications
  static void criticalNotification(
      {required String title, String message = '', BuildContext? context}) {
    // Try everything in order of preference
    try {
      if (context != null && _isContextValid(context)) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: Text(title),
              content: message.isNotEmpty ? Text(message) : null,
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
        return;
      }
    } catch (e) {
      print('Critical dialog with context failed: $e');
    }

    // Try GetX dialog
    try {
      if (_isGetXReady()) {
        Get.dialog(
          AlertDialog(
            title: Text(title),
            content: message.isNotEmpty ? Text(message) : null,
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('OK'),
              ),
            ],
          ),
          barrierDismissible: false,
        );
        return;
      }
    } catch (e) {
      print('Critical GetX dialog failed: $e');
    }

    // Ultimate fallback
    print('CRITICAL NOTIFICATION: $title - $message');
  }
}

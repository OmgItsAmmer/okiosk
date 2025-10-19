import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Desktop Permission Helper
/// Provides desktop-specific permission handling and debugging
class DesktopPermissionHelper {
  /// Check if we're running on a desktop platform
  static bool get isDesktop {
    return kIsWeb == false &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS);
  }

  /// Get platform-specific permission instructions
  static String getPermissionInstructions() {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return 'Windows: Go to Settings > Privacy > Microphone and enable access for this app';
    } else if (defaultTargetPlatform == TargetPlatform.macOS) {
      return 'macOS: Go to System Preferences > Security & Privacy > Privacy > Microphone and enable access for this app';
    } else if (defaultTargetPlatform == TargetPlatform.linux) {
      return 'Linux: Ensure your user is in the audio group and microphone permissions are granted';
    }
    return 'Please enable microphone permissions in your system settings';
  }

  /// Check microphone permission with detailed debugging
  static Future<PermissionStatus> checkMicrophonePermission() async {
    try {
      debugPrint(
          '🔍 Desktop Permission Helper: Checking microphone permission...');
      final status = await Permission.microphone.status;
      debugPrint('📊 Desktop Permission Helper: Permission status = $status');

      if (isDesktop) {
        debugPrint(
            '🖥️ Desktop Permission Helper: Running on desktop platform');
        debugPrint(
            '💡 Desktop Permission Helper: ${getPermissionInstructions()}');
      }

      return status;
    } catch (e) {
      debugPrint('❌ Desktop Permission Helper: Error checking permission: $e');
      return PermissionStatus.denied;
    }
  }

  /// Request microphone permission with detailed debugging
  static Future<PermissionStatus> requestMicrophonePermission() async {
    try {
      debugPrint(
          '🔐 Desktop Permission Helper: Requesting microphone permission...');
      final status = await Permission.microphone.request();
      debugPrint(
          '📊 Desktop Permission Helper: Permission request result = $status');

      if (status.isPermanentlyDenied) {
        debugPrint(
            '❌ Desktop Permission Helper: Permission permanently denied');
        debugPrint(
            '💡 Desktop Permission Helper: ${getPermissionInstructions()}');
      }

      return status;
    } catch (e) {
      debugPrint(
          '❌ Desktop Permission Helper: Error requesting permission: $e');
      return PermissionStatus.denied;
    }
  }

  /// Get detailed permission diagnostics
  static Future<Map<String, dynamic>> getPermissionDiagnostics() async {
    final diagnostics = <String, dynamic>{};

    try {
      diagnostics['isDesktop'] = isDesktop;
      diagnostics['platform'] = defaultTargetPlatform.name;
      diagnostics['microphoneStatus'] =
          (await Permission.microphone.status).toString();
      diagnostics['permissionInstructions'] = getPermissionInstructions();

      // Check if permission handler is working
      try {
        await Permission.microphone.status;
        diagnostics['permissionHandlerWorking'] = true;
      } catch (e) {
        diagnostics['permissionHandlerWorking'] = false;
        diagnostics['permissionHandlerError'] = e.toString();
      }
    } catch (e) {
      diagnostics['error'] = e.toString();
    }

    return diagnostics;
  }
}

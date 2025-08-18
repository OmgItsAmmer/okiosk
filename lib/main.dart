import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'package:get_storage/get_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

import 'supabase/supabase_strings.dart';

// Supabase
final supabase = Supabase.instance.client;

Future<void> main() async {
  final WidgetsBinding widgetsBinding =
      WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await GetStorage.init();

  try {
    await Supabase.initialize(
      url: SupabaseStrings.projectUrl,
      anonKey: SupabaseStrings.anonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
      ),
      storageOptions: const StorageClientOptions(
        retryAttempts: 10,
      ),
    );

    // await Firebase.initializeApp(
    //   options: DefaultFirebaseOptions.currentPlatform,
    // );

    //  await _setupNotifications();

    // Get.put(AuthenticationRepository());
    // Remove the preserved native splash so the first frame can be drawn
    FlutterNativeSplash.remove();
    runApp(const App());
  } catch (e, s) {
    debugPrint('🔥 Initialization Error: $e');
    debugPrintStack(stackTrace: s);
  }
}

// Future<void> _setupNotifications() async {
//   // 🔐 Request permission
//   NotificationSettings settings = await messaging.requestPermission(
//     alert: true,
//     badge: true,
//     sound: true,
//   );

//   if (settings.authorizationStatus == AuthorizationStatus.authorized) {
//     if (kDebugMode) {
//       print('✅ Notification permission granted');
//     }
//   } else {
//     if (kDebugMode) {
//       print('❌ Notification permission denied');
//     }
//   }

//   // // 📣 Create Android notification channel
//   const AndroidNotificationChannel channel = AndroidNotificationChannel(
//     'high_importance_channel', // MUST match the channel_id in FCM payload
//     'High Importance Notifications',
//     description: 'Used for order updates and urgent alerts.',
//     importance: Importance.high,
//   );

//   await flutterLocalNotificationsPlugin
//       .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
//       ?.createNotificationChannel(channel);

//   // 🎯 Handle foreground messages
//   FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//     RemoteNotification? notification = message.notification;

//     if (notification != null) {
//       flutterLocalNotificationsPlugin.show(
//         notification.hashCode,
//         notification.title,
//         notification.body,
//         NotificationDetails(
//           android: AndroidNotificationDetails(
//             channel.id,
//             channel.name,
//             channelDescription: channel.description,
//             importance: Importance.high,
//             priority: Priority.high,
//             icon: '@mipmap/ic_launcher',
//           ),
//         ),
//       );
//     }
//   });
// }

import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../../features/cart/controller/cart_controller.dart';
import '../../main.dart';

RealtimeChannel? _cartChannel;

void startCartRealtime() {
  try {
    final cartController = Get.find<CartController>();
    final sessionId = cartController.kioskUUID; // Use kiosk's own UUID

    if (sessionId.isEmpty) {
      if (kDebugMode) {
        print('KioskCartRealtime: Cannot start realtime - session ID is empty');
      }
      return;
    }

    // Stop any existing channel first
    stopCartRealtime();

    if (kDebugMode) {
      print(
          'KioskCartRealtime: Starting realtime subscription for session: $sessionId');
    }

    _cartChannel =
        supabase.channel('kiosk-cart-$sessionId') // unique channel name
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
              try {
                if (kDebugMode) {
                  print('KioskCartRealtime: Insert detected: $payload');
                }
                await cartController.fetchKioskCartBySession(sessionId);
              } catch (e) {
                if (kDebugMode) {
                  print('KioskCartRealtime: Error handling insert: $e');
                }
              }
            },
          )
          ..onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'kiosk_cart',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'kiosk_session_id',
              value: sessionId,
            ),
            callback: (payload) async {
              try {
                if (kDebugMode) {
                  print('KioskCartRealtime: Update detected: $payload');
                }
                await cartController.fetchKioskCartBySession(sessionId);
              } catch (e) {
                if (kDebugMode) {
                  print('KioskCartRealtime: Error handling update: $e');
                }
              }
            },
          )
          ..onPostgresChanges(
            event: PostgresChangeEvent.delete,
            schema: 'public',
            table: 'kiosk_cart',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'kiosk_session_id',
              value: sessionId,
            ),
            callback: (payload) async {
              try {
                if (kDebugMode) {
                  print('KioskCartRealtime: Delete detected: $payload');
                }
                await cartController.fetchKioskCartBySession(sessionId);
              } catch (e) {
                if (kDebugMode) {
                  print('KioskCartRealtime: Error handling delete: $e');
                }
              }
            },
          ).subscribe((status, [err]) {
            if (status == RealtimeSubscribeStatus.subscribed) {
              if (kDebugMode) {
                print(
                    'KioskCartRealtime: Successfully subscribed for session: $sessionId');
              }
              // Don't fetch immediately on subscription to avoid startup errors
              // The cart will be fetched when actual changes occur
            } else if (err != null) {
              if (kDebugMode) {
                print('KioskCartRealtime: Subscription error: $err');
              }
            }
          });
  } catch (e) {
    if (kDebugMode) {
      print('KioskCartRealtime: Failed to start realtime: $e');
    }
  }
}

void stopCartRealtime() {
  if (_cartChannel != null) {
    supabase.removeChannel(_cartChannel!);
    _cartChannel = null;
  }
}

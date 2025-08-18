import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:okiosk/routes/routes.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../common/widgets/loaders/tloaders.dart';

class NetworkManager extends GetxController {
  static NetworkManager get instance => Get.find();

  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  final Rx<ConnectivityResult> _connectionStatus = ConnectivityResult.none.obs;
  final RxBool _isInternetAvailable = false.obs;
  final RxBool _isRedirecting = false.obs;

  ConnectivityResult get connectionStatus => _connectionStatus.value;
  bool get isInternetAvailable => _isInternetAvailable.value;
  bool get isRedirecting => _isRedirecting.value;

  @override
  void onInit() {
    super.onInit();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatusWithRetry);
    _checkInitialConnection();
  }

  Future<void> _checkInitialConnection() async {
    await Future.delayed(const Duration(seconds: 2)); // 🕒 Give time for network to initialize
    final result = await _connectivity.checkConnectivity();
    await _updateConnectionStatusWithRetry(result);
  }

  Future<void> _updateConnectionStatusWithRetry(ConnectivityResult result) async {
    _connectionStatus.value = result;

    if (result == ConnectivityResult.none) {
      _isInternetAvailable.value = false;
      _redirectToLogin();
      return;
    }

    // 🔁 Retry internet access check up to 3 times
    for (int i = 0; i < 3; i++) {
      final hasInternet = await _checkInternetAccess();
      if (hasInternet) {
        _isInternetAvailable.value = true;
        return;
      }
      await Future.delayed(const Duration(seconds: 2));
    }

    // ❌ Still no internet after retries
    _isInternetAvailable.value = false;
    _redirectToLogin();
  }

  Future<bool> _checkInternetAccess() async {
    try {
      final response = await http.get(
        Uri.parse('https://www.google.com'),
        headers: {'Cache-Control': 'no-cache'},
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  void _redirectToLogin() {
    if (!_isRedirecting.value) {
      _isRedirecting.value = true;

      TLoader.errorSnackBar(
        title: 'No internet connection',
        message: 'Please check your internet connection and try again',
      );

      // 🔁 Redirect only if needed (can be replaced with offline page)
      Future.delayed(const Duration(seconds: 1), () {
       // Get.offAllNamed(TRoutes.signIn); // 🚨 Replace with offline screen if you prefer
        _isRedirecting.value = false;
      });
    }
  }

  // ✅ External method to check current connection
  Future<bool> isConnected() async {
    try {
      final result = await _connectivity.checkConnectivity();
      if (result == ConnectivityResult.none) return false;
      return await _checkInternetAccess();
    } on PlatformException catch (_) {
      return false;
    }
  }

  // ✅ Manual check trigger
  Future<void> checkAndRedirectIfNeeded() async {
    final connected = await isConnected();
    if (!connected) _redirectToLogin();
  }

  @override
  void onClose() {
    _connectivitySubscription.cancel();
    super.onClose();
  }
}

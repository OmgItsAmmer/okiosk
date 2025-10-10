import 'package:flutter/material.dart';

import '../di/backend_dependency_injection.dart';

/// Example of how to initialize backend services in your app
class BackendInitializationExample {
  /// Initialize backend services with default configuration
  static void initializeDefault() {
    // Initialize backend services
    BackendDependencyInjection.init();

    print('Backend services initialized with default configuration');
  }

  /// Initialize backend services with custom base URL
  static void initializeWithCustomUrl(String baseUrl) {
    // Set custom base URL
    // Note: You would need to modify BackendConfig to accept custom URLs
    // or create a new configuration class for this

    // Initialize backend services
    BackendDependencyInjection.init();

    print('Backend services initialized with custom URL: $baseUrl');
  }

  /// Example of how to use in main.dart
  static void exampleMainFunction() {
    // This is how you would typically initialize in main.dart
    /*
    void main() {
      WidgetsFlutterBinding.ensureInitialized();
      
      // Initialize backend services
      BackendInitializationExample.initializeDefault();
      
      runApp(MyApp());
    }
    */
  }
}

/// Example widget showing how to use the backend services
class BackendExampleWidget extends StatelessWidget {
  const BackendExampleWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backend Integration Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Backend services are initialized!'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Example of using the backend services
                _testBackendServices();
              },
              child: const Text('Test Backend Services'),
            ),
          ],
        ),
      ),
    );
  }

  void _testBackendServices() {
    try {
      // Example of how to use the backend services
      // Note: These would be called from your controllers
      print('Testing backend services...');

      // The controllers will automatically use the backend services
      // when you call methods like:
      // - ProductController.instance.loadPopularProductsLazily()
      // - ProductVariationController.instance.fetchProductVariantByProductId()

      print('Backend services are working!');
    } catch (e) {
      print('Error testing backend services: $e');
    }
  }
}

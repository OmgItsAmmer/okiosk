import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_windows/webview_windows.dart';

class WebViewExample extends StatefulWidget {
  const WebViewExample({super.key});

  @override
  State<WebViewExample> createState() => _WebViewExampleState();
}

class _WebViewExampleState extends State<WebViewExample> {
  late final WebviewController _controller;
  bool _isInitialized = false;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = WebviewController();
    _initializeWebView();
  }

  Future<void> _initializeWebView() async {
    try {
      // Small delay to ensure platform is ready
      await Future.delayed(const Duration(milliseconds: 100));

      await _controller.initialize();
      await _controller.loadUrl('http://localhost:5173/');

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      if (mounted) {
        setState(() {
          _error = 'Failed to initialize WebView: $e\n\n'
              'Please ensure:\n'
              '1. The app was fully rebuilt (not hot reloaded)\n'
              '2. WebView2 runtime is installed\n'
              '3. You are running on Windows desktop\n\n'
              'Stack trace: $stackTrace';
          _isLoading = false;
        });
      }
      debugPrint('WebView initialization error: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'WebView Error',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: SelectableText(
                  _error!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.red.shade900,
                        fontFamily: 'monospace',
                      ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading || !_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 200, // Fixed height for embedded view in voice assistant section
      child: Webview(_controller),
    );
  }
}

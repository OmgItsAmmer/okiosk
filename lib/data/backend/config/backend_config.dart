/// Configuration class for backend API settings
class BackendConfig {
  /// Base URL for the backend API
  static const String baseUrl = 'http://localhost:3000'; // Development URL

  /// Production URL (uncomment when deploying)
  // static const String baseUrl = 'https://your-production-domain.com';

  /// API timeout duration
  static const Duration timeout = Duration(seconds: 30);

  /// Enable debug logging
  static const bool enableDebugLogging = true;

  /// API version (your backend doesn't use versioning yet)
  static const String apiVersion = 'v1';

  /// Get the full API base URL with version
  static String get apiBaseUrl => '$baseUrl/api/$apiVersion';

  /// Get the full API base URL without version (use this for your current backend)
  static String get baseApiUrl => '$baseUrl/api';
}

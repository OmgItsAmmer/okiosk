import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../models/api_response.dart';
import '../config/backend_config.dart';

/// Base API client for backend communication
class ApiClient {
  static String _baseUrl = BackendConfig.baseUrl;
  static const Duration _timeout = BackendConfig.timeout;

  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  /// Set the base URL for API calls
  static void setBaseUrl(String baseUrl) {
    _baseUrl = baseUrl;
  }

  /// Get the current base URL
  static String get baseUrl => _baseUrl;

  /// Generic GET request
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParams);
      final response = await _client
          .get(uri, headers: _buildHeaders(headers))
          .timeout(_timeout);

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      if (kDebugMode) {
        print('API GET Error: $e');
      }
      return ApiResponse<T>(
        success: false,
        message: 'Network error: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  /// Generic POST request
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final response = await _client
          .post(
            uri,
            headers: _buildHeaders(headers),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout);

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      if (kDebugMode) {
        print('API POST Error: $e');
      }
      return ApiResponse<T>(
        success: false,
        message: 'Network error: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  /// Generic PUT request
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final response = await _client
          .put(
            uri,
            headers: _buildHeaders(headers),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout);

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      if (kDebugMode) {
        print('API PUT Error: $e');
      }
      return ApiResponse<T>(
        success: false,
        message: 'Network error: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  /// Generic DELETE request
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    Map<String, String>? headers,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final response = await _client
          .delete(uri, headers: _buildHeaders(headers))
          .timeout(_timeout);

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      if (kDebugMode) {
        print('API DELETE Error: $e');
      }
      return ApiResponse<T>(
        success: false,
        message: 'Network error: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  /// Build URI with query parameters
  Uri _buildUri(String endpoint, [Map<String, dynamic>? queryParams]) {
    final uri = Uri.parse('$_baseUrl$endpoint');
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: {
        ...uri.queryParameters,
        ...queryParams.map((key, value) => MapEntry(key, value.toString())),
      });
    }
    return uri;
  }

  /// Build headers with default content type
  Map<String, String> _buildHeaders(Map<String, String>? customHeaders) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?customHeaders,
    };
  }

  /// Handle HTTP response and convert to ApiResponse
  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(dynamic)? fromJson,
  ) {
    try {
      final String bodyText = response.body;

      // if (kDebugMode) {
      //   print('ApiClient: ========== RAW RESPONSE ==========');
      //   print('ApiClient: Status Code: ${response.statusCode}');
      //   print('ApiClient: Body Length: ${bodyText.length}');
      //   print('ApiClient: Body: $bodyText');
      //   print('ApiClient: ====================================');
      // }

      // Success HTTP status
      final bool isOk = response.statusCode >= 200 && response.statusCode < 300;

      // Fast paths for top-level array or primitive payloads
      if (bodyText.trim().startsWith('[')) {
        final List<dynamic> listJson = jsonDecode(bodyText) as List<dynamic>;
        return ApiResponse<T>(
          success: isOk,
          message: isOk ? 'Success' : 'Request failed',
          data: fromJson != null ? fromJson(listJson) : (listJson as dynamic),
          statusCode: response.statusCode,
        );
      }

      // Parse as JSON object
      final dynamic decoded = jsonDecode(bodyText);

      if (decoded is Map<String, dynamic>) {
        final Map<String, dynamic> jsonResponse = decoded;

        // If backend wraps payload in { success, data, message }
        final bool hasWrappedData = jsonResponse.containsKey('data');
        final bool hasSuccessFlag = jsonResponse.containsKey('success');

        if (isOk) {
          final dynamic rawData =
              hasWrappedData ? jsonResponse['data'] : jsonResponse;
          final T? parsedData =
              fromJson != null ? fromJson(rawData) : rawData as T?;
          return ApiResponse<T>(
            success: hasSuccessFlag ? (jsonResponse['success'] == true) : true,
            message: (jsonResponse['message'] as String?) ?? 'Success',
            data: parsedData,
            statusCode: response.statusCode,
            errors: jsonResponse['errors'] as Map<String, dynamic>?,
          );
        } else {
          return ApiResponse<T>(
            success: false,
            message: (jsonResponse['message'] as String?) ?? 'Request failed',
            statusCode: response.statusCode,
            errors: jsonResponse['errors'] as Map<String, dynamic>?,
          );
        }
      }

      // Fallback: unknown payload type
      if (kDebugMode) {
        print('ApiClient: WARNING - Unexpected response shape');
        print('ApiClient: Response body: ${response.body}');
        print('ApiClient: Decoded type: ${decoded.runtimeType}');
      }
      return ApiResponse<T>(
        success: isOk,
        message: isOk ? 'Success' : 'Request failed',
        statusCode: response.statusCode,
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('ApiClient: ❌ PARSING ERROR ❌');
        print('ApiClient: Error: $e');
        print('ApiClient: Error Type: ${e.runtimeType}');
        print('ApiClient: Response Body: ${response.body}');
        print('ApiClient: Stack Trace: $stackTrace');
      }
      // Provide more detailed error information
      String errorMessage = 'Failed to parse response: ${e.toString()}';
      if (e
          .toString()
          .contains('type \'String\' is not a subtype of type \'Map')) {
        errorMessage =
            'Backend returned string response instead of JSON: ${response.body}';
      }

      return ApiResponse<T>(
        success: false,
        message: errorMessage,
        statusCode: response.statusCode,
      );
    }
  }

  /// Dispose the HTTP client
  void dispose() {
    _client.close();
  }
}

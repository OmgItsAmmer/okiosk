import 'package:get/get.dart';
import 'package:flutter/foundation.dart';

import 'api_client.dart';
import '../models/api_response.dart';

/// AI Command Service - Handles AI natural language processing
///
/// This service communicates with the Rust backend AI module
/// Endpoint: POST /api/ai/command
class AiCommandService {
  final ApiClient _apiClient = Get.find<ApiClient>();

  /// Process natural language command
  ///
  /// Endpoint: POST /api/ai/command
  /// Handles both kiosk mode (session_id) and authenticated mode (customer_id)
  ///
  /// Request body matches the Rust backend AI specification:
  /// {
  ///   "prompt": string,           // User's natural language command
  ///   "session_id": string?,      // Optional: For kiosk mode
  ///   "customer_id": int?         // Optional: For authenticated users
  /// }
  Future<ApiResponse<AiCommandResponse>> processCommand({
    required String prompt,
    String? sessionId,
    int? customerId,
  }) async {
    try {
      if (kDebugMode) {
        print('AiCommandService: Processing command: "$prompt"');
        print('AiCommandService: Session ID: $sessionId');
        print('AiCommandService: Customer ID: $customerId');
      }

      final requestBody = <String, dynamic>{
        'prompt': prompt,
      };

      // Add session_id for kiosk mode
      if (sessionId != null && sessionId.isNotEmpty) {
        requestBody['session_id'] = sessionId;
      }

      // Add customer_id for authenticated mode
      if (customerId != null) {
        requestBody['customer_id'] = customerId;
      }

      final response = await _apiClient.post<AiCommandResponse>(
        '/api/ai/command',
        body: requestBody,
        fromJson: (data) => AiCommandResponse.fromJson(data),
      );

      if (kDebugMode) {
        print('AiCommandService: Response success: ${response.success}');
        print('AiCommandService: Response message: ${response.message}');
        if (response.data != null) {
          print(
              'AiCommandService: Actions executed: ${response.data!.actionsExecuted}');
        }
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('AiCommandService: Error processing command: $e');
      }
      return ApiResponse<AiCommandResponse>(
        success: false,
        message: 'Failed to process AI command: ${e.toString()}',
        statusCode: 0,
      );
    }
  }
}

/// AI Command Response Model
///
/// Matches the response format from the Rust backend AI module
class AiCommandResponse {
  final bool success;
  final String message;
  final List<String> actionsExecuted;
  final String? error;

  AiCommandResponse({
    required this.success,
    required this.message,
    required this.actionsExecuted,
    this.error,
  });

  factory AiCommandResponse.fromJson(Map<String, dynamic> json) {
    return AiCommandResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? 'No message',
      actionsExecuted: json['actions_executed'] != null
          ? List<String>.from(json['actions_executed'])
          : [],
      error: json['error'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'actions_executed': actionsExecuted,
      'error': error,
    };
  }

  @override
  String toString() {
    return 'AiCommandResponse(success: $success, message: $message, actionsExecuted: $actionsExecuted, error: $error)';
  }
}

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'api_client.dart';
import 'ai_action_executor.dart';
import '../models/api_response.dart';
import '../models/ai_command_response_model.dart';
import '../models/ai_action_model.dart';

/// AI Command Service with Action Response Support
///
/// This service handles the action response format from the backend where actions are
/// returned as JSON strings in the actions_executed array. The frontend parses these
/// strings and executes the actions locally without database persistence.
///
/// ## Key Features:
///
/// 1. **JSON String Actions**: Backend returns actions as JSON strings in actions_executed array
/// 2. **Frontend Execution**: Frontend parses and executes actions locally
/// 3. **Stock Validation**: Backend validates stock and returns validated product data
/// 4. **Error Handling**: Each action has its own success/failure status and error messages
///
/// ## Supported Action Types:
///
/// - `add_to_cart`: Add validated products to local cart
/// - `remove_from_cart`: Remove products from local cart
/// - `update_quantity`: Update product quantities in local cart
/// - `clear_cart`: Clear all items from local cart
/// - `view_cart`: Display current cart contents
/// - `search_product`: Show search results for products
/// - `show_menu`: Display menu items
/// - `generate_bill`: Prepare cart for bill generation
/// - `checkout`: Initiate checkout process
///
/// ## Response Format:
///
/// ```json
/// {
///   "success": true,
///   "message": "Ready to add 2 Large Pizza to cart",
///   "actions_executed": [
///     "{\"action_type\":\"add_to_cart\",\"success\":true,\"message\":\"Ready to add 2 Large Pizza to cart\",\"data\":{\"variant_id\":123,\"product_name\":\"Large Pizza\",\"variant_name\":\"Large\",\"quantity\":2,\"available_stock\":50,\"sell_price\":15.99,\"session_id\":\"session-uuid\",\"customer_id\":null},\"error\":null}"
///   ],
///   "error": null
/// }
/// ```

/// AI Command Service - Handles AI natural language processing
///
/// This service communicates with the Rust backend AI module
/// Endpoint: POST /api/ai/command
///
/// ## Usage Example:
///
/// ```dart
/// final aiService = Get.find<AiCommandService>();
///
/// // Process voice command and execute actions automatically
/// final result = await aiService.processCommandAndExecute(
///   prompt: "add 2 large pizzas to cart",
///   sessionId: "kiosk-session-123",
/// );
///
/// if (result.success) {
///   // Actions were executed automatically
///   // AI message is available in result.message
///   print('AI Response: ${result.message}');
/// } else {
///   // Handle error
///   print('Error: ${result.message}');
/// }
/// ```
class AiCommandService {
  final ApiClient _apiClient = Get.find<ApiClient>();
  final AiActionExecutor _actionExecutor = Get.find<AiActionExecutor>();

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

      return response;
    } catch (e) {
      return ApiResponse<AiCommandResponse>(
        success: false,
        message: 'Failed to process AI command: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  /// Process natural language command and automatically execute actions
  ///
  /// This method processes the command and automatically executes all successful actions
  /// returned by the AI. This is the preferred method for most use cases as it handles
  /// the complete flow from command processing to action execution.
  ///
  /// @param prompt The user's natural language command
  /// @param sessionId Optional session ID for kiosk mode
  /// @param customerId Optional customer ID for authenticated mode
  /// @return Future<ProcessResult> Contains success status and AI message
  Future<ProcessResult> processCommandAndExecute({
    required String prompt,
    String? sessionId,
    int? customerId,
  }) async {
    try {
      // First, process the command to get actions
      final response = await processCommand(
        prompt: prompt,
        sessionId: sessionId,
        customerId: customerId,
      );

      if (!response.success || response.data == null) {
        return ProcessResult(
          success: false,
          message: response.message.isNotEmpty
              ? response.message
              : 'Failed to process command',
        );
      }
      if (kDebugMode) {
        print('AI Command Service: Response: ${response.toString()}');
        print('AI Command Service: Response success: ${response.success}');
        print('AI Command Service: Response message: ${response.message}');
        print(
            'AI Command Service: Response data type: ${response.data.runtimeType}');
      }
      final aiResponse = response.data!;

      if (kDebugMode) {
        print(
            'AI Command Service: Raw actions count: ${aiResponse.actionsExecutedRaw.length}');
        print('AI Command Service: AI response message: ${aiResponse.message}');
        for (int i = 0; i < aiResponse.actionsExecutedRaw.length; i++) {
          print(
              'AI Command Service: Raw action $i: ${aiResponse.actionsExecutedRaw[i]}');
        }
      }

      // Execute all actions from JSON strings (as returned by backend)
      // Updated to handle the new backend response format from CART_AI_MODULE.md
      // Variant selection actions should be executed to show UI, but not add to cart
      final results = await _actionExecutor
          .executeActionsFromStrings(aiResponse.actionsExecutedRaw);

      // Return result with AI message and parsed actions
      final allSuccess = results.every((result) => result);
      return ProcessResult(
        success: allSuccess,
        message: aiResponse.message,
        actionsExecuted: aiResponse.actionsExecuted,
      );
    } catch (e) {
      return ProcessResult(
        success: false,
        message: 'Error: ${e.toString()}',
      );
    }
  }
}

/// Result of processing and executing an AI command
class ProcessResult {
  final bool success;
  final String message;
  final List<AiAction>? actionsExecuted;

  ProcessResult({
    required this.success,
    required this.message,
    this.actionsExecuted,
  });
}

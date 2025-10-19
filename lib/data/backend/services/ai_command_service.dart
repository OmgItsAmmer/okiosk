import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'api_client.dart';
import 'ai_action_executor.dart';
import '../models/api_response.dart';
import '../models/ai_command_response_model.dart';
import '../models/ai_action_model.dart';
import '../models/action_data_models.dart';

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

      if (kDebugMode) {
        print('========== AI COMMAND REQUEST ==========');
        print('AiCommandService: Sending AI command');
        print('AiCommandService: Prompt: $prompt');
        print('AiCommandService: Session ID: $sessionId');
        print('AiCommandService: Customer ID: $customerId');
        print('AiCommandService: Request body: $requestBody');
        print('AiCommandService: Endpoint: POST /api/ai/command');
        print('========================================');
      }

      final response = await _apiClient.post<AiCommandResponse>(
        '/api/ai/command',
        body: requestBody,
        fromJson: (data) => AiCommandResponse.fromJson(data),
      );

      if (kDebugMode) {
        print('========== AI COMMAND RESPONSE ==========');
        print('AiCommandService: Response success: ${response.success}');
        print('AiCommandService: Response message: ${response.message}');
        print('AiCommandService: Status code: ${response.statusCode}');
        print('AiCommandService: Has data: ${response.data != null}');
        if (response.data != null) {
          print(
              'AiCommandService: Actions count: ${response.data!.actionsExecutedRaw.length}');
          print(
              'AiCommandService: AI response message: ${response.data!.message}');
          print(
              'AiCommandService: AI response success: ${response.data!.success}');
          print(
              'AiCommandService: Format valid: ${response.data!.isValidFormat}');

          if (response.data!.error != null) {
            print(
                'AiCommandService: AI response error: ${response.data!.error}');
          }

          // Check for validation errors
          final validationErrors = response.data!.validationErrors;
          if (validationErrors.isNotEmpty) {
            print('AiCommandService: Validation errors:');
            for (final error in validationErrors) {
              print('AiCommandService: - $error');
            }
          }

          // Print each action string for debugging
          for (int i = 0; i < response.data!.actionsExecutedRaw.length; i++) {
            print(
                'AiCommandService: Action $i: ${response.data!.actionsExecutedRaw[i]}');
          }
        }
        print('=========================================');
      }

      return response;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('========== AI COMMAND ERROR ==========');
        print('AiCommandService: Exception type: ${e.runtimeType}');
        print('AiCommandService: Exception: $e');
        print('AiCommandService: Stack trace: $stackTrace');
        print('AiCommandService: Request that failed:');
        print('AiCommandService: - Prompt: $prompt');
        print('AiCommandService: - Session ID: $sessionId');
        print('AiCommandService: - Customer ID: $customerId');
        print('AiCommandService: - Endpoint: POST /api/ai/command');
        print('======================================');
      }

      // Provide more specific error messages based on exception type
      String errorMessage;
      if (e.toString().contains('FormatException')) {
        errorMessage =
            'Backend returned invalid JSON format. Please check backend response structure.';
      } else if (e.toString().contains('SocketException')) {
        errorMessage =
            'Network connection failed. Please check your internet connection and backend server status.';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Request timed out. Backend server may be overloaded.';
      } else {
        errorMessage = 'Failed to process AI command: ${e.toString()}';
      }

      return ApiResponse<AiCommandResponse>(
        success: false,
        message: errorMessage,
        statusCode: 0,
      );
    }
  }

  /// Confirm variant selection in sequential queue orchestration
  ///
  /// Endpoint: POST /api/ai/variant-confirm
  /// Used in the new sequential queue approach where backend sends ONE product at a time
  /// Frontend confirms each variant selection, and backend returns the next product or completion
  ///
  /// Request body:
  /// {
  ///   "action": "variant_selection",
  ///   "status": "success" | "cancel",
  ///   "product_name": string,      // Product name being confirmed
  ///   "variant_id": int?,          // Selected variant ID (if status is success)
  ///   "session_id": string         // Session ID
  /// }
  ///
  /// Response:
  /// {
  ///   "success": true,
  ///   "message": "Product added! Select next variant",
  ///   "has_more": true,            // If there are more items in queue
  ///   "next_action": {             // Next product to select (if has_more is true)
  ///     "action_type": "variant_selection",
  ///     "data": { ... }
  ///   }
  /// }
  Future<VariantConfirmResponse> confirmVariantSelection({
    required String productName,
    required String sessionId,
    int? variantId,
    int? quantity,
    bool cancel = false,
  }) async {
    try {
      final requestBody = <String, dynamic>{
        'action': 'variant_selection',
        'status': cancel ? 'cancel' : 'success',
        'product_name': productName,
        'session_id': sessionId,
      };

      // Add variant_id and quantity only if not cancelling
      if (!cancel && variantId != null) {
        requestBody['variant_id'] = variantId;
      }

      if (!cancel && quantity != null) {
        requestBody['quantity'] = quantity;
      }

      if (kDebugMode) {
        print('====== VARIANT CONFIRMATION REQUEST ======');
        print('AiCommandService: Confirming variant selection');
        print('AiCommandService: Product Name: $productName');
        print('AiCommandService: Session ID: $sessionId');
        print('AiCommandService: Variant ID: $variantId');
        print('AiCommandService: Cancel: $cancel');
        print('AiCommandService: Full Request Body: $requestBody');
        print('==========================================');
      }

      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/ai/variant-confirm',
        body: requestBody,
        fromJson: (data) => data as Map<String, dynamic>,
      );

      if (kDebugMode) {
        print('====== VARIANT CONFIRMATION RESPONSE ======');
        print('AiCommandService: Response success: ${response.success}');
        print('AiCommandService: Response message: ${response.message}');
        print('AiCommandService: Response status code: ${response.statusCode}');
        print('AiCommandService: Response data: ${response.data}');
        print('============================================');
      }

      if (!response.success || response.data == null) {
        final errorMessage = response.message.isNotEmpty
            ? response.message
            : 'Failed to confirm variant selection';

        if (kDebugMode) {
          print('AiCommandService: Confirmation failed: $errorMessage');
          print('AiCommandService: Status code: ${response.statusCode}');
        }

        return VariantConfirmResponse(
          success: false,
          message: errorMessage,
          hasMore: false,
          error: errorMessage,
        );
      }

      final data = response.data!;

      final confirmResponse = VariantConfirmResponse(
        success: true,
        message: data['message'] ?? 'Variant confirmed',
        hasMore: data['has_more'] ?? false,
        nextAction: data['next_action'] != null
            ? AiAction.fromJson(data['next_action'])
            : null,
      );

      if (kDebugMode) {
        print('AiCommandService: Confirmation successful');
        print('AiCommandService: Has more items: ${confirmResponse.hasMore}');
        print(
            'AiCommandService: Next action: ${confirmResponse.nextAction?.actionType}');
      }

      return confirmResponse;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('====== VARIANT CONFIRMATION ERROR ======');
        print('AiCommandService: Exception during confirmation: $e');
        print('AiCommandService: Stack trace: $stackTrace');
        print('=========================================');
      }
      return VariantConfirmResponse(
        success: false,
        message: 'Failed to confirm variant selection: ${e.toString()}',
        hasMore: false,
        error: e.toString(),
      );
    }
  }

  /// Process natural language command and automatically execute actions
  ///
  /// This method processes the command and automatically executes all successful actions
  /// returned by the AI using a queue-based approach. This supports handling multiple
  /// actions like "add lux and rice into cart" where the backend processes multiple
  /// functions in sequence.
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

      // Validate response format
      if (!response.data!.isValidFormat) {
        final validationErrors = response.data!.validationErrors;
        if (kDebugMode) {
          print('AiCommandService: Invalid response format detected');
          for (final error in validationErrors) {
            print('AiCommandService: Validation error: $error');
          }
        }
        return ProcessResult(
          success: false,
          message:
              'Backend returned invalid response format. Errors: ${validationErrors.join(", ")}',
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

      // Execute all actions from JSON strings using queue-based approach
      // This supports multiple actions like "add lux and rice into cart"
      // where the backend processes multiple functions in sequence
      final results = await _actionExecutor
          .executeActionsFromStrings(aiResponse.actionsExecutedRaw);

      // Calculate execution statistics
      final hasActions = aiResponse.actionsExecutedRaw.isNotEmpty;
      final successfulActions = results.where((result) => result).length;
      final allSuccess = hasActions ? results.every((result) => result) : true;

      if (kDebugMode) {
        print('AI Command Service: Queue execution completed');
        print(
            'AI Command Service: Total actions: ${aiResponse.actionsExecutedRaw.length}');
        print('AI Command Service: Successful actions: $successfulActions');
        print('AI Command Service: All successful: $allSuccess');
      }

      return ProcessResult(
        success: allSuccess,
        message: aiResponse.message,
        actionsExecuted: aiResponse.actionsExecuted,
        actionsCount: aiResponse.actionsExecutedRaw.length,
        successfulActionsCount: successfulActions,
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
///
/// Supports both single actions and queue-based multiple actions
/// like "add lux and rice into cart" where multiple backend functions
/// are processed in sequence.
class ProcessResult {
  final bool success;
  final String message;
  final List<AiAction>? actionsExecuted;
  final int? actionsCount;
  final int? successfulActionsCount;

  ProcessResult({
    required this.success,
    required this.message,
    this.actionsExecuted,
    this.actionsCount,
    this.successfulActionsCount,
  });

  /// Check if this result has any actions
  bool get hasActions => actionsExecuted != null && actionsExecuted!.isNotEmpty;

  /// Check if this is a message-only response
  bool get isMessageOnly => !hasActions;

  /// Get the count of actions executed
  int get totalActionsCount => actionsCount ?? (actionsExecuted?.length ?? 0);

  /// Get the count of successful actions
  int get totalSuccessfulActions =>
      successfulActionsCount ??
      (actionsExecuted?.where((action) => action.success).length ?? 0);

  /// Check if all actions were successful
  bool get allActionsSuccessful => hasActions
      ? (actionsExecuted?.every((action) => action.success) ?? false)
      : true;
}

/// Response from variant confirmation endpoint
///
/// Used in sequential queue orchestration when frontend confirms a variant selection
class VariantConfirmResponse {
  final bool success;
  final String message;
  final bool hasMore;
  final AiAction? nextAction;
  final String? error;

  VariantConfirmResponse({
    required this.success,
    required this.message,
    required this.hasMore,
    this.nextAction,
    this.error,
  });

  /// Check if there's a next product to select
  bool get hasNextAction => hasMore && nextAction != null;

  /// Get variant selection data from next action
  VariantSelectionActionData? get nextVariantData =>
      nextAction?.variantSelectionData;
}

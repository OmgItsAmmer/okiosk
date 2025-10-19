import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'action_data_models.dart';
import 'search_models.dart';

/// AI Action Model
///
/// Represents a single action that the frontend should execute
/// Contains action type, success status, message, data, and error information
class AiAction {
  final String actionType;
  final bool success;
  final String message;
  final Map<String, dynamic>? data;
  final String? error;

  AiAction({
    required this.actionType,
    required this.success,
    required this.message,
    this.data,
    this.error,
  });

  factory AiAction.fromJson(dynamic json) {
    // Handle case where json is not a Map
    if (json is! Map<String, dynamic>) {
      return AiAction(
        actionType: 'unknown',
        success: false,
        message: 'Invalid action format: ${json.runtimeType}',
        data: null,
        error: 'Expected Map<String, dynamic>, got ${json.runtimeType}',
      );
    }

    final Map<String, dynamic> jsonMap = json;

    return AiAction(
      actionType: jsonMap['action_type'] ?? 'unknown',
      success: jsonMap['success'] ?? false,
      message: jsonMap['message'] ?? 'No message',
      data: jsonMap['data'],
      error: jsonMap['error'],
    );
  }

  /// Parse AI action from JSON string (as returned by backend)
  factory AiAction.fromJsonString(String jsonString) {
    if (kDebugMode) {
      print('========== AI ACTION JSON STRING PARSING ==========');
      print('AiAction: Parsing JSON string: $jsonString');
      print('AiAction: String length: ${jsonString.length}');
    }

    // Check if string is empty or null
    if (jsonString.isEmpty) {
      if (kDebugMode) {
        print('AiAction: Empty JSON string provided');
      }
      return AiAction(
        actionType: 'parse_error',
        success: false,
        message: 'Empty JSON string provided',
        data: null,
        error: 'Empty JSON string',
      );
    }

    try {
      // Try to parse the JSON string
      final dynamic json = jsonDecode(jsonString);

      if (kDebugMode) {
        print('AiAction: Successfully decoded JSON');
        print('AiAction: Decoded type: ${json.runtimeType}');
        print('AiAction: Decoded content: $json');
      }

      // Handle case where JSON is not a Map
      if (json is! Map<String, dynamic>) {
        if (kDebugMode) {
          print('AiAction: JSON is not a Map, got ${json.runtimeType}');
        }
        return AiAction(
          actionType: 'parse_error',
          success: false,
          message: 'JSON string does not contain a valid action object',
          data: null,
          error: 'Expected Map<String, dynamic>, got ${json.runtimeType}',
        );
      }

      // Parse the action using the main fromJson method
      final action = AiAction.fromJson(json);

      if (kDebugMode) {
        print('AiAction: Successfully parsed action');
        print('AiAction: Action type: ${action.actionType}');
        print('AiAction: Action success: ${action.success}');
        print('AiAction: Action message: ${action.message}');
        print('AiAction: Has data: ${action.data != null}');
        print('AiAction: Error: ${action.error}');
        print('===============================================');
      }

      return action;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('AiAction: JSON parsing failed');
        print('AiAction: Error: $e');
        print('AiAction: Stack trace: $stackTrace');
        print('AiAction: Original string: $jsonString');
        print('===============================================');
      }

      return AiAction(
        actionType: 'parse_error',
        success: false,
        message: 'Failed to parse action JSON string',
        data: null,
        error: 'JSON parse error: $e',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'action_type': actionType,
      'success': success,
      'message': message,
      'data': data,
      'error': error,
    };
  }

  @override
  String toString() {
    return 'AiAction(type: $actionType, success: $success, message: $message, hasData: ${data != null}, error: $error)';
  }

  /// Helper method to get typed data for add_to_cart actions
  AddToCartActionData? get addToCartData {
    if (actionType != 'add_to_cart' || data == null) return null;
    try {
      return AddToCartActionData.fromJson(data!);
    } catch (e) {
      return null;
    }
  }

  /// Helper method to get typed data for remove_from_cart actions
  RemoveFromCartActionData? get removeFromCartData {
    if (actionType != 'remove_from_cart' || data == null) return null;
    try {
      return RemoveFromCartActionData.fromJson(data!);
    } catch (e) {
      return null;
    }
  }

  /// Helper method to get typed data for update_quantity actions
  UpdateQuantityActionData? get updateQuantityData {
    if (actionType != 'update_quantity' || data == null) return null;
    try {
      return UpdateQuantityActionData.fromJson(data!);
    } catch (e) {
      return null;
    }
  }

  /// Helper method to get typed data for search_product actions
  SearchProductActionData? get searchProductData {
    if (actionType != 'search_product' || data == null) return null;
    try {
      return SearchProductActionData.fromJson(data!);
    } catch (e) {
      return null;
    }
  }

  /// Helper method to get typed data for variant_selection actions (single item)
  VariantSelectionActionData? get variantSelectionData {
    if (actionType != 'variant_selection' || data == null) return null;
    try {
      return VariantSelectionActionData.fromJson(data!);
    } catch (e) {
      return null;
    }
  }

  /// Helper method to get typed data for multi-variant selection (multiple items)
  /// Detects the new backend response format from CART_AI_MODULE.md
  MultiVariantSelectionData? get multiVariantSelectionData {
    // Check if data contains 'pending_selections' field (new multi-variant format)
    if (data == null || !data!.containsKey('pending_selections')) return null;
    try {
      return MultiVariantSelectionData.fromJson(data!);
    } catch (e) {
      return null;
    }
  }

  /// Check if this action requires variant selection (single item)
  bool get requiresVariantSelection =>
      actionType == 'variant_selection' &&
      success &&
      !requiresSequentialVariantSelection;

  /// Check if this action requires sequential variant selection (NEW - queue-based)
  /// Based on FRONTEND_MULTI_VARIANT_SOLUTION.md: detects 'queue_info' field
  /// This is the NEW approach where backend sends ONE product at a time
  bool get requiresSequentialVariantSelection =>
      actionType == 'variant_selection' &&
      success &&
      data != null &&
      data!.containsKey('queue_info');

  /// Check if this action requires multi-variant selection (multiple items)
  /// Based on CART_AI_MODULE.md: detects 'pending_selections' field
  /// DEPRECATED: Backend now uses sequential queue orchestration instead
  bool get requiresMultiVariantSelection =>
      success && data != null && data!.containsKey('pending_selections');

  /// Check if this is a successful add_to_cart action
  bool get isSuccessfulAddToCart => actionType == 'add_to_cart' && success;

  /// Check if this is a failed add_to_cart action
  bool get isFailedAddToCart => actionType == 'add_to_cart' && !success;

  /// Get error message for failed actions
  String get errorMessage => error ?? 'Unknown error occurred';

  /// Check if this action has valid data
  bool get hasValidData => data != null && data!.isNotEmpty;

  /// Check if this is an add_to_cart action
  bool get isAddToCart => actionType == 'add_to_cart';

  /// Check if this is a remove_from_cart action
  bool get isRemoveFromCart => actionType == 'remove_from_cart';

  /// Check if this is an update_quantity action
  bool get isUpdateQuantity => actionType == 'update_quantity';

  /// Check if this is a clear_cart action
  bool get isClearCart => actionType == 'clear_cart';

  /// Check if this is a view_cart action
  bool get isViewCart => actionType == 'view_cart';

  /// Check if this is a search_product action
  bool get isSearchProduct => actionType == 'search_product';

  /// Check if this is a variant_selection action
  bool get isVariantSelection => actionType == 'variant_selection';

  /// Check if this is a generate_bill action
  bool get isGenerateBill => actionType == 'generate_bill';

  /// Check if this is a checkout action
  bool get isCheckout => actionType == 'checkout';

  /// Get response type for frontend detection
  /// Based on CART_AI_MODULE.md Response Format Types
  ResponseType get responseType {
    if (requiresMultiVariantSelection) {
      return ResponseType.multiVariantSelection;
    } else if (requiresVariantSelection) {
      return ResponseType.singleVariantSelection;
    } else {
      return ResponseType.standardSuccess;
    }
  }

  /// Check if this is a multi-variant selection action
  bool get isMultiVariantSelection => requiresMultiVariantSelection;
}

/// Response Type Enum
///
/// Defines the different response formats based on CART_AI_MODULE.md
enum ResponseType {
  /// Single item variant selection: action_type == 'variant_selection'
  singleVariantSelection,

  /// Multiple items variant selection: pending_selections != null
  multiVariantSelection,

  /// Standard success: neither above
  standardSuccess,
}

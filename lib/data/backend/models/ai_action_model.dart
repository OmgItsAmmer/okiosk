import 'dart:convert';
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
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      return AiAction.fromJson(json);
    } catch (e) {
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

  /// Check if this is a generate_bill action
  bool get isGenerateBill => actionType == 'generate_bill';

  /// Check if this is a checkout action
  bool get isCheckout => actionType == 'checkout';
}

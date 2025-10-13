import 'ai_action_model.dart';

/// AI Command Response Model
///
/// Matches the new action response format from the Rust backend AI module
/// The backend returns actions_executed as an array of JSON strings that need to be parsed individually
class AiCommandResponse {
  final bool success;
  final String message;
  final List<String> actionsExecutedRaw; // Raw JSON strings from backend
  final String? error;

  AiCommandResponse({
    required this.success,
    required this.message,
    required this.actionsExecutedRaw,
    this.error,
  });

  factory AiCommandResponse.fromJson(dynamic json) {
    // Handle case where backend returns a string instead of JSON
    if (json is String) {
      return AiCommandResponse(
        success: true, // Treat string responses as successful messages
        message: json,
        actionsExecutedRaw: [],
        error: null,
      );
    }

    // Handle case where json is not a Map
    if (json is! Map<String, dynamic>) {
      return AiCommandResponse(
        success: false,
        message: 'Invalid response format: ${json.runtimeType}',
        actionsExecutedRaw: [],
        error: 'Expected Map<String, dynamic>, got ${json.runtimeType}',
      );
    }

    final Map<String, dynamic> jsonMap = json;

    return AiCommandResponse(
      success: jsonMap['success'] ?? false,
      message: jsonMap['message'] ?? 'No message',
      actionsExecutedRaw: jsonMap['actions_executed'] != null
          ? (jsonMap['actions_executed'] as List)
              .map((action) => action.toString())
              .toList()
          : [],
      error: jsonMap['error'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'actions_executed': actionsExecutedRaw,
      'error': error,
    };
  }

  /// Parse the raw JSON strings into AiAction objects
  List<AiAction> get actionsExecuted {
    final List<AiAction> parsedActions = [];

    for (final actionString in actionsExecutedRaw) {
      try {
        final action = AiAction.fromJsonString(actionString);
        parsedActions.add(action);
      } catch (e) {
        // Create an error action for failed parsing
        parsedActions.add(AiAction(
          actionType: 'parse_error',
          success: false,
          message: 'Failed to parse action: $actionString',
          error: 'Parse error: $e',
        ));
      }
    }

    return parsedActions;
  }

  @override
  String toString() {
    return 'AiCommandResponse(success: $success, message: $message, actionsExecuted: ${actionsExecuted.length} actions, error: $error)';
  }

  /// Get all successful actions
  List<AiAction> get successfulActions =>
      actionsExecuted.where((action) => action.success).toList();

  /// Get all failed actions
  List<AiAction> get failedActions =>
      actionsExecuted.where((action) => !action.success).toList();

  /// Get actions by type
  List<AiAction> getActionsByType(String actionType) => actionsExecuted
      .where((action) => action.actionType == actionType)
      .toList();

  /// Get the first action of a specific type
  AiAction? getFirstActionByType(String actionType) {
    try {
      return actionsExecuted
          .firstWhere((action) => action.actionType == actionType);
    } catch (e) {
      return null;
    }
  }

  /// Check if there are any actions of a specific type
  bool hasActionType(String actionType) =>
      actionsExecuted.any((action) => action.actionType == actionType);

  /// Get all add_to_cart actions
  List<AiAction> get addToCartActions => getActionsByType('add_to_cart');

  /// Get all remove_from_cart actions
  List<AiAction> get removeFromCartActions =>
      getActionsByType('remove_from_cart');

  /// Get all update_quantity actions
  List<AiAction> get updateQuantityActions =>
      getActionsByType('update_quantity');

  /// Get all search_product actions
  List<AiAction> get searchProductActions => getActionsByType('search_product');
}

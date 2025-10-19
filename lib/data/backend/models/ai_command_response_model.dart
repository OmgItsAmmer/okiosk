import 'dart:convert';
import 'package:flutter/foundation.dart';
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
    if (kDebugMode) {
      print('========== AI COMMAND RESPONSE PARSING ==========');
      print('AiCommandResponse: Received JSON type: ${json.runtimeType}');
      print('AiCommandResponse: Received JSON: $json');
    }

    // Handle case where backend returns a string instead of JSON
    if (json is String) {
      if (kDebugMode) {
        print('AiCommandResponse: Treating as string response');
      }
      return AiCommandResponse(
        success: true, // Treat string responses as successful messages
        message: json,
        actionsExecutedRaw: [],
        error: null,
      );
    }

    // Handle case where json is not a Map
    if (json is! Map<String, dynamic>) {
      if (kDebugMode) {
        print(
            'AiCommandResponse: Invalid JSON type - Expected Map, got ${json.runtimeType}');
      }
      return AiCommandResponse(
        success: false,
        message: 'Invalid response format: ${json.runtimeType}',
        actionsExecutedRaw: [],
        error: 'Expected Map<String, dynamic>, got ${json.runtimeType}',
      );
    }

    final Map<String, dynamic> jsonMap = json;

    // Validate required fields
    final success = jsonMap['success'];
    final message = jsonMap['message'];
    final actionsExecuted = jsonMap['actions_executed'];
    final error = jsonMap['error'];

    if (kDebugMode) {
      print(
          'AiCommandResponse: Success field: $success (${success.runtimeType})');
      print(
          'AiCommandResponse: Message field: $message (${message.runtimeType})');
      print(
          'AiCommandResponse: Actions field: $actionsExecuted (${actionsExecuted.runtimeType})');
      print('AiCommandResponse: Error field: $error (${error.runtimeType})');
    }

    // Parse actions_executed field with better error handling
    List<String> actionsList = [];
    if (actionsExecuted != null) {
      if (actionsExecuted is List) {
        for (int i = 0; i < actionsExecuted.length; i++) {
          final action = actionsExecuted[i];
          if (kDebugMode) {
            print(
                'AiCommandResponse: Action $i: $action (${action.runtimeType})');
          }

          // Convert to string safely
          if (action is String) {
            actionsList.add(action);
          } else if (action is Map<String, dynamic>) {
            // If action is already a Map, convert to JSON string
            try {
              final jsonString = jsonEncode(action);
              actionsList.add(jsonString);
            } catch (e) {
              if (kDebugMode) {
                print(
                    'AiCommandResponse: Failed to convert action $i to JSON string: $e');
              }
              actionsList.add(action.toString());
            }
          } else {
            // For any other type, convert to string
            actionsList.add(action.toString());
          }
        }
      } else {
        if (kDebugMode) {
          print(
              'AiCommandResponse: actions_executed is not a List: ${actionsExecuted.runtimeType}');
        }
        // Try to convert to string anyway
        actionsList.add(actionsExecuted.toString());
      }
    }

    final response = AiCommandResponse(
      success: success is bool ? success : false,
      message: message is String ? message : 'No message',
      actionsExecutedRaw: actionsList,
      error: error is String ? error : null,
    );

    if (kDebugMode) {
      print('AiCommandResponse: Parsed successfully');
      print('AiCommandResponse: Success: ${response.success}');
      print('AiCommandResponse: Message: ${response.message}');
      print(
          'AiCommandResponse: Actions count: ${response.actionsExecutedRaw.length}');
      print('AiCommandResponse: Error: ${response.error}');
      print('================================================');
    }

    return response;
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'actions_executed': actionsExecutedRaw,
      'error': error,
    };
  }

  /// Validate that the response format matches expected backend format
  bool get isValidFormat {
    // Check if we have the required fields
    if (message.isEmpty) return false;

    // For actions_executed, it should be a list of strings (JSON strings)
    for (final actionString in actionsExecutedRaw) {
      if (actionString.isEmpty) return false;

      // Try to parse each action string to validate it's valid JSON
      try {
        jsonDecode(actionString);
      } catch (e) {
        if (kDebugMode) {
          print(
              'AiCommandResponse: Invalid JSON string in actions_executed: $actionString');
          print('AiCommandResponse: Parse error: $e');
        }
        return false;
      }
    }

    return true;
  }

  /// Get validation errors for debugging
  List<String> get validationErrors {
    final errors = <String>[];

    if (message.isEmpty) {
      errors.add('Message field is empty');
    }

    for (int i = 0; i < actionsExecutedRaw.length; i++) {
      final actionString = actionsExecutedRaw[i];
      if (actionString.isEmpty) {
        errors.add('Action $i is empty');
      } else {
        try {
          jsonDecode(actionString);
        } catch (e) {
          errors.add('Action $i has invalid JSON: $e');
        }
      }
    }

    return errors;
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

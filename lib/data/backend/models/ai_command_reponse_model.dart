// /// AI Command Response Model
// ///
// /// Matches the new action response format from the Rust backend AI module
// /// Each action contains structured data that the frontend can execute
// class AiCommandResponse {
//   final bool success;
//   final String message;
//   final List<AiAction> actionsExecuted;
//   final String? error;

//   AiCommandResponse({
//     required this.success,
//     required this.message,
//     required this.actionsExecuted,
//     this.error,
//   });

//   factory AiCommandResponse.fromJson(dynamic json) {
//     // Handle case where backend returns a string instead of JSON
//     // if (json is String) {
//     //   return AiCommandResponse(
//     //     success: false,
//     //     message: json,
//     //     actionsExecuted: [],
//     //     error: 'Backend returned string response instead of JSON',
//     //   );
//     // }

//     // Handle case where json is not a Map
//     if (json is! Map<String, dynamic>) {
//       return AiCommandResponse(
//         success: false,
//         message: 'Invalid response format: ${json.runtimeType}',
//         actionsExecuted: [],
//         error: 'Expected Map<String, dynamic>, got ${json.runtimeType}',
//       );
//     }

//     final Map<String, dynamic> jsonMap = json;

//     return AiCommandResponse(
//       success: jsonMap['success'] ?? false,
//       message: jsonMap['message'] ?? 'No message',
//       actionsExecuted: jsonMap['actions_executed'] != null
//           ? (jsonMap['actions_executed'] as List)
//               .map((action) => AiAction.fromJson(action))
//               .toList()
//           : [],
//       error: jsonMap['error'],
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'success': success,
//       'message': message,
//       'actions_executed':
//           actionsExecuted.map((action) => action.toJson()).toList(),
//       'error': error,
//     };
//   }

//   @override
//   String toString() {
//     return 'AiCommandResponse(success: $success, message: $message, actionsExecuted: ${actionsExecuted.length} actions, error: $error)';
//   }

//   /// Get all successful actions
//   List<AiAction> get successfulActions =>
//       actionsExecuted.where((action) => action.success).toList();

//   /// Get all failed actions
//   List<AiAction> get failedActions =>
//       actionsExecuted.where((action) => !action.success).toList();

//   /// Get actions by type
//   List<AiAction> getActionsByType(String actionType) => actionsExecuted
//       .where((action) => action.actionType == actionType)
//       .toList();

//   /// Get the first action of a specific type
//   AiAction? getFirstActionByType(String actionType) {
//     try {
//       return actionsExecuted
//           .firstWhere((action) => action.actionType == actionType);
//     } catch (e) {
//       return null;
//     }
//   }

//   /// Check if there are any actions of a specific type
//   bool hasActionType(String actionType) =>
//       actionsExecuted.any((action) => action.actionType == actionType);

//   /// Get all add_to_cart actions
//   List<AiAction> get addToCartActions => getActionsByType('add_to_cart');

//   /// Get all remove_from_cart actions
//   List<AiAction> get removeFromCartActions =>
//       getActionsByType('remove_from_cart');

//   /// Get all update_quantity actions
//   List<AiAction> get updateQuantityActions =>
//       getActionsByType('update_quantity');

//   /// Get all search_product actions
//   List<AiAction> get searchProductActions => getActionsByType('search_product');
// }
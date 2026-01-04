import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../data/backend/services/ai_command_service.dart';
import '../../../data/backend/models/action_data_models.dart';
import '../../../features/cart/controller/cart_controller.dart';
import '../models/chat_message.dart';

/// Chat Controller - Manages AI assistant chat state and API calls
///
/// Handles:
/// - Chat message history
/// - Sending messages to AI backend
/// - Managing loading states
/// - Error handling
class ChatController extends GetxController {
  final AiCommandService _aiCommandService = Get.find<AiCommandService>();

  // Observable lists for reactive UI
  final RxList<ChatMessage> _messages = <ChatMessage>[].obs;

  // Public getter for messages observable
  RxList<ChatMessage> get messagesObservable => _messages;
  final RxBool _isLoading = false.obs;
  final RxBool _isTyping = false.obs;
  final RxString _currentSessionId = ''.obs;

  // Getters
  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading.value;
  bool get isTyping => _isTyping.value;
  String get currentSessionId => _currentSessionId.value;

  @override
  void onInit() {
    super.onInit();
    _initializeChat();
  }

  /// Initialize chat with welcome message
  void _initializeChat() {
    // Generate unique session ID for kiosk mode
    _currentSessionId.value = 'kiosk-${DateTime.now().millisecondsSinceEpoch}';

    // Add welcome message
    _addSystemMessage('Welcome! I\'m your AI assistant. You can ask me to:\n\n'
        '• Add items to cart: "Add 2 burgers to cart"\n'
        '• Remove items: "Remove burger from cart"\n'
        '• Generate bill: "Bill bana do" or "Generate bill"\n'
        '• Show cart: "Cart dikha do" or "Show cart"\n'
        '• Clear cart: "Cart khali kar do" or "Clear cart"\n'
        '• Search products: "Find pizza" or "Burger search karo"\n\n'
        'You can mix English and Urdu in your commands!');
  }

  /// Send a message to the AI assistant
  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty || _isLoading.value) return;

    // Add user message to chat
    _addUserMessage(message.trim());

    // Set loading state
    _isLoading.value = true;
    _isTyping.value = true;

    try {
      if (kDebugMode) {
        print('========== SENDING AI COMMAND ==========');
        print('ChatController: Message: ${message.trim()}');
        print('ChatController: Session ID: ${_currentSessionId.value}');
        print('========================================');
      }

      // Send message to AI backend and execute actions automatically
      final result = await _aiCommandService.processCommandAndExecute(
        prompt: message.trim(),
        sessionId: _currentSessionId.value,
      );

      // Remove typing indicator
      _isTyping.value = false;

      if (kDebugMode) {
        print('========== AI COMMAND RESULT ==========');
        print('ChatController: Success: ${result.success}');
        print('ChatController: Message: ${result.message}');
        print('ChatController: Actions count: ${result.totalActionsCount}');
        print('=======================================');
      }

      if (result.success) {
        // Detection logic based on FRONTEND_MULTI_VARIANT_SOLUTION.md
        // Priority order:
        // 1. Sequential variant selection (queue_info != null) - NEW
        // 2. Multi-variant selection (pending_selections != null) - DEPRECATED
        // 3. Single variant selection (action_type == 'variant_selection')
        // 4. Standard success (neither above)

        final sequentialVariantAction = result.actionsExecuted
            ?.where((action) => action.requiresSequentialVariantSelection)
            .firstOrNull;

        final multiVariantAction = result.actionsExecuted
            ?.where((action) => action.requiresMultiVariantSelection)
            .firstOrNull;

        final singleVariantAction = result.actionsExecuted
            ?.where((action) => action.requiresVariantSelection)
            .firstOrNull;

        if (sequentialVariantAction != null) {
          // NEW: Handle sequential variant selection (queue-based)
          // User command: "add lux and rice to cart" (2+ items with variants)
          // Backend sends ONE product at a time
          if (kDebugMode) {
            print('========== SEQUENTIAL VARIANT DETECTED ==========');
            print('ChatController: Sequential variant selection detected');
            final data = sequentialVariantAction.variantSelectionData;
            if (data != null && data.queueInfo != null) {
              print(
                  'ChatController: Queue position: ${data.queueInfo!.position}/${data.queueInfo!.total}');
              print('ChatController: Product: ${data.productName}');
              print(
                  'ChatController: Remaining: ${data.queueInfo!.remaining.join(", ")}');
              print(
                  'ChatController: Session ID will be: ${_currentSessionId.value}');
            }
            print('=================================================');
          }

          addAssistantMessage(
            result.message,
            actionsExecuted: ['sequential_variant_selection'],
            variantSelectionData: sequentialVariantAction.variantSelectionData,
          );
        } else if (multiVariantAction != null) {
          // DEPRECATED: Handle multiple items variant selection (old format)
          // User command: "add lux and rice to cart" (2+ items with variants)
          if (kDebugMode) {
            print(
                'ChatController: Multi-variant selection detected (DEPRECATED)');
            final data = multiVariantAction.multiVariantSelectionData;
            if (data != null) {
              print(
                  'ChatController: Total items requiring selection: ${data.totalItems}');
              print(
                  'ChatController: Products: ${data.productNames.join(", ")}');
            }
          }

          addAssistantMessage(
            result.message,
            actionsExecuted: ['multi_variant_selection'],
            multiVariantSelectionData:
                multiVariantAction.multiVariantSelectionData,
          );
        } else if (singleVariantAction != null) {
          // Handle single item variant selection (original format)
          // User command: "add lux to cart" (1 item with variants)
          if (kDebugMode) {
            print('ChatController: Single variant selection detected');
            final data = singleVariantAction.variantSelectionData;
            if (data != null) {
              print('ChatController: Product: ${data.productName}');
              print(
                  'ChatController: Available variants: ${data.totalVariants}');
            }
          }

          addAssistantMessage(
            result.message,
            actionsExecuted: ['variant_selection'],
            variantSelectionData: singleVariantAction.variantSelectionData,
          );
        } else {
          // Handle queue-based multiple actions or single action responses
          final hasActions = result.actionsExecuted != null &&
              result.actionsExecuted!.isNotEmpty;
          final actionTypes = result.actionsExecuted
                  ?.map((action) => action.actionType)
                  .toList() ??
              [];

          if (hasActions) {
            // Add AI message with executed actions info
            addAssistantMessage(
              result.message,
              actionsExecuted: actionTypes,
            );

            if (kDebugMode) {
              print('ChatController: Queue-based execution completed');
              print(
                  'ChatController: Total actions: ${result.totalActionsCount}');
              print(
                  'ChatController: Successful actions: ${result.totalSuccessfulActions}');
              print('ChatController: Action types: $actionTypes');
              print(
                  'ChatController: All actions successful: ${result.allActionsSuccessful}');
            }
          } else {
            // Message-only response (no actions to execute)
            addAssistantMessage(
              result.message,
              actionsExecuted: ['message_only'],
            );

            if (kDebugMode) {
              print(
                  'ChatController: Message-only response (no actions to execute)');
            }
          }
        }
      } else {
        // Add error message
        _addErrorMessage(
          result.message.isNotEmpty
              ? result.message
              : 'Sorry, I couldn\'t process your request. Please try again.',
        );
      }
    } catch (e) {
      _isTyping.value = false;
      if (kDebugMode) {
        print('ChatController: Error sending message: $e');
      }
      _addErrorMessage(
        'Network error. Please check your connection and try again.',
      );
    } finally {
      _isLoading.value = false;
    }
  }

  /// Add user message to chat
  void _addUserMessage(String content) {
    final message = ChatMessage.user(content: content);
    _messages.add(message);

    if (kDebugMode) {
      print('ChatController: Added user message: $content');
    }
  }

  /// Add AI assistant message to chat
  /// Updated to support both single and multi-variant selection based on CART_AI_MODULE.md
  void addAssistantMessage(
    String content, {
    List<String>? actionsExecuted,
    VariantSelectionActionData? variantSelectionData,
    MultiVariantSelectionData? multiVariantSelectionData,
  }) {
    final message = ChatMessage.assistant(
      content: content,
      actionsExecuted: actionsExecuted,
      variantSelectionData: variantSelectionData,
      multiVariantSelectionData: multiVariantSelectionData,
    );
    _messages.add(message);

    if (kDebugMode) {
      print('ChatController: Added assistant message: $content');
      if (actionsExecuted != null && actionsExecuted.isNotEmpty) {
        print('ChatController: Actions executed: $actionsExecuted');
      }
      if (variantSelectionData != null) {
        print('ChatController: Single variant selection data attached');
      }
      if (multiVariantSelectionData != null) {
        print('ChatController: Multi-variant selection data attached');
      }
    }
  }

  /// Add system message to chat
  void _addSystemMessage(String content) {
    final message = ChatMessage.system(content: content);
    _messages.add(message);

    if (kDebugMode) {
      print('ChatController: Added system message: $content');
    }
  }

  /// Add error message to chat
  void _addErrorMessage(String content) {
    final message = ChatMessage.error(content: content);
    _messages.add(message);

    if (kDebugMode) {
      print('ChatController: Added error message: $content');
    }
  }

  /// Confirm variant selection in sequential queue
  /// Called when user selects a variant from sequential variant dialog
  Future<void> confirmSequentialVariant({
    required String productName,
    required int variantId,
    required int quantity,
  }) async {
    try {
      if (kDebugMode) {
        print('========== SEQUENTIAL VARIANT CONFIRMATION ==========');
        print('ChatController: Confirming sequential variant selection');
        print('ChatController: Product: $productName');
        print('ChatController: Variant ID: $variantId');
        print('ChatController: Quantity: $quantity');
        print('ChatController: Session ID: ${_currentSessionId.value}');
        print('=====================================================');
      }

      // Show loading
      _isLoading.value = true;

      // Call backend to confirm variant
      final response = await _aiCommandService.confirmVariantSelection(
        productName: productName,
        variantId: variantId,
        quantity: quantity,
        sessionId: _currentSessionId.value,
      );

      _isLoading.value = false;

      if (kDebugMode) {
        print('========== CONFIRMATION RESPONSE ==========');
        print('ChatController: Response success: ${response.success}');
        print('ChatController: Response message: ${response.message}');
        print('ChatController: Has more items: ${response.hasMore}');
        print('ChatController: Has next action: ${response.hasNextAction}');
        if (response.error != null) {
          print('ChatController: Error: ${response.error}');
        }
        print('===========================================');
      }

      if (response.success) {
        if (response.hasNextAction) {
          // There's another product in the queue
          if (kDebugMode) {
            print('ChatController: More items in queue');
            final nextData = response.nextVariantData;
            if (nextData != null && nextData.queueInfo != null) {
              print(
                  'ChatController: Next position: ${nextData.queueInfo!.position}/${nextData.queueInfo!.total}');
              print('ChatController: Next product: ${nextData.productName}');
              print(
                  'ChatController: Remaining: ${nextData.queueInfo!.remaining.join(", ")}');
            }
          }

          // Add message for current item confirmation
          addAssistantMessage(
            response.message,
            actionsExecuted: ['sequential_variant_selection'],
            variantSelectionData: response.nextVariantData,
          );
        } else {
          // All items processed, queue complete
          if (kDebugMode) {
            print('ChatController: Queue complete - all items added');
          }

          addAssistantMessage(
            response.message,
            actionsExecuted: ['add_to_cart'],
          );
        }
      } else {
        // Error confirming variant
        if (kDebugMode) {
          print('ChatController: Confirmation failed');
          print('ChatController: Error message: ${response.message}');
          print('ChatController: Error detail: ${response.error}');
        }

        // Check if it's a "no active queue found" error
        final errorMsg = response.message.toLowerCase();
        if (errorMsg.contains('no active queue') ||
            errorMsg.contains('queue not found')) {
          _addErrorMessage(
            'Session expired or queue not found. This usually happens when:\n'
            '• The backend restarted\n'
            '• Too much time passed between selections\n'
            '• The session was cleared\n\n'
            'Please try your command again from the start.',
          );
        } else {
          _addErrorMessage(
            'Failed to confirm variant: ${response.message}\n\n'
            'Please try again or restart your command.',
          );
        }
      }
    } catch (e, stackTrace) {
      _isLoading.value = false;
      if (kDebugMode) {
        print('========== CONFIRMATION EXCEPTION ==========');
        print('ChatController: Exception confirming variant: $e');
        print('ChatController: Stack trace: $stackTrace');
        print('===========================================');
      }
      _addErrorMessage(
          'Failed to confirm variant selection. Please try again.');
    }
  }

  /// Cancel sequential variant selection
  /// Called when user cancels the sequential variant dialog
  Future<void> cancelSequentialVariant({required String productName}) async {
    try {
      if (kDebugMode) {
        print('ChatController: Cancelling sequential variant selection');
      }

      _isLoading.value = true;

      final response = await _aiCommandService.confirmVariantSelection(
        productName: productName,
        sessionId: _currentSessionId.value,
        cancel: true,
      );

      _isLoading.value = false;

      addAssistantMessage(
        response.message.isNotEmpty ? response.message : 'Action cancelled',
        actionsExecuted: ['cancel'],
      );
    } catch (e) {
      _isLoading.value = false;
      if (kDebugMode) {
        print('ChatController: Error cancelling variant: $e');
      }
      _addErrorMessage('Failed to cancel. Please try again.');
    }
  }

  /// Clear chat history
  void clearChat() {
    _messages.clear();
    _initializeChat();

    if (kDebugMode) {
      print('ChatController: Chat cleared');
    }
  }

  /// Generate new session ID (useful for new kiosk sessions)
  void generateNewSession() {
    _currentSessionId.value = 'kiosk-${DateTime.now().millisecondsSinceEpoch}';

    if (kDebugMode) {
      print('ChatController: New session ID: ${_currentSessionId.value}');
    }
  }

  /// Get last message (useful for UI updates)
  ChatMessage? get lastMessage {
    return _messages.isNotEmpty ? _messages.last : null;
  }

  /// Get message count
  int get messageCount => _messages.length;

  /// Check if chat is empty (only system message)
  bool get isChatEmpty {
    return _messages.length <= 1; // Only system message
  }

  /// Get typing indicator message
  ChatMessage get typingMessage {
    return ChatMessage.loading();
  }

  /// Send quick command (for predefined actions)
  Future<void> sendQuickCommand(String command) async {
    await sendMessage(command);
  }

  /// Get suggested commands based on context
  List<String> getSuggestedCommands() {
    return [
      'Show menu',
      'Show cart',
      'Add 2 burger to cart',
      'Generate bill',
      'Clear cart',
    ];
  }

  /// Add to cart from variant selection (used in sequential flow)
  /// This method adds the item to cart locally, just like single variant does
  Future<void> addToCartFromVariantSelection({
    required String productName,
    required String variantName,
    required int variantId,
    required int quantity,
    required double sellPrice,
    required int stock,
  }) async {
    try {
      if (kDebugMode) {
        print('========== ADD TO CART (SEQUENTIAL) ==========');
        print('ChatController: Adding to cart from variant selection');
        print('ChatController: Product: $productName');
        print('ChatController: Variant: $variantName');
        print('ChatController: Variant ID: $variantId');
        print('ChatController: Quantity: $quantity');
        print('ChatController: Price: $sellPrice');
        print('ChatController: Stock: $stock');
        print('==============================================');
      }

      // Get CartController
      final cartController = Get.find<CartController>();

      // Add to cart using the AI-validated data (skip validation)
      final success = await cartController.addToCartFromAI(
        variantId: variantId,
        quantity: quantity,
        sellPrice: sellPrice,
        availableStock: stock,
        productName: productName,
        variantName: variantName,
      );

      if (kDebugMode) {
        if (success) {
          print('ChatController: Successfully added $productName to cart');
        } else {
          print('ChatController: Failed to add $productName to cart');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('========== ADD TO CART ERROR ==========');
        print('ChatController: Exception adding to cart: $e');
        print('========================================');
      }
    }
  }

  @override
  void onClose() {
    _messages.clear();
    super.onClose();
  }
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../data/backend/services/ai_command_service.dart';
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
      // Send message to AI backend and execute actions automatically
      final result = await _aiCommandService.processCommandAndExecute(
        prompt: message.trim(),
        sessionId: _currentSessionId.value,
      );

      // Remove typing indicator
      _isTyping.value = false;

      if (result.success) {
        // Add AI message (works for both action-based and message-based responses)
        _addAssistantMessage(
          result.message,
          actionsExecuted: ['executed'],
        );
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
  void _addAssistantMessage(String content, {List<String>? actionsExecuted}) {
    final message = ChatMessage.assistant(
      content: content,
      actionsExecuted: actionsExecuted,
    );
    _messages.add(message);

    if (kDebugMode) {
      print('ChatController: Added assistant message: $content');
      if (actionsExecuted != null && actionsExecuted.isNotEmpty) {
        print('ChatController: Actions executed: $actionsExecuted');
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

  @override
  void onClose() {
    _messages.clear();
    super.onClose();
  }
}

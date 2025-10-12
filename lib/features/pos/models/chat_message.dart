import 'package:flutter/material.dart';

/// Chat Message Model
///
/// Represents a message in the AI assistant chat
class ChatMessage {
  final String id;
  final String content;
  final ChatMessageType type;
  final DateTime timestamp;
  final bool isLoading;
  final List<String>? actionsExecuted;

  ChatMessage({
    required this.id,
    required this.content,
    required this.type,
    required this.timestamp,
    this.isLoading = false,
    this.actionsExecuted,
  });

  /// Create a user message
  factory ChatMessage.user({
    required String content,
    String? id,
  }) {
    return ChatMessage(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: ChatMessageType.user,
      timestamp: DateTime.now(),
    );
  }

  /// Create an AI assistant message
  factory ChatMessage.assistant({
    required String content,
    String? id,
    List<String>? actionsExecuted,
  }) {
    return ChatMessage(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: ChatMessageType.assistant,
      timestamp: DateTime.now(),
      actionsExecuted: actionsExecuted,
    );
  }

  /// Create a loading message (for AI responses)
  factory ChatMessage.loading({
    String? id,
  }) {
    return ChatMessage(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      content: 'AI is thinking...',
      type: ChatMessageType.assistant,
      timestamp: DateTime.now(),
      isLoading: true,
    );
  }

  /// Create an error message
  factory ChatMessage.error({
    required String content,
    String? id,
  }) {
    return ChatMessage(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: ChatMessageType.error,
      timestamp: DateTime.now(),
    );
  }

  /// Create a system message (for instructions, etc.)
  factory ChatMessage.system({
    required String content,
    String? id,
  }) {
    return ChatMessage(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: ChatMessageType.system,
      timestamp: DateTime.now(),
    );
  }

  /// Copy with new values
  ChatMessage copyWith({
    String? id,
    String? content,
    ChatMessageType? type,
    DateTime? timestamp,
    bool? isLoading,
    List<String>? actionsExecuted,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isLoading: isLoading ?? this.isLoading,
      actionsExecuted: actionsExecuted ?? this.actionsExecuted,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage &&
        other.id == id &&
        other.content == content &&
        other.type == type &&
        other.timestamp == timestamp &&
        other.isLoading == isLoading &&
        other.actionsExecuted == actionsExecuted;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      content,
      type,
      timestamp,
      isLoading,
      actionsExecuted,
    );
  }

  @override
  String toString() {
    return 'ChatMessage(id: $id, content: $content, type: $type, timestamp: $timestamp, isLoading: $isLoading, actionsExecuted: $actionsExecuted)';
  }
}

/// Chat Message Types
enum ChatMessageType {
  user, // User's input message
  assistant, // AI assistant's response
  system, // System messages (instructions, etc.)
  error, // Error messages
}

/// Chat Message Type Extensions
extension ChatMessageTypeExtension on ChatMessageType {
  /// Get the display name for the message type
  String get displayName {
    switch (this) {
      case ChatMessageType.user:
        return 'You';
      case ChatMessageType.assistant:
        return 'AI Assistant';
      case ChatMessageType.system:
        return 'System';
      case ChatMessageType.error:
        return 'Error';
    }
  }

  /// Get the color for the message type
  Color getColor() {
    switch (this) {
      case ChatMessageType.user:
        return const Color(0xFF283618); // TColors.primary
      case ChatMessageType.assistant:
        return const Color(0xFF606C38); // TColors.secondary
      case ChatMessageType.system:
        return const Color(0xFFBC6C25); // TColors.accent
      case ChatMessageType.error:
        return const Color(0xFFD32F2F); // TColors.error
    }
  }
}

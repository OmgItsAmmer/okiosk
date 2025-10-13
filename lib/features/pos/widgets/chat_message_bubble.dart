import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../models/chat_message.dart';
import 'variant_selection_bubble.dart';

/// Chat Message Bubble Widget
///
/// Displays individual chat messages with appropriate styling
/// based on message type (user, assistant, system, error)
class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool showTimestamp;

  const ChatMessageBubble({
    super.key,
    required this.message,
    this.showTimestamp = false,
  });

  @override
  Widget build(BuildContext context) {
    // Handle variant selection messages specially
    if (message.variantSelectionData != null) {
      return VariantSelectionBubble(
        variantData: message.variantSelectionData!,
        message: message.content,
      );
    }

    return Container(
      margin: const EdgeInsets.only(
        bottom: TSizes.spaceBtwItems,
        left: TSizes.defaultSpace,
        right: TSizes.defaultSpace,
      ),
      child: Column(
        crossAxisAlignment: _getCrossAxisAlignment(),
        children: [
          // Message bubble
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: TSizes.defaultSpace,
              vertical: TSizes.spaceBtwItems,
            ),
            decoration: BoxDecoration(
              color: _getBubbleColor(),
              borderRadius: _getBorderRadius(),
              border: _getBorder(),
              boxShadow: _getBoxShadow(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Message content
                _buildMessageContent(context),

                // Actions executed (for assistant messages)
                if (message.actionsExecuted != null &&
                    message.actionsExecuted!.isNotEmpty)
                  _buildActionsExecuted(context),
              ],
            ),
          ),

          // Timestamp
          if (showTimestamp) _buildTimestamp(context),
        ],
      ),
    );
  }

  /// Build message content
  Widget _buildMessageContent(BuildContext context) {
    if (message.isLoading) {
      return _buildLoadingIndicator();
    }

    return Text(
      message.content,
      style: _getTextStyle(context),
      textAlign: _getTextAlign(),
    );
  }

  /// Build loading indicator for loading messages
  Widget _buildLoadingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(_getLoadingColor()),
          ),
        ),
        const SizedBox(width: TSizes.sm),
        Text(
          'AI is thinking...',
          style: TextStyle(
            color: _getLoadingColor(),
            fontSize: TSizes.fontSizeSm,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  /// Build actions executed section
  Widget _buildActionsExecuted(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: TSizes.sm),
      padding: const EdgeInsets.all(TSizes.sm),
      decoration: BoxDecoration(
        color: TColors.lightContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.tick_circle,
                size: 14,
                color: TColors.success,
              ),
              const SizedBox(width: TSizes.xs),
              Text(
                'Actions completed:',
                style: TextStyle(
                  fontSize: TSizes.fontSizeSm - 2,
                  fontWeight: FontWeight.w600,
                  color: TColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: TSizes.xs / 2),
          ...message.actionsExecuted!.map((action) => Padding(
                padding: const EdgeInsets.only(left: 18, bottom: 2),
                child: Text(
                  '• $action',
                  style: TextStyle(
                    fontSize: TSizes.fontSizeSm - 2,
                    color: TColors.lightModeSecondaryText,
                  ),
                ),
              )),
        ],
      ),
    );
  }

  /// Build timestamp
  Widget _buildTimestamp(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: TSizes.xs),
      child: Text(
        _formatTimestamp(),
        style: TextStyle(
          fontSize: TSizes.fontSizeSm - 2,
          color: TColors.lightModeSecondaryText.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  /// Get cross axis alignment based on message type
  CrossAxisAlignment _getCrossAxisAlignment() {
    switch (message.type) {
      case ChatMessageType.user:
        return CrossAxisAlignment.end;
      case ChatMessageType.assistant:
      case ChatMessageType.system:
      case ChatMessageType.error:
        return CrossAxisAlignment.start;
    }
  }

  /// Get bubble color based on message type
  Color _getBubbleColor() {
    switch (message.type) {
      case ChatMessageType.user:
        return TColors.primary;
      case ChatMessageType.assistant:
        return TColors.lightContainer;
      case ChatMessageType.system:
        return TColors.accent.withValues(alpha: 0.1);
      case ChatMessageType.error:
        return TColors.error.withValues(alpha: 0.1);
    }
  }

  /// Get border radius based on message type
  BorderRadius _getBorderRadius() {
    switch (message.type) {
      case ChatMessageType.user:
        return const BorderRadius.only(
          topLeft: Radius.circular(TSizes.borderRadiusLg),
          topRight: Radius.circular(TSizes.borderRadiusSm),
          bottomLeft: Radius.circular(TSizes.borderRadiusLg),
          bottomRight: Radius.circular(TSizes.borderRadiusSm),
        );
      case ChatMessageType.assistant:
      case ChatMessageType.system:
      case ChatMessageType.error:
        return const BorderRadius.only(
          topLeft: Radius.circular(TSizes.borderRadiusSm),
          topRight: Radius.circular(TSizes.borderRadiusLg),
          bottomLeft: Radius.circular(TSizes.borderRadiusSm),
          bottomRight: Radius.circular(TSizes.borderRadiusLg),
        );
    }
  }

  /// Get border based on message type
  Border? _getBorder() {
    switch (message.type) {
      case ChatMessageType.user:
        return null;
      case ChatMessageType.assistant:
        return Border.all(
          color: TColors.borderPrimary.withValues(alpha: 0.3),
          width: 1,
        );
      case ChatMessageType.system:
        return Border.all(
          color: TColors.accent.withValues(alpha: 0.3),
          width: 1,
        );
      case ChatMessageType.error:
        return Border.all(
          color: TColors.error.withValues(alpha: 0.3),
          width: 1,
        );
    }
  }

  /// Get box shadow based on message type
  List<BoxShadow>? _getBoxShadow() {
    switch (message.type) {
      case ChatMessageType.user:
        return [
          BoxShadow(
            color: TColors.primary.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ];
      case ChatMessageType.assistant:
      case ChatMessageType.system:
      case ChatMessageType.error:
        return [
          BoxShadow(
            color: TColors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ];
    }
  }

  /// Get text style based on message type
  TextStyle _getTextStyle(BuildContext context) {
    switch (message.type) {
      case ChatMessageType.user:
        return const TextStyle(
          color: TColors.white,
          fontSize: TSizes.fontSizeMd,
        );
      case ChatMessageType.assistant:
        return const TextStyle(
          color: TColors.lightModePrimaryText,
          fontSize: TSizes.fontSizeMd,
        );
      case ChatMessageType.system:
        return TextStyle(
          color: TColors.accent,
          fontSize: TSizes.fontSizeMd,
          fontWeight: FontWeight.w500,
        );
      case ChatMessageType.error:
        return TextStyle(
          color: TColors.error,
          fontSize: TSizes.fontSizeMd,
          fontWeight: FontWeight.w500,
        );
    }
  }

  /// Get text alignment based on message type
  TextAlign _getTextAlign() {
    switch (message.type) {
      case ChatMessageType.user:
        return TextAlign.end;
      case ChatMessageType.assistant:
      case ChatMessageType.system:
      case ChatMessageType.error:
        return TextAlign.start;
    }
  }

  /// Get loading color based on message type
  Color _getLoadingColor() {
    switch (message.type) {
      case ChatMessageType.user:
        return TColors.white;
      case ChatMessageType.assistant:
      case ChatMessageType.system:
      case ChatMessageType.error:
        return TColors.lightModeSecondaryText;
    }
  }

  /// Format timestamp for display
  String _formatTimestamp() {
    final now = DateTime.now();
    final messageTime = message.timestamp;

    if (now.difference(messageTime).inMinutes < 1) {
      return 'Just now';
    } else if (now.difference(messageTime).inHours < 1) {
      return '${now.difference(messageTime).inMinutes}m ago';
    } else if (now.difference(messageTime).inDays < 1) {
      return '${now.difference(messageTime).inHours}h ago';
    } else {
      return '${messageTime.day}/${messageTime.month}/${messageTime.year}';
    }
  }
}

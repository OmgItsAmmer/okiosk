import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get/get.dart';

import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../controller/chat_controller.dart';

/// Chat Input Field Widget
///
/// Provides a text input field with send button for chat messages
class ChatInputField extends StatefulWidget {
  final VoidCallback? onSendMessage;

  const ChatInputField({
    super.key,
    this.onSendMessage,
  });

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  final TextEditingController _textController = TextEditingController();
  final ChatController _chatController = Get.find<ChatController>();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      decoration: BoxDecoration(
        color: TColors.primaryBackground,
        border: Border(
          top: BorderSide(
            color: TColors.borderPrimary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: TColors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Text input field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: TColors.white,
                  borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
                  border: Border.all(
                    color: TColors.borderPrimary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Type your message... (English or Urdu)',
                    hintStyle: TextStyle(
                      color:
                          TColors.lightModeSecondaryText.withValues(alpha: 0.6),
                      fontSize: TSizes.fontSizeMd,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: TSizes.defaultSpace,
                      vertical: TSizes.spaceBtwItems,
                    ),
                    prefixIcon: Icon(
                      Iconsax.message_text,
                      color:
                          TColors.lightModeSecondaryText.withValues(alpha: 0.6),
                      size: 20,
                    ),
                  ),
                  style: const TextStyle(
                    color: TColors.lightModePrimaryText,
                    fontSize: TSizes.fontSizeMd,
                  ),
                  onSubmitted: _sendMessage,
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),
            ),

            const SizedBox(width: TSizes.sm),

            // Send button
            Obx(() => _buildSendButton()),
          ],
        ),
      ),
    );
  }

  /// Build send button with loading state
  Widget _buildSendButton() {
    final bool hasText = _textController.text.trim().isNotEmpty;
    final bool isLoading = _chatController.isLoading;

    return Container(
      decoration: BoxDecoration(
        color: hasText && !isLoading ? TColors.primary : TColors.buttonDisabled,
        borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
        boxShadow: hasText && !isLoading
            ? [
                BoxShadow(
                  color: TColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
          onTap: hasText && !isLoading ? _sendMessage : null,
          child: Container(
            padding: const EdgeInsets.all(TSizes.spaceBtwItems),
            child: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        TColors.white,
                      ),
                    ),
                  )
                : Icon(
                    Iconsax.send_1,
                    color: hasText
                        ? TColors.white
                        : TColors.lightModeSecondaryText.withValues(alpha: 0.5),
                    size: 20,
                  ),
          ),
        ),
      ),
    );
  }

  /// Send message to chat controller
  void _sendMessage([String? text]) {
    final message = text ?? _textController.text.trim();

    if (message.isEmpty || _chatController.isLoading) return;

    // Clear text field
    _textController.clear();

    // Remove focus
    _focusNode.unfocus();

    // Send message
    _chatController.sendMessage(message);

    // Call callback if provided
    widget.onSendMessage?.call();

    setState(() {});
  }

  /// Clear input field
  void clearInput() {
    _textController.clear();
    setState(() {});
  }

  /// Focus input field
  void focusInput() {
    _focusNode.requestFocus();
  }
}

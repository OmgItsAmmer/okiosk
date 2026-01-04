import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:okiosk/features/pos/controller/animation_controller.dart';
import 'package:okiosk/features/pos/controller/chat_controller.dart';
import 'package:okiosk/features/pos/widgets/chat_message_bubble.dart';
import 'package:okiosk/features/pos/widgets/chat_input_field.dart';
import 'package:okiosk/features/pos/widgets/quick_actions_bar.dart';
import 'package:okiosk/features/voice_assistant/voice_assistant.dart';
import 'package:okiosk/features/webview/webview_temp.dart';
import 'package:okiosk/utils/constants/colors.dart';
import 'package:okiosk/utils/constants/sizes.dart';
import 'package:okiosk/utils/constants/image_strings.dart';
import 'package:okiosk/common/widgets/images/t_rounded_image.dart';
import 'package:iconsax/iconsax.dart';

/// AI Assistant Screen Widget
///
/// This widget appears in the left half when AI agent is clicked
/// Contains the complete AI chatbot interface with chat history,
/// input field, and quick actions
class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  late final ChatController _chatController;
  late final PosAnimationController _animationController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animationController = Get.find<PosAnimationController>();

    // Initialize chat controller
    Get.put(ChatController());
    _chatController = Get.find<ChatController>();

    // Initialize voice controller
    if (!Get.isRegistered<VoiceController>()) {
      Get.put(VoiceController());
    }

    // Auto-scroll to bottom when new messages are added
    ever(_chatController.messagesObservable, (_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print(
          'AI Assistant Screen building with opacity: ${_animationController.aiScreenOpacity.value}');
    }

    return AnimatedBuilder(
      animation: _animationController.animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _animationController.aiScreenOpacity,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  TColors.primary.withValues(alpha: 0.1),
                  TColors.primaryBackground,
                ],
              ),
              border: Border.all(
                color: TColors.primary,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                // Header with AI agent image and cancel button
                _buildHeader(context),

                // Quick actions bar
                const QuickActionsBar(),

                // Voice assistant section
                _buildVoiceSection(),

                // Chat messages area
                Expanded(
                  child: _buildChatMessagesArea(),
                ),

                // Chat input field
                const ChatInputField(),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build header with AI agent image and cancel button
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      decoration: BoxDecoration(
        color: TColors.primaryBackground,
        border: Border(
          bottom: BorderSide(
            color: TColors.borderPrimary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // AI Agent Image with pulsing animation
          _buildAiAgentImage(),

          const SizedBox(width: TSizes.md),

          // Title and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Assistant',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: TColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: TSizes.xs),
                Text(
                  'How can I help you today?',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: TColors.lightModeSecondaryText,
                      ),
                ),
              ],
            ),
          ),

          // Cancel button
          _buildCancelButton(context),
        ],
      ),
    );
  }

  /// Build AI agent image with pulsing animation
  Widget _buildAiAgentImage() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1500),
      tween: Tween(begin: 0.8, end: 1.0),
      curve: Curves.easeInOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  TColors.primary.withValues(alpha: 0.1),
                  TColors.primary.withValues(alpha: 0.05),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: TColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: TRoundedImage(
              imageurl: TImages.aiAgentHovered,
              isNetworkImage: false,
              width: 40,
              height: 40,
            ),
          ),
        );
      },
    );
  }

  /// Build cancel button
  Widget _buildCancelButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TColors.error,
        borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
        boxShadow: [
          BoxShadow(
            color: TColors.error.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
          onTap: () => _animationController.hideAiScreen(),
          child: Container(
            padding: const EdgeInsets.all(TSizes.sm),
            child: const Icon(
              Iconsax.close_circle,
              color: TColors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  /// Build chat messages area
  Widget _buildChatMessagesArea() {
    return Obx(() {
      final messages = _chatController.messages;
      final isTyping = _chatController.isTyping;

      return Container(
        decoration: BoxDecoration(
          color: TColors.primaryBackground,
        ),
        child: Column(
          children: [
            // Messages list
            Expanded(
              child: messages.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        vertical: TSizes.defaultSpace,
                      ),
                      itemCount: messages.length + (isTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index < messages.length) {
                          return ChatMessageBubble(
                            message: messages[index],
                          );
                        } else {
                          // Show typing indicator
                          return ChatMessageBubble(
                            message: _chatController.typingMessage,
                          );
                        }
                      },
                    ),
            ),
          ],
        ),
      );
    });
  }

  /// Build empty state when no messages
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // AI Agent Image
          Container(
            padding: const EdgeInsets.all(TSizes.defaultSpace),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  TColors.primary.withValues(alpha: 0.1),
                  TColors.primary.withValues(alpha: 0.05),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: TColors.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: TRoundedImage(
              imageurl: TImages.aiAgentHovered,
              isNetworkImage: false,
              width: 80,
              height: 80,
            ),
          ),

          const SizedBox(height: TSizes.spaceBtwSections),

          // Welcome text
          Text(
            'Welcome to AI Assistant!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: TColors.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: TSizes.spaceBtwItems),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
            padding: const EdgeInsets.all(TSizes.defaultSpace),
            decoration: BoxDecoration(
              color: TColors.lightContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
              border: Border.all(
                color: TColors.borderPrimary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              'I can help you with:\n\n'
              '• Adding items to cart\n'
              '• Removing items from cart\n'
              '• Generating bills\n'
              '• Showing menu and cart\n'
              '• Product searches\n\n'
              'You can speak in English, Urdu, or mix both languages!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: TColors.lightModePrimaryText,
                    height: 1.5,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// Build voice assistant section
  Widget _buildVoiceSection() {
    return Container(
      margin: const EdgeInsets.all(TSizes.defaultSpace),
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      decoration: BoxDecoration(
        color: TColors.lightContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
        border: Border.all(
          color: TColors.borderPrimary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.mic,
                color: TColors.primary,
                size: 20,
              ),
              const SizedBox(width: TSizes.sm),
              Text(
                'Voice Assistant',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: TColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: TSizes.sm),
          // VoiceAssistantWidget(
          //   showTranscription: true,
          //   compactMode: true,
          //   onTranscriptionComplete: () {
          //     // Send transcription to chat
          //     final voiceController = Get.find<VoiceController>();
          //     final transcription = voiceController.getTranscriptionForAI();

          //     if (transcription.isNotEmpty) {
          //       _chatController.sendMessage(transcription);
          //     }
          //   },
          // ),
          WebViewExample()
        ],
      ),
    );
  }

  /// Scroll to bottom of chat
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
}

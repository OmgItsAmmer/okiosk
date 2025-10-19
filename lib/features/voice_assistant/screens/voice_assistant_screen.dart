import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../voice_assistant.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';

/// Voice Assistant Screen
///
/// A full-screen dedicated voice assistant interface
class VoiceAssistantScreen extends StatelessWidget {
  const VoiceAssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize voice controller
    if (!Get.isRegistered<VoiceController>()) {
      Get.put(VoiceController());
    }

    return Scaffold(
      backgroundColor: TColors.primaryBackground,
      appBar: AppBar(
        title: const Text('Voice Assistant'),
        backgroundColor: TColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            children: [
              // Header
              _buildHeader(context),

              const SizedBox(height: TSizes.spaceBtwSections),

              // Voice Assistant Widget
              Expanded(
                child: VoiceAssistantWidget(
                  showTranscription: true,
                  compactMode: false,
                  onTranscriptionComplete: () {
                    // Show transcription result
                    final voiceController = Get.find<VoiceController>();
                    final transcription =
                        voiceController.getTranscriptionForAI();

                    if (transcription.isNotEmpty) {
                      Get.snackbar(
                        'Transcription Complete',
                        transcription,
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: TColors.primary,
                        colorText: Colors.white,
                        duration: const Duration(seconds: 5),
                      );
                    }
                  },
                ),
              ),

              const SizedBox(height: TSizes.spaceBtwSections),

              // Instructions
              _buildInstructions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      decoration: BoxDecoration(
        color: TColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
        border: Border.all(
          color: TColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.mic,
            color: TColors.primary,
            size: 32,
          ),
          const SizedBox(width: TSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Voice Assistant',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: TColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: TSizes.xs),
                Text(
                  'Speak naturally and I\'ll transcribe your words',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: TColors.lightModeSecondaryText,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions(BuildContext context) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: TColors.primary,
                size: 20,
              ),
              const SizedBox(width: TSizes.sm),
              Text(
                'How to use:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: TColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: TSizes.sm),
          const Text(
            '1. Tap the microphone button to start recording\n'
            '2. Speak clearly into your device microphone\n'
            '3. Tap the stop button when you\'re done\n'
            '4. Your transcription will appear below\n'
            '5. Use the transcription for AI commands or chat',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

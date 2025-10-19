import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'voice_assistant.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';

/// Example Integration of Voice Assistant
///
/// This file shows different ways to integrate the voice assistant
/// into your Flutter app

class VoiceAssistantIntegrationExamples {
  /// Example 1: Simple Voice Button in AppBar
  static PreferredSizeWidget buildAppBarWithVoiceButton() {
    return AppBar(
      title: const Text('My App'),
      actions: [
        // Voice button in app bar
        IconButton(
          onPressed: () => _showVoiceDialog(),
          icon: const Icon(Icons.mic),
          tooltip: 'Voice Assistant',
        ),
      ],
    );
  }

  /// Example 2: Voice Button in FloatingActionButton
  static Widget buildFloatingVoiceButton() {
    return FloatingActionButton(
      onPressed: () => _showVoiceDialog(),
      backgroundColor: TColors.primary,
      child: const Icon(Icons.mic, color: Colors.white),
    );
  }

  /// Example 3: Voice Button in Bottom Navigation
  static Widget buildBottomNavWithVoice() {
    return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.mic),
          label: 'Voice',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
      onTap: (index) {
        if (index == 1) {
          _showVoiceDialog();
        }
      },
    );
  }

  /// Example 4: Full Screen Voice Assistant
  static void navigateToVoiceScreen() {
    Get.to(() => const VoiceAssistantScreen());
  }

  /// Example 5: Voice Widget in Custom Layout
  static Widget buildCustomVoiceSection() {
    return Container(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      decoration: BoxDecoration(
        color: TColors.lightContainer,
        borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
      ),
      child: Column(
        children: [
          const Text(
            'Voice Commands',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: TSizes.sm),
          const VoiceAssistantWidget(
            showTranscription: true,
            compactMode: true,
          ),
        ],
      ),
    );
  }

  /// Example 6: Voice Integration with Chat
  static Widget buildChatWithVoice() {
    return Column(
      children: [
        // Chat messages area
        Expanded(
          child: ListView(
            children: [
              // Your chat messages here
            ],
          ),
        ),

        // Voice assistant for input
        Container(
          padding: const EdgeInsets.all(TSizes.sm),
          child: const VoiceAssistantWidget(
            showTranscription: true,
            compactMode: true,
          ),
        ),
      ],
    );
  }

  /// Example 7: Voice Button with Custom Styling
  static Widget buildCustomVoiceButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [TColors.primary, TColors.primary.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: TColors.primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(50),
          onTap: () => _showVoiceDialog(),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Icon(
              Icons.mic,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }

  /// Show voice assistant dialog
  static void _showVoiceDialog() {
    // Initialize voice controller
    if (!Get.isRegistered<VoiceController>()) {
      Get.put(VoiceController());
    }

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 400,
          height: 500,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: VoiceAssistantWidget(
            showTranscription: true,
            compactMode: false,
            onTranscriptionComplete: () {
              // Handle transcription completion
              Get.back();
              final voiceController = Get.find<VoiceController>();
              final transcription = voiceController.getTranscriptionForAI();

              if (transcription.isNotEmpty) {
                Get.snackbar(
                  'Voice Transcription',
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
      ),
      barrierDismissible: true,
    );
  }
}

/// Example Usage in Your App
class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: VoiceAssistantIntegrationExamples.buildAppBarWithVoiceButton(),
      body: const Center(
        child: Text('Your app content here'),
      ),
      floatingActionButton:
          VoiceAssistantIntegrationExamples.buildFloatingVoiceButton(),
      bottomNavigationBar:
          VoiceAssistantIntegrationExamples.buildBottomNavWithVoice(),
    );
  }
}

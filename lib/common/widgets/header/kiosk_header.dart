import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:okiosk/common/widgets/images/t_rounded_image.dart';
import 'package:okiosk/utils/constants/sizes.dart';
import 'package:okiosk/features/pos/controller/animation_controller.dart';
import 'package:okiosk/features/voice_assistant/voice_assistant.dart';

import '../../../utils/constants/colors.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/helpers/helper_functions.dart';
import '../search/animated_search_bar.dart';

class KioskHeader extends StatefulWidget {
  const KioskHeader({super.key});

  @override
  State<KioskHeader> createState() => _KioskHeaderState();
}

class _KioskHeaderState extends State<KioskHeader> {
  Timer? _timer;
  bool _showHoveredImage = false;

  @override
  void initState() {
    super.initState();
    // Start the timer to alternate images every 3 seconds
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      setState(() {
        _showHoveredImage = !_showHoveredImage;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Handle AI agent tap to trigger screen transition
  void _onAiAgentTapped() {
    try {
      // Initialize animation controller if not already initialized
      if (!Get.isRegistered<PosAnimationController>()) {
        Get.put(PosAnimationController());
        print('Animation controller initialized');
      }

      final animationController = Get.find<PosAnimationController>();
      print('Animation controller found, triggering showAiScreen');
      print(
          'Current AI screen visible: ${animationController.isAiScreenVisible}');
      print('Current animation status: ${animationController.isAnimating}');

      animationController.showAiScreen();
      print('showAiScreen called');
    } catch (e) {
      // Handle error gracefully
      print('Error triggering AI screen animation: $e');
    }
  }

  /// Handle voice button tap to show voice assistant
  void _onVoiceButtonTapped() {
    try {
      // Initialize voice controller if not already initialized
      if (!Get.isRegistered<VoiceController>()) {
        Get.put(VoiceController());
        print('Voice controller initialized');
      }

      // Show voice assistant dialog
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
                // Close dialog and show transcription result
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
    } catch (e) {
      // Handle error gracefully
      print('Error showing voice assistant: $e');
      Get.snackbar(
        'Error',
        'Failed to open voice assistant: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: TColors.error,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return Container(
      width: double.infinity,
      //  height: 60,
      padding: const EdgeInsets.all(TSizes.defaultSpace / 2),
      color: dark ? TColors.primaryBackground : TColors.primaryBackground,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // const TSectionHeading(
          //   title: 'Kiosk Header',
          //   showActionButton: false,
          //   textColor: TColors.primary,
          // ),
          TRoundedImage(
            imageurl: TImages.appIcon,
            isNetworkImage: false,
            width: 80,
            height: 80,
          ),
          const SizedBox(width: TSizes.spaceBtwItems),
          Expanded(
            child: const AnimatedSearchBar(),
          ),
          const SizedBox(width: TSizes.spaceBtwItems),
          // Voice Button
          GestureDetector(
            onTap: _onVoiceButtonTapped,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TColors.primary,
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: TColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.mic,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: TSizes.spaceBtwItems),
          // AI Agent with Chat Bubble
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Chat bubble - moved up slightly
              Transform.translate(
                offset: const Offset(0, -8),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: TColors.primary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'Need some help? Ask me!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    // Triangle pointer positioned at the right edge
                    Positioned(
                      right: -6,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: CustomPaint(
                          size: const Size(8, 12),
                          painter: _TrianglePainter(color: TColors.primary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Animated AI Agent Image (Clickable)
              GestureDetector(
                onTap: () => _onAiAgentTapped(),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  child: TRoundedImage(
                    key: ValueKey<bool>(_showHoveredImage),
                    imageurl: _showHoveredImage
                        ? TImages.aiAgentHovered
                        : TImages.aiAgentDoodle,
                    isNetworkImage: false,
                    width: 80,
                    height: 80,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Custom painter for the chat bubble triangle pointing right
class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0) // Top left
      ..lineTo(size.width, size.height / 2) // Right point (middle)
      ..lineTo(0, size.height) // Bottom left
      ..lineTo(0, 0) // Back to top left
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

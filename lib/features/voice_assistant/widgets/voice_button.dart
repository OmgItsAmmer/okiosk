import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/constants/enums.dart';
import '../controller/voice_controller.dart';

/// Voice Button Widget
/// A simple, reusable button for starting/stopping voice recording
class VoiceButton extends StatelessWidget {
  final VoiceController? controller;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final VoidCallback? onTranscriptionComplete;

  const VoiceButton({
    super.key,
    this.controller,
    this.size = 64.0,
    this.activeColor,
    this.inactiveColor,
    this.onTranscriptionComplete,
  });

  @override
  Widget build(BuildContext context) {
    final voiceController = controller ?? Get.find<VoiceController>();

    return Obx(() {
      final state = voiceController.voiceStateObs.value;
      final isActive = state.isRecording;
      final isProcessing = state.isProcessing;

      return GestureDetector(
        onTap: isProcessing ? null : () => _handleTap(voiceController, state),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getButtonColor(state, context),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: (activeColor ?? Colors.red).withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: _buildIcon(state),
          ),
        ),
      );
    });
  }

  void _handleTap(VoiceController controller, VoiceState state) {
    if (state.isRecording) {
      controller.stopRecording().then((_) {
        if (onTranscriptionComplete != null) {
          onTranscriptionComplete!();
        }
      });
    } else if (state.canStartRecording) {
      controller.startRecording();
    }
  }

  Color _getButtonColor(VoiceState state, BuildContext context) {
    if (state.isRecording) {
      return activeColor ?? Colors.red;
    } else if (state.isProcessing) {
      return Colors.orange;
    } else if (state.isError) {
      return Colors.red.shade900;
    }
    return inactiveColor ?? Theme.of(context).primaryColor;
  }

  Widget _buildIcon(VoiceState state) {
    if (state.isProcessing) {
      return SizedBox(
        width: size * 0.5,
        height: size * 0.5,
        child: const CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 3,
        ),
      );
    } else if (state.isRecording) {
      return Icon(
        Icons.stop,
        color: Colors.white,
        size: size * 0.5,
      );
    } else if (state.isError) {
      return Icon(
        Icons.error_outline,
        color: Colors.white,
        size: size * 0.5,
      );
    }

    return Icon(
      Icons.mic,
      color: Colors.white,
      size: size * 0.5,
    );
  }
}

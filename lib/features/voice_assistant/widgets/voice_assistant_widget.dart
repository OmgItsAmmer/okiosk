import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/voice_controller.dart';
import '../models/voice_state.dart';
import '../screens/voice_debug_screen.dart';
import 'voice_button.dart';

/// Voice Assistant Widget
/// A comprehensive UI for voice recording with transcription display
class VoiceAssistantWidget extends StatelessWidget {
  final VoiceController? controller;
  final VoidCallback? onTranscriptionComplete;
  final bool showTranscription;
  final bool compactMode;

  const VoiceAssistantWidget({
    super.key,
    this.controller,
    this.onTranscriptionComplete,
    this.showTranscription = true,
    this.compactMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final voiceController = controller ?? Get.find<VoiceController>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!compactMode) _buildHeader(context),
          const SizedBox(height: 16),
          _buildVoiceButton(voiceController),
          const SizedBox(height: 16),
          _buildStatusIndicator(voiceController),
          if (showTranscription) ...[
            const SizedBox(height: 16),
            _buildTranscriptionDisplay(voiceController, context),
          ],
          if (!compactMode) ...[
            const SizedBox(height: 16),
            _buildControlButtons(voiceController),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.mic_none_rounded,
          color: Theme.of(context).primaryColor,
          size: 28,
        ),
        const SizedBox(width: 8),
        Text(
          'Voice Assistant',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildVoiceButton(VoiceController controller) {
    return VoiceButton(
      controller: controller,
      size: 80,
      onTranscriptionComplete: onTranscriptionComplete,
    );
  }

  Widget _buildStatusIndicator(VoiceController controller) {
    return Obx(() {
      final state = controller.voiceStateObs.value;
      final duration = controller.recordingDuration;

      return Column(
        children: [
          Text(
            _getStatusText(state),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _getStatusColor(state),
            ),
          ),
          if (state.isRecording && duration > 0) ...[
            const SizedBox(height: 8),
            Text(
              _formatDuration(duration),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            _buildRecordingIndicator(),
          ],
        ],
      );
    });
  }

  Widget _buildRecordingIndicator() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8 + (value * 16 * (index + 1) / 3),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.8),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        );
      },
      onEnd: () {
        // Loop animation
      },
    );
  }

  Widget _buildTranscriptionDisplay(
      VoiceController controller, BuildContext context) {
    return Obx(() {
      final current = controller.currentTranscriptionObs.value;
      final final_ = controller.finalTranscriptionObs.value;
      final error = controller.errorMessage;

      if (error.isNotEmpty) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Voice Assistant Error',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
              if (error.contains('microphone') ||
                  error.contains('permission')) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: const Text(
                    '💡 Try: Check system microphone permissions and ensure a microphone is connected',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }

      if (final_.isEmpty && current.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Transcription will appear here...',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      }

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (final_.isNotEmpty) ...[
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).primaryColor,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Final:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                final_,
                style: const TextStyle(fontSize: 14),
              ),
            ],
            if (current.isNotEmpty && current != final_) ...[
              if (final_.isNotEmpty) const Divider(height: 16),
              Row(
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Live:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                current,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildControlButtons(VoiceController controller) {
    return Obx(() {
      final state = controller.voiceStateObs.value;
      final hasTranscription =
          controller.finalTranscriptionObs.value.isNotEmpty ||
              controller.currentTranscriptionObs.value.isNotEmpty;

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (state.isRecording)
            ElevatedButton.icon(
              onPressed: controller.toggleMute,
              icon: Icon(
                controller.isMicrophoneMuted ? Icons.mic_off : Icons.mic,
                size: 18,
              ),
              label: Text(controller.isMicrophoneMuted ? 'Unmute' : 'Mute'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          if (hasTranscription && !state.isRecording) ...[
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: controller.clearTranscription,
              icon: const Icon(Icons.clear, size: 18),
              label: const Text('Clear'),
            ),
          ],
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              //   Get.to(() => const VoiceDebugScreen());
            },
            icon: const Icon(Icons.bug_report, size: 18),
            tooltip: 'Debug Voice Assistant',
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey.shade200,
            ),
          ),
        ],
      );
    });
  }

  String _getStatusText(VoiceState state) {
    switch (state) {
      case VoiceState.idle:
        return 'Tap to start speaking';
      case VoiceState.initializing:
        return 'Initializing...';
      case VoiceState.connecting:
        return 'Connecting...';
      case VoiceState.recording:
        return '🎤 Recording...';
      case VoiceState.streaming:
        return 'Streaming audio...';
      case VoiceState.processing:
        return 'Processing...';
      case VoiceState.completed:
        return '✅ Completed';
      case VoiceState.error:
        return '❌ Error';
      case VoiceState.disconnected:
        return 'Disconnected';
    }
  }

  Color _getStatusColor(VoiceState state) {
    switch (state) {
      case VoiceState.recording:
        return Colors.red;
      case VoiceState.processing:
      case VoiceState.streaming:
        return Colors.orange;
      case VoiceState.completed:
        return Colors.green;
      case VoiceState.error:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDuration(double seconds) {
    final duration = Duration(seconds: seconds.toInt());
    final minutes = duration.inMinutes;
    final secs = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

/// Voice Assistant Module
///
/// A comprehensive voice-to-text integration for AI kiosk system
///
/// Features:
/// - Real-time audio recording at 16kHz PCM mono
/// - WebSocket streaming to backend
/// - Live transcription display
/// - State management with GetX
/// - Error handling and reconnection logic
///
/// Usage:
/// ```dart
/// // Initialize controller
/// final voiceController = Get.put(VoiceController());
///
/// // Use in UI
/// VoiceAssistantWidget(
///   onTranscriptionComplete: () {
///     final text = voiceController.getTranscriptionForAI();
///     // Send to AI for processing
///   },
/// )
/// ```

library voice_assistant;

// Models
export 'models/audio_config.dart';
export 'models/transcription_response.dart';
export 'models/voice_state.dart';

// Services
export 'services/voice_recording_service.dart';
export 'services/voice_websocket_service.dart';

// Controller
export 'controller/voice_controller.dart';

// Widgets
export 'widgets/voice_assistant_widget.dart';
export 'widgets/voice_button.dart';

// Screens
export 'screens/voice_assistant_screen.dart';
export 'screens/voice_debug_screen.dart';

// Utils
export 'utils/desktop_permission_helper.dart';

// Examples
export 'example_integration.dart';

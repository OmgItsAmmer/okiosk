import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../utils/constants/enums.dart';
import '../../../data/backend/services/ai_action_executor.dart';
import '../../../data/backend/models/ai_action_model.dart';
import '../models/audio_config.dart';
import '../models/transcription_response.dart';
import '../services/voice_recording_service.dart';
import '../services/voice_websocket_service.dart';
import '../../pos/controller/chat_controller.dart';

/// Voice Controller
/// Manages voice recording, WebSocket connection, and transcription state
class VoiceController extends GetxController {
  // Services
  final VoiceRecordingService _recordingService = VoiceRecordingService();
  final VoiceWebSocketService _websocketService = VoiceWebSocketService();
  final AiActionExecutor _actionExecutor = Get.find<AiActionExecutor>();

  // Observable state
  final Rx<VoiceState> _voiceState = VoiceState.idle.obs;
  final RxString _currentTranscription = ''.obs;
  final RxString _finalTranscription = ''.obs;
  final RxString _errorMessage = ''.obs;
  final RxBool _isMicrophoneMuted = false.obs;
  final RxDouble _recordingDuration = 0.0.obs;
  final RxDouble _audioLevel = 0.0.obs;

  // Stream subscriptions
  StreamSubscription<Uint8List>? _audioStreamSubscription;
  StreamSubscription<TranscriptionResponse>? _transcriptionSubscription;
  StreamSubscription<VoiceState>? _connectionStateSubscription;
  StreamSubscription<dynamic>? _recordingProgressSubscription;
  StreamSubscription<Map<String, dynamic>>? _aiResponseSubscription;

  // WebSocket configuration - Connect to Rust server
  String _wsUrl = 'ws://localhost:3000/ws/voice';

  // Demo mode for testing without backend
  bool _demoMode = false;

  // Completer to wait for transcription completion
  Completer<void>? _transcriptionCompleter;

  // Getters
  VoiceState get voiceState => _voiceState.value;
  String get currentTranscription => _currentTranscription.value;
  String get finalTranscription => _finalTranscription.value;
  String get errorMessage => _errorMessage.value;
  bool get isMicrophoneMuted => _isMicrophoneMuted.value;
  double get recordingDuration => _recordingDuration.value;
  double get audioLevel => _audioLevel.value;
  bool get isRecording => _voiceState.value.isRecording;
  bool get canStartRecording => _voiceState.value.canStartRecording;
  bool get isDemoMode => _demoMode;

  // Observable getters for reactive UI
  Rx<VoiceState> get voiceStateObs => _voiceState;
  RxString get currentTranscriptionObs => _currentTranscription;
  RxString get finalTranscriptionObs => _finalTranscription;

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  /// Initialize the voice assistant
  Future<void> _initialize() async {
    try {
      debugPrint('🎯 Voice Controller: Starting initialization...');
      _voiceState.value = VoiceState.initializing;

      // Initialize recording service with detailed debugging
      debugPrint('🎤 Voice Controller: Initializing recording service...');
      final recordingInitialized = await _recordingService.initialize();
      if (!recordingInitialized) {
        debugPrint(
            '❌ Voice Controller: Recording service initialization failed');
        _setError(
            'Failed to initialize microphone - check system permissions and audio devices');
        return;
      }
      debugPrint(
          '✅ Voice Controller: Recording service initialized successfully');

      // Setup transcription listener
      debugPrint('🔗 Voice Controller: Setting up transcription listener...');
      _transcriptionSubscription = _websocketService.transcriptionStream.listen(
        _onTranscriptionReceived,
        onError: (error) {
          debugPrint('❌ Voice Controller: Transcription stream error: $error');
          _setError('Transcription error: $error');
        },
      );

      // Setup connection state listener
      debugPrint(
          '🔗 Voice Controller: Setting up connection state listener...');
      _connectionStateSubscription =
          _websocketService.connectionStateStream.listen(
        _onConnectionStateChanged,
        onError: (error) {
          debugPrint(
              '❌ Voice Controller: Connection state stream error: $error');
        },
      );

      // Setup AI response listener
      debugPrint('🔗 Voice Controller: Setting up AI response listener...');
      _aiResponseSubscription = _websocketService.aiResponseStream.listen(
        _onAiResponseReceived,
        onError: (error) {
          debugPrint('❌ Voice Controller: AI response stream error: $error');
        },
      );

      _voiceState.value = VoiceState.idle;
      debugPrint('🎉 Voice Controller: Initialization completed successfully');
      debugPrint('📊 Voice Controller: State = ${_voiceState.value}');
      debugPrint(
          '📊 Voice Controller: Recording service ready = ${_recordingService.isInitialized}');
    } catch (e, stackTrace) {
      debugPrint('❌ Voice Controller: Failed to initialize: $e');
      debugPrint('📋 Voice Controller: Stack trace: $stackTrace');
      _setError('Initialization failed: $e');
    }
  }

  /// Set WebSocket URL (optional, for custom backends)
  void setWebSocketUrl(String url) {
    _wsUrl = url;
    debugPrint('🔧 WebSocket URL set to: $_wsUrl');
  }

  /// Enable demo mode for testing microphone without backend
  void enableDemoMode() {
    _demoMode = true;
    debugPrint('🎤 Demo mode enabled - microphone testing without backend');
  }

  /// Disable demo mode
  void disableDemoMode() {
    _demoMode = false;
    debugPrint('🎤 Demo mode disabled - will try to connect to backend');
  }

  /// Start voice recording and streaming
  Future<void> startRecording() async {
    if (!canStartRecording) {
      debugPrint('⚠️ Cannot start recording in current state: $voiceState');
      return;
    }

    try {
      // Try to connect to WebSocket first
      _voiceState.value = VoiceState.connecting;
      final connected = await _websocketService.connect(_wsUrl);

      if (!connected) {
        debugPrint('⚠️ WebSocket connection failed, entering demo mode');
        _demoMode = true;
        _currentTranscription.value = 'Demo Mode: Microphone is working!';
        _finalTranscription.value = 'Demo Mode: Microphone is working!';
      } else {
        _demoMode = false;
        // Send start message
        _websocketService.sendControlMessage('start', data: {
          'sample_rate': kDefaultAudioConfig.sampleRate,
          'encoding': kDefaultAudioConfig.codec,
        });
      }

      // Start recording (this should work regardless of WebSocket)
      final recordingStarted = await _recordingService.startRecording();

      if (!recordingStarted) {
        _setError('Failed to start recording - check microphone permissions');
        if (!_demoMode) {
          await _websocketService.disconnect();
        }
        return;
      }

      // Note: No longer streaming audio chunks during recording
      // The complete audio file will be sent when recording stops
      debugPrint('🎤 Recording in progress - will send complete file on stop');

      // Listen to recording progress
      _recordingProgressSubscription = _recordingService.onProgress?.listen(
        (progress) {
          // Handle RecordingDisposition from the record package
          if (progress != null) {
            _recordingDuration.value = progress.duration.inSeconds.toDouble();
          }
        },
      );

      _voiceState.value = VoiceState.recording;
      _currentTranscription.value =
          _demoMode ? 'Demo Mode: Microphone is working!' : '';
      _finalTranscription.value = '';
      _errorMessage.value = '';

      debugPrint(
          '🎤 Started voice recording ${_demoMode ? '(Demo Mode)' : 'and streaming'}');
    } catch (e) {
      debugPrint('❌ Failed to start recording: $e');
      _setError('Failed to start: $e');
    }
  }

  /// Stop voice recording and send complete audio file
  Future<void> stopRecording() async {
    if (!isRecording) return;

    try {
      _voiceState.value = VoiceState.processing;

      // Stop recording and get the complete audio file
      final audioBytes = await _recordingService.stopRecording();

      // Cancel audio stream subscription
      await _audioStreamSubscription?.cancel();
      _audioStreamSubscription = null;

      // Cancel recording progress subscription
      await _recordingProgressSubscription?.cancel();
      _recordingProgressSubscription = null;

      if (!_demoMode) {
        if (audioBytes != null && audioBytes.isNotEmpty) {
          debugPrint(
              '📤 Sending complete audio file (${audioBytes.length} bytes) to backend');

          // Create completer to wait for transcription
          _transcriptionCompleter = Completer<void>();

          // Send the complete audio file to backend
          _websocketService.sendAudioChunk(audioBytes);

          // Wait for transcription response with timeout
          debugPrint('⏳ Waiting for transcription from backend...');
          try {
            await _transcriptionCompleter!.future.timeout(
              const Duration(seconds: 120), // 2 minutes timeout for AssemblyAI
              onTimeout: () {
                debugPrint('⏰ Transcription timeout - proceeding anyway');
              },
            );
          } catch (e) {
            debugPrint('❌ Error waiting for transcription: $e');
          }
        } else {
          debugPrint('⚠️ No audio data to send');
          _setError('No audio recorded');
        }

        // Disconnect WebSocket after transcription is received
        await _websocketService.disconnect();
      } else {
        // Demo mode: Show final message
        _finalTranscription.value =
            'Demo Mode: Microphone test completed successfully!';
        debugPrint('🎤 Demo Mode: Microphone test completed');
      }

      _voiceState.value = VoiceState.completed;
      _recordingDuration.value = 0.0;

      debugPrint(
          '⏹️ Stopped voice recording ${_demoMode ? '(Demo Mode)' : ''}');
      debugPrint('📝 Final transcription: $_finalTranscription');
    } catch (e) {
      debugPrint('❌ Failed to stop recording: $e');
      _setError('Failed to stop: $e');
    }
  }

  /// Toggle microphone mute (pause/resume recording)
  Future<void> toggleMute() async {
    if (!isRecording) return;

    try {
      if (_isMicrophoneMuted.value) {
        await _recordingService.resumeRecording();
        _websocketService.sendControlMessage('resume');
      } else {
        await _recordingService.pauseRecording();
        _websocketService.sendControlMessage('pause');
      }

      _isMicrophoneMuted.value = !_isMicrophoneMuted.value;
      debugPrint(
          '🔇 Microphone ${_isMicrophoneMuted.value ? "muted" : "unmuted"}');
    } catch (e) {
      debugPrint('❌ Failed to toggle mute: $e');
    }
  }

  /// Clear transcription and reset state
  void clearTranscription() {
    _currentTranscription.value = '';
    _finalTranscription.value = '';
    _errorMessage.value = '';
    _recordingDuration.value = 0.0;

    if (_voiceState.value == VoiceState.completed ||
        _voiceState.value == VoiceState.error) {
      _voiceState.value = VoiceState.idle;
    }
  }

  /// Handle incoming transcription
  void _onTranscriptionReceived(TranscriptionResponse transcription) {
    if (transcription.isFinal) {
      _finalTranscription.value = transcription.text;
      debugPrint('✅ Final transcription: ${transcription.text}');

      // Complete the transcription completer if it exists
      if (_transcriptionCompleter != null &&
          !_transcriptionCompleter!.isCompleted) {
        _transcriptionCompleter!.complete();
        debugPrint('✅ Transcription completer completed');
      }
    } else {
      _currentTranscription.value = transcription.text;
    }
  }

  /// Handle connection state changes
  void _onConnectionStateChanged(VoiceState state) {
    if (state == VoiceState.error || state == VoiceState.disconnected) {
      if (isRecording) {
        stopRecording();
      }
    }
  }

  /// Handle AI response from voice WebSocket
  Future<void> _onAiResponseReceived(Map<String, dynamic> aiResponse) async {
    debugPrint('🤖 Voice Controller: Received AI response: $aiResponse');

    final success = aiResponse['success'] as bool? ?? false;
    final message = aiResponse['message'] as String? ?? '';
    final actionsRaw = aiResponse['actions_executed'] as List<dynamic>? ?? [];
    final error = aiResponse['error'] as String?;

    debugPrint('🤖 Voice Controller: Success: $success');
    debugPrint('🤖 Voice Controller: Message: $message');
    debugPrint('🤖 Voice Controller: Actions raw: $actionsRaw');
    if (error != null) debugPrint('🤖 Voice Controller: Error: $error');

    // Convert actions to strings for processing
    final actionStrings = actionsRaw.map((e) => e.toString()).toList();

    if (!success) {
      // Handle error case
      try {
        if (Get.isRegistered<ChatController>()) {
          final chatController = Get.find<ChatController>();
          chatController.addAssistantMessage(
            message,
            actionsExecuted: ['error'],
          );
        }
      } catch (e) {
        debugPrint('❌ Voice Controller: Failed to add error message: $e');
      }
      return;
    }

    try {
      // Execute actions using the same logic as text-based AI flow
      debugPrint(
          '🔄 Voice Controller: Executing ${actionStrings.length} actions...');
      final results =
          await _actionExecutor.executeActionsFromStrings(actionStrings);

      final successfulActions = results.where((result) => result).length;

      debugPrint(
          '✅ Voice Controller: Actions executed - Success: $successfulActions/${actionStrings.length}');

      // Parse actions to get structured data for variant selection detection
      final parsedActions = <AiAction>[];
      for (final actionString in actionStrings) {
        try {
          final action = AiAction.fromJsonString(actionString);
          parsedActions.add(action);
        } catch (e) {
          debugPrint('❌ Voice Controller: Failed to parse action: $e');
        }
      }

      // Forward to chat controller with proper action data
      if (Get.isRegistered<ChatController>()) {
        final chatController = Get.find<ChatController>();

        // Check for variant selection actions (same logic as text flow)
        final sequentialVariantAction = parsedActions
            .where((action) => action.requiresSequentialVariantSelection)
            .firstOrNull;

        final multiVariantAction = parsedActions
            .where((action) => action.requiresMultiVariantSelection)
            .firstOrNull;

        final singleVariantAction = parsedActions
            .where((action) => action.requiresVariantSelection)
            .firstOrNull;

        if (sequentialVariantAction != null) {
          // Sequential variant selection
          debugPrint(
              '🔄 Voice Controller: Sequential variant selection detected');
          chatController.addAssistantMessage(
            message,
            actionsExecuted: ['sequential_variant_selection'],
            variantSelectionData: sequentialVariantAction.variantSelectionData,
          );
        } else if (multiVariantAction != null) {
          // Multi-variant selection (deprecated but still supported)
          debugPrint('🔄 Voice Controller: Multi-variant selection detected');
          chatController.addAssistantMessage(
            message,
            actionsExecuted: ['multi_variant_selection'],
            multiVariantSelectionData:
                multiVariantAction.multiVariantSelectionData,
          );
        } else if (singleVariantAction != null) {
          // Single variant selection
          debugPrint('🔄 Voice Controller: Single variant selection detected');
          chatController.addAssistantMessage(
            message,
            actionsExecuted: ['variant_selection'],
            variantSelectionData: singleVariantAction.variantSelectionData,
          );
        } else {
          // Normal actions executed
          final actionTypes =
              parsedActions.map((action) => action.actionType).toList();
          debugPrint(
              '✅ Voice Controller: Normal actions executed: $actionTypes');
          chatController.addAssistantMessage(
            message,
            actionsExecuted:
                actionTypes.isNotEmpty ? actionTypes : ['message_only'],
          );
        }

        debugPrint(
            '✅ Voice Controller: AI response processed and forwarded to chat');
      } else {
        debugPrint('⚠️ Voice Controller: ChatController not found');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Voice Controller: Failed to process AI response: $e');
      debugPrint('📋 Voice Controller: Stack trace: $stackTrace');

      // Show error in chat
      try {
        if (Get.isRegistered<ChatController>()) {
          final chatController = Get.find<ChatController>();
          chatController.addAssistantMessage(
            'Failed to execute action: ${e.toString()}',
            actionsExecuted: ['error'],
          );
        }
      } catch (e2) {
        debugPrint('❌ Voice Controller: Failed to add error message: $e2');
      }
    }
  }

  /// Set error state
  void _setError(String message) {
    _errorMessage.value = message;
    _voiceState.value = VoiceState.error;
    debugPrint('❌ Error: $message');
  }

  /// Get transcription text for AI processing
  String getTranscriptionForAI() {
    // Return final transcription if available, otherwise current
    return _finalTranscription.value.isNotEmpty
        ? _finalTranscription.value
        : _currentTranscription.value;
  }

  @override
  void onClose() {
    // Cancel all subscriptions
    _audioStreamSubscription?.cancel();
    _transcriptionSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    _recordingProgressSubscription?.cancel();
    _aiResponseSubscription?.cancel();

    // Complete any pending transcription completer
    if (_transcriptionCompleter != null &&
        !_transcriptionCompleter!.isCompleted) {
      _transcriptionCompleter!.complete();
    }

    // Dispose services
    _recordingService.dispose();
    _websocketService.dispose();

    super.onClose();
  }
}

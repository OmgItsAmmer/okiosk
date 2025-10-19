import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../models/audio_config.dart';
import '../models/transcription_response.dart';
import '../models/voice_state.dart';
import '../services/voice_recording_service.dart';
import '../services/voice_websocket_service.dart';

/// Voice Controller
/// Manages voice recording, WebSocket connection, and transcription state
class VoiceController extends GetxController {
  // Services
  final VoiceRecordingService _recordingService = VoiceRecordingService();
  final VoiceWebSocketService _websocketService = VoiceWebSocketService();

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

  // WebSocket configuration
  String _wsUrl = 'ws://localhost:8081/ws/voice';

  // Demo mode for testing without backend
  bool _demoMode = false;

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

      if (!_demoMode) {
        // Listen to audio stream and send to WebSocket
        _audioStreamSubscription = _recordingService.audioStream?.listen(
          (audioChunk) {
            _websocketService.sendAudioChunk(audioChunk);
          },
          onError: (error) {
            debugPrint('❌ Audio stream error: $error');
            _setError('Audio stream error: $error');
            stopRecording();
          },
        );
      } else {
        // Demo mode: Just listen to audio stream for testing
        _audioStreamSubscription = _recordingService.audioStream?.listen(
          (audioChunk) {
            debugPrint(
                '🎤 Demo Mode: Audio chunk received (${audioChunk.length} bytes)');
            // Simulate transcription updates
            _currentTranscription.value =
                'Demo Mode: Recording... (${audioChunk.length} bytes)';
          },
          onError: (error) {
            debugPrint('❌ Demo Mode Audio stream error: $error');
            _setError('Demo Mode Audio stream error: $error');
            stopRecording();
          },
        );
      }

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

  /// Stop voice recording and streaming
  Future<void> stopRecording() async {
    if (!isRecording) return;

    try {
      _voiceState.value = VoiceState.processing;

      // Stop recording
      await _recordingService.stopRecording();

      // Cancel audio stream subscription
      await _audioStreamSubscription?.cancel();
      _audioStreamSubscription = null;

      // Cancel recording progress subscription
      await _recordingProgressSubscription?.cancel();
      _recordingProgressSubscription = null;

      if (!_demoMode) {
        // Send stop message to backend
        _websocketService.sendControlMessage('stop');

        // Wait a bit for final transcription
        await Future.delayed(const Duration(milliseconds: 500));

        // Disconnect WebSocket
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

    // Dispose services
    _recordingService.dispose();
    _websocketService.dispose();

    super.onClose();
  }
}

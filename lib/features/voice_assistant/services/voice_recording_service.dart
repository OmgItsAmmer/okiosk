import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/audio_config.dart';

/// Voice Recording Service
/// Handles microphone access, audio recording, and PCM audio streaming using record package
class VoiceRecordingService {
  static final VoiceRecordingService _instance =
      VoiceRecordingService._internal();
  factory VoiceRecordingService() => _instance;
  VoiceRecordingService._internal();

  final AudioRecorder _recorder = AudioRecorder();
  StreamController<Uint8List>? _audioStreamController;
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  Timer? _audioChunkTimer;
  final AudioConfig _audioConfig = kDefaultAudioConfig;
  String? _recordingPath;

  bool _isInitialized = false;
  bool _isRecording = false;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Check if currently recording
  bool get isRecording => _isRecording;

  /// Get audio configuration
  AudioConfig get audioConfig => _audioConfig;

  /// Audio stream for real-time audio chunks
  Stream<Uint8List>? get audioStream => _audioStreamController?.stream;

  /// Initialize the recording service
  Future<bool> initialize() async {
    if (_isInitialized) {
      debugPrint('✅ Voice Recording Service already initialized');
      return true;
    }

    try {
      debugPrint(
          '🔧 Initializing Voice Recording Service with record package...');
      debugPrint('📊 Audio Config: $_audioConfig');

      // Check if we have recording permission
      debugPrint('🔐 Checking microphone permission...');
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        debugPrint('❌ Microphone permission not granted');
        final permission = await _requestMicrophonePermission();
        if (!permission) {
          debugPrint('❌ Microphone permission denied');
          return false;
        }
      }
      debugPrint('✅ Microphone permission granted');

      // Test if recording is available on this device
      debugPrint('🔍 Checking if recording is available...');
      final isAvailable = await _recorder.hasPermission();
      if (!isAvailable) {
        debugPrint('❌ Recording not available on this device');
        return false;
      }
      debugPrint('✅ Recording is available');

      // Initialize stream controller
      _audioStreamController = StreamController<Uint8List>.broadcast();
      debugPrint('✅ Audio stream controller initialized');

      _isInitialized = true;
      debugPrint('🎉 Voice Recording Service initialized successfully');
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to initialize Voice Recording Service: $e');
      debugPrint('📋 Stack trace: $stackTrace');
      debugPrint('🔍 Error type: ${e.runtimeType}');

      // Additional debugging for common issues
      if (e.toString().contains('permission')) {
        debugPrint(
            '💡 Permission issue detected - check system microphone permissions');
      } else if (e.toString().contains('audio')) {
        debugPrint(
            '💡 Audio system issue detected - check audio drivers and devices');
      }

      return false;
    }
  }

  /// Request microphone permission
  Future<bool> _requestMicrophonePermission() async {
    try {
      debugPrint(
          '🔐 Voice Recording Service: Requesting microphone permission...');

      // Request microphone permission using permission_handler
      final status = await Permission.microphone.request();
      debugPrint('📊 Voice Recording Service: Permission status: $status');

      if (status.isGranted) {
        debugPrint('✅ Voice Recording Service: Microphone permission granted');
        return true;
      } else if (status.isPermanentlyDenied) {
        debugPrint(
            '❌ Voice Recording Service: Microphone permission permanently denied');
        debugPrint(
            '💡 Voice Recording Service: Please enable microphone permission in system settings');
        return false;
      } else if (status.isDenied) {
        debugPrint('❌ Voice Recording Service: Microphone permission denied');
        return false;
      }

      return false;
    } catch (e, stackTrace) {
      debugPrint(
          '❌ Voice Recording Service: Error requesting microphone permission: $e');
      debugPrint('📋 Voice Recording Service: Stack trace: $stackTrace');
      return false;
    }
  }

  /// Start recording audio
  Future<bool> startRecording() async {
    if (!_isInitialized) {
      debugPrint('❌ Service not initialized');
      return false;
    }

    if (_isRecording) {
      debugPrint('⚠️ Already recording');
      return false;
    }

    try {
      debugPrint('🎤 Starting audio recording...');

      // Start recording with record package
      final isRecording = await _recorder.isRecording();
      if (isRecording) {
        debugPrint('⚠️ Recorder is already recording');
        return false;
      }

      // Create temporary file path for recording
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _recordingPath =
          path.join(tempDir.path, 'voice_recording_$timestamp.wav');
      debugPrint('📁 Recording to: $_recordingPath');

      // Start recording
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: _recordingPath!,
      );

      _isRecording = true;
      debugPrint('🎤 Started audio recording');

      // Start streaming audio chunks
      _startAudioStreaming();

      return true;
    } catch (e) {
      debugPrint('❌ Failed to start recording: $e');
      return false;
    }
  }

  /// Start streaming audio chunks to the stream controller
  void _startAudioStreaming() {
    // Start amplitude monitoring for audio level
    _amplitudeSubscription =
        _recorder.onAmplitudeChanged(const Duration(milliseconds: 100)).listen(
      (amplitude) {
        // You can use this for audio level visualization
        debugPrint('🔊 Audio level: ${amplitude.current}');
      },
    );

    // Note: The record package saves audio to a file.
    // We'll send the complete file when recording stops rather than streaming chunks.
    debugPrint(
        '📝 Recording in progress - will send complete file when stopped');
  }

  /// Stop recording audio and return the recorded file bytes
  Future<Uint8List?> stopRecording() async {
    if (!_isRecording) return null;

    try {
      debugPrint('⏹️ Stopping audio recording...');

      // Stop the recorder
      final path = await _recorder.stop();
      debugPrint('📁 Recording stopped, saved to: $path');

      // Cancel subscriptions and timers
      await _amplitudeSubscription?.cancel();
      _amplitudeSubscription = null;

      _audioChunkTimer?.cancel();
      _audioChunkTimer = null;

      _isRecording = false;

      // Read the recorded audio file
      Uint8List? audioBytes;
      if (_recordingPath != null) {
        try {
          final file = File(_recordingPath!);
          if (await file.exists()) {
            audioBytes = await file.readAsBytes();
            debugPrint('📖 Read audio file: ${audioBytes.length} bytes');

            // Send the complete audio file through stream
            if (_audioStreamController != null &&
                !_audioStreamController!.isClosed) {
              _audioStreamController!.add(audioBytes);
              debugPrint('📤 Sent complete audio file to stream');
            }

            // Clean up the temporary file
            await file.delete();
            debugPrint('🗑️ Deleted temporary recording file: $_recordingPath');
          } else {
            debugPrint('⚠️ Recording file not found: $_recordingPath');
          }
        } catch (e) {
          debugPrint('❌ Failed to read/delete audio file: $e');
        }
        _recordingPath = null;
      }

      debugPrint('⏹️ Stopped recording audio');
      return audioBytes;
    } catch (e) {
      debugPrint('❌ Failed to stop recording: $e');
      _isRecording = false;
      return null;
    }
  }

  /// Pause recording
  Future<void> pauseRecording() async {
    if (!_isRecording) return;

    try {
      // Cancel amplitude subscription and timer
      await _amplitudeSubscription?.cancel();
      _amplitudeSubscription = null;

      _audioChunkTimer?.cancel();
      _audioChunkTimer = null;

      debugPrint('⏸️ Paused recording');
    } catch (e) {
      debugPrint('❌ Failed to pause recording: $e');
    }
  }

  /// Resume recording
  Future<void> resumeRecording() async {
    if (!_isRecording) return;

    try {
      // Restart audio streaming
      _startAudioStreaming();
      debugPrint('▶️ Resumed recording');
    } catch (e) {
      debugPrint('❌ Failed to resume recording: $e');
    }
  }

  /// Get current recording duration
  Stream<dynamic>? get onProgress {
    // The record package doesn't provide a direct progress stream
    // We can create a simple timer-based progress stream
    if (!_isRecording) return null;

    final controller = StreamController<RecordingDisposition>();
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isRecording) {
        timer.cancel();
        controller.close();
        return;
      }

      controller.add(RecordingDisposition(
        duration: Duration(seconds: timer.tick),
        decibel: 0.0,
      ));
    });

    return controller.stream;
  }

  /// Dispose the service
  Future<void> dispose() async {
    try {
      if (_isRecording) {
        await stopRecording();
      }

      // Cancel all subscriptions
      await _amplitudeSubscription?.cancel();
      _amplitudeSubscription = null;

      _audioChunkTimer?.cancel();
      _audioChunkTimer = null;

      // Clean up any remaining temporary file
      if (_recordingPath != null) {
        try {
          final file = File(_recordingPath!);
          if (await file.exists()) {
            await file.delete();
            debugPrint('🗑️ Deleted remaining temporary file: $_recordingPath');
          }
        } catch (e) {
          debugPrint('⚠️ Failed to delete remaining temporary file: $e');
        }
        _recordingPath = null;
      }

      // Close stream controller
      await _audioStreamController?.close();
      _audioStreamController = null;

      _isInitialized = false;
      _isRecording = false;

      debugPrint('🗑️ Voice Recording Service disposed');
    } catch (e) {
      debugPrint('❌ Failed to dispose Voice Recording Service: $e');
    }
  }
}

/// Simple recording disposition class for compatibility
class RecordingDisposition {
  final Duration duration;
  final double decibel;

  const RecordingDisposition({
    required this.duration,
    required this.decibel,
  });
}

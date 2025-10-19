import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import '../models/transcription_response.dart';
import '../models/voice_state.dart';

/// Voice WebSocket Service
/// Handles WebSocket connection to backend for real-time audio streaming
class VoiceWebSocketService {
  static final VoiceWebSocketService _instance =
      VoiceWebSocketService._internal();
  factory VoiceWebSocketService() => _instance;
  VoiceWebSocketService._internal();

  WebSocketChannel? _channel;
  final StreamController<TranscriptionResponse> _transcriptionController =
      StreamController<TranscriptionResponse>.broadcast();
  final StreamController<VoiceState> _connectionStateController =
      StreamController<VoiceState>.broadcast();

  bool _isConnected = false;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 2);

  /// Check if WebSocket is connected
  bool get isConnected => _isConnected;

  /// Stream of transcription responses
  Stream<TranscriptionResponse> get transcriptionStream =>
      _transcriptionController.stream;

  /// Stream of connection state changes
  Stream<VoiceState> get connectionStateStream =>
      _connectionStateController.stream;

  /// Connect to WebSocket server
  Future<bool> connect(String wsUrl) async {
    if (_isConnected) {
      debugPrint('⚠️ Already connected to WebSocket');
      return true;
    }

    try {
      debugPrint('🔌 Connecting to WebSocket: $wsUrl');
      _connectionStateController.add(VoiceState.connecting);

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Listen to incoming messages
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDisconnect,
        cancelOnError: false,
      );

      _isConnected = true;
      _reconnectAttempts = 0;
      _connectionStateController.add(VoiceState.idle);
      debugPrint('✅ Connected to WebSocket');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to connect to WebSocket: $e');
      _connectionStateController.add(VoiceState.error);
      _attemptReconnect(wsUrl);
      return false;
    }
  }

  /// Send audio chunk to backend
  void sendAudioChunk(Uint8List audioData) {
    if (!_isConnected || _channel == null) {
      debugPrint('⚠️ WebSocket not connected, cannot send audio');
      return;
    }

    try {
      // Convert audio bytes to base64 for JSON transmission
      final audioBase64 = base64Encode(audioData);

      // Debug: Log audio chunk details
      debugPrint(
          '📤 Voice WebSocket: Sending audio chunk of ${audioData.length} bytes');
      debugPrint(
          '📤 Voice WebSocket: Base64 length: ${audioBase64.length} characters');
      debugPrint(
          '📤 Voice WebSocket: Audio sample (first 20 bytes): ${audioData.take(20).join(' ')}');

      final message = jsonEncode({
        'type': 'audio',
        'data': audioBase64,
      });

      _channel!.sink.add(message);
      debugPrint('📤 Voice WebSocket: Audio chunk sent successfully');
    } catch (e) {
      debugPrint('❌ Failed to send audio chunk: $e');
    }
  }

  /// Send control message to backend
  void sendControlMessage(String messageType, {Map<String, dynamic>? data}) {
    if (!_isConnected || _channel == null) {
      debugPrint('⚠️ WebSocket not connected, cannot send control message');
      return;
    }

    try {
      final message = jsonEncode({
        'type': messageType,
        'data': data ?? {},
      });

      _channel!.sink.add(message);
      debugPrint('📤 Sent control message: $messageType');
    } catch (e) {
      debugPrint('❌ Failed to send control message: $e');
    }
  }

  /// Handle incoming WebSocket messages
  void _onMessage(dynamic message) {
    try {
      final Map<String, dynamic> json = jsonDecode(message as String);
      final messageType = json['type'] as String;

      switch (messageType) {
        case 'transcription':
          final transcription = TranscriptionResponse.fromJson(
              json['data'] as Map<String, dynamic>);
          _transcriptionController.add(transcription);
          debugPrint('📝 Received transcription: ${transcription.text}');
          break;

        case 'status':
          final statusMessage = json['data']['message'] as String?;
          debugPrint('ℹ️ Status: $statusMessage');
          break;

        case 'error':
          final errorMessage = json['data']['message'] as String?;
          debugPrint('❌ Error from backend: $errorMessage');
          _connectionStateController.add(VoiceState.error);
          break;

        default:
          debugPrint('⚠️ Unknown message type: $messageType');
      }
    } catch (e) {
      debugPrint('❌ Failed to parse message: $e');
    }
  }

  /// Handle WebSocket error
  void _onError(dynamic error) {
    debugPrint('❌ WebSocket error: $error');
    _connectionStateController.add(VoiceState.error);
    _isConnected = false;
  }

  /// Handle WebSocket disconnection
  void _onDisconnect() {
    debugPrint('🔌 WebSocket disconnected');
    _isConnected = false;
    _connectionStateController.add(VoiceState.disconnected);
  }

  /// Attempt to reconnect to WebSocket
  void _attemptReconnect(String wsUrl) {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('❌ Max reconnect attempts reached');
      return;
    }

    _reconnectAttempts++;
    debugPrint(
        '🔄 Attempting reconnect $_reconnectAttempts/$_maxReconnectAttempts');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () => connect(wsUrl));
  }

  /// Disconnect from WebSocket
  Future<void> disconnect() async {
    if (!_isConnected) return;

    try {
      _reconnectTimer?.cancel();
      await _channel?.sink.close(status.goingAway);
      _isConnected = false;
      _connectionStateController.add(VoiceState.idle);
      debugPrint('🔌 Disconnected from WebSocket');
    } catch (e) {
      debugPrint('❌ Failed to disconnect: $e');
    }
  }

  /// Dispose the service
  Future<void> dispose() async {
    await disconnect();
    await _transcriptionController.close();
    await _connectionStateController.close();
    _channel = null;
    debugPrint('🗑️ Voice WebSocket Service disposed');
  }
}

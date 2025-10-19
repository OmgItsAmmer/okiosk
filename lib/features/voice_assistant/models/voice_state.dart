/// Voice State Enum
enum VoiceState {
  /// Initial state - not recording
  idle,

  /// Initializing audio recorder
  initializing,

  /// Recording audio from microphone
  recording,

  /// Streaming audio to backend
  streaming,

  /// Processing transcription
  processing,

  /// Transcription completed
  completed,

  /// Error occurred
  error,

  /// Connecting to WebSocket
  connecting,

  /// WebSocket disconnected
  disconnected,
}

/// Extension for Voice State
extension VoiceStateExtension on VoiceState {
  bool get isRecording => this == VoiceState.recording;
  bool get isProcessing =>
      this == VoiceState.processing || this == VoiceState.streaming;
  bool get isIdle => this == VoiceState.idle;
  bool get isError => this == VoiceState.error;
  bool get canStartRecording =>
      this == VoiceState.idle ||
      this == VoiceState.completed ||
      this == VoiceState.error;
}

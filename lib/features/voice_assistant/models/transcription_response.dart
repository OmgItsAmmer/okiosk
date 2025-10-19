/// Transcription Response Model
class TranscriptionResponse {
  final String text;
  final bool isFinal;
  final double confidence;
  final DateTime timestamp;

  TranscriptionResponse({
    required this.text,
    required this.isFinal,
    this.confidence = 0.0,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory TranscriptionResponse.fromJson(Map<String, dynamic> json) {
    return TranscriptionResponse(
      text: json['text'] as String? ?? '',
      isFinal: json['is_final'] as bool? ?? false,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'is_final': isFinal,
      'confidence': confidence,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  TranscriptionResponse copyWith({
    String? text,
    bool? isFinal,
    double? confidence,
    DateTime? timestamp,
  }) {
    return TranscriptionResponse(
      text: text ?? this.text,
      isFinal: isFinal ?? this.isFinal,
      confidence: confidence ?? this.confidence,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'TranscriptionResponse(text: $text, isFinal: $isFinal, confidence: $confidence)';
  }
}

/// WebSocket Message Model
class VoiceWebSocketMessage {
  final String type;
  final dynamic data;

  VoiceWebSocketMessage({
    required this.type,
    required this.data,
  });

  factory VoiceWebSocketMessage.fromJson(Map<String, dynamic> json) {
    return VoiceWebSocketMessage(
      type: json['type'] as String,
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'data': data,
    };
  }
}

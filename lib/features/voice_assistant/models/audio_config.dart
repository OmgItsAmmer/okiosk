/// Audio Configuration for Voice Recording
class AudioConfig {
  /// Sample rate: 16kHz as required by AssemblyAI
  final int sampleRate;

  /// Number of channels: Mono (1 channel)
  final int numChannels;

  /// Bit depth: 16-bit PCM
  final int bitDepth;

  /// Codec for audio encoding
  final String codec;

  /// Buffer size for streaming chunks (in bytes)
  final int bufferSize;

  const AudioConfig({
    this.sampleRate = 16000,
    this.numChannels = 1,
    this.bitDepth = 16,
    this.codec = 'pcm16',
    this.bufferSize = 4096,
  });

  /// Calculate bytes per second
  int get bytesPerSecond => sampleRate * numChannels * (bitDepth ~/ 8);

  /// Calculate chunk duration in milliseconds
  int get chunkDurationMs => (bufferSize * 1000) ~/ bytesPerSecond;

  @override
  String toString() {
    return 'AudioConfig(sampleRate: $sampleRate Hz, channels: $numChannels, bitDepth: $bitDepth, codec: $codec)';
  }
}

/// Singleton instance for global audio configuration
const kDefaultAudioConfig = AudioConfig();

# Voice Assistant Module - Quick Start

## Overview

The Voice Assistant module provides real-time voice-to-text transcription for
your Flutter app using AssemblyAI.

## Quick Setup (5 minutes)

### 1. Install Dependencies

```bash
flutter pub get
```

Dependencies are already added to `pubspec.yaml`:

- `flutter_sound: ^9.2.13`
- `permission_handler: ^11.0.0`
- `web_socket_channel: ^2.0.1`

### 2. Add Permissions

**Android** (`android/app/src/main/AndroidManifest.xml`):

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
```

**iOS** (`ios/Runner/Info.plist`):

```xml
<key>NSMicrophoneUsageDescription</key>
<string>We need microphone access for voice commands</string>
```

### 3. Start Backend

Make sure your Rust backend is running:

```bash
cd kks_online_backend
cargo run --release
```

Ensure `.env` contains:

```env
ASSEMBLYAI_API_KEY=your_key_here
```

### 4. Use in Your App

**Simple Usage:**

```dart
import 'package:get/get.dart';
import 'package:okiosk/features/voice_assistant/voice_assistant.dart';

// Initialize controller
final voiceController = Get.put(VoiceController());

// Use the widget
VoiceAssistantWidget(
  onTranscriptionComplete: () {
    final text = voiceController.getTranscriptionForAI();
    print('User said: $text');
  },
)
```

**Just a Button:**

```dart
VoiceButton(
  size: 64,
  onTranscriptionComplete: () {
    // Handle transcription
  },
)
```

## File Structure

```
lib/features/voice_assistant/
├── models/
│   ├── audio_config.dart          # Audio configuration
│   ├── transcription_response.dart # Response models
│   └── voice_state.dart           # State enum
├── services/
│   ├── voice_recording_service.dart # Audio recording
│   └── voice_websocket_service.dart # WebSocket communication
├── controller/
│   └── voice_controller.dart      # State management
├── widgets/
│   ├── voice_assistant_widget.dart # Full UI
│   └── voice_button.dart          # Simple button
├── voice_assistant.dart           # Module exports
└── example_usage.dart             # Examples
```

## Key Features

- ✅ **Real-time transcription** - See text as you speak
- ✅ **16kHz PCM audio** - Optimized for voice
- ✅ **WebSocket streaming** - Low latency
- ✅ **GetX state management** - Reactive UI
- ✅ **Error handling** - Automatic reconnection
- ✅ **Mute/unmute** - Control recording
- ✅ **Permission handling** - Automatic requests

## Common Use Cases

### 1. Add to Chat Interface

```dart
import 'package:okiosk/features/voice_assistant/voice_assistant.dart';

Row(
  children: [
    VoiceButton(onTranscriptionComplete: () {
      final text = Get.find<VoiceController>().getTranscriptionForAI();
      chatController.sendMessage(text);
    }),
    Expanded(child: TextField(...)),
    IconButton(icon: Icon(Icons.send)),
  ],
)
```

### 2. Add to POS System

```dart
Container(
  width: 300,
  child: VoiceAssistantWidget(
    onTranscriptionComplete: () {
      final command = voiceController.getTranscriptionForAI();
      _processVoiceCommand(command);
    },
  ),
)
```

### 3. Standalone Voice Screen

```dart
Scaffold(
  body: Center(
    child: VoiceAssistantWidget(
      showTranscription: true,
      compactMode: false,
    ),
  ),
)
```

## State Management

```dart
final controller = Get.find<VoiceController>();

// Observe state
Obx(() => Text(controller.voiceStateObs.value.toString()));

// Check if recording
if (controller.isRecording) { ... }

// Get transcription
String text = controller.currentTranscription;  // Live
String final = controller.finalTranscription;   // Complete
String forAI = controller.getTranscriptionForAI(); // Best
```

## Configuration

### Custom WebSocket URL

```dart
voiceController.setWebSocketUrl('ws://your-server:8080/ws/voice');
```

### Audio Settings

Edit `lib/features/voice_assistant/models/audio_config.dart`:

```dart
const AudioConfig({
  sampleRate: 16000,    // Hz
  numChannels: 1,       // Mono
  bitDepth: 16,         // 16-bit
  codec: 'pcm16',       // PCM
  bufferSize: 4096,     // Bytes
});
```

## Troubleshooting

### ❌ "Microphone permission denied"

- Check device settings → App permissions → Microphone
- On iOS, verify Info.plist has NSMicrophoneUsageDescription

### ❌ "WebSocket connection failed"

- Ensure backend is running: `cargo run`
- Check WebSocket URL: `ws://localhost:8080/ws/voice`
- Verify firewall allows connections

### ❌ "No audio recorded"

- Check microphone is working (test in other apps)
- Verify flutter_sound initialization
- Check device volume is not muted

### ❌ "Transcription not appearing"

- Check AssemblyAI API key in backend `.env`
- Verify internet connection
- Check backend logs for errors

## Examples

See `example_usage.dart` for complete examples:

- Basic voice assistant
- Simple voice button
- Voice-enabled chat
- POS integration
- Custom configuration

Run examples:

```dart
import 'package:okiosk/features/voice_assistant/example_usage.dart';

void main() {
  runApp(VoiceAssistantExampleApp());
}
```

## API Reference

### VoiceController

**Methods:**

- `startRecording()` - Start audio capture
- `stopRecording()` - Stop and finalize
- `toggleMute()` - Mute/unmute mic
- `clearTranscription()` - Clear text
- `getTranscriptionForAI()` - Get best text

**Properties:**

- `voiceState` - Current state
- `isRecording` - Boolean
- `currentTranscription` - Live text
- `finalTranscription` - Complete text
- `errorMessage` - Error if any
- `recordingDuration` - Seconds

### VoiceAssistantWidget

**Parameters:**

- `controller` - Optional controller
- `onTranscriptionComplete` - Callback
- `showTranscription` - Show text (default: true)
- `compactMode` - Minimal UI (default: false)

### VoiceButton

**Parameters:**

- `controller` - Optional controller
- `size` - Button size (default: 64)
- `activeColor` - Recording color
- `inactiveColor` - Idle color
- `onTranscriptionComplete` - Callback

## Performance Tips

1. **Lower latency**: Reduce `bufferSize` in `AudioConfig`
2. **Save bandwidth**: Only send audio when speaking (VAD)
3. **Cache controller**: Use `Get.find()` instead of creating new instances
4. **Close sessions**: Always stop recording when done

## Cost Optimization

AssemblyAI charges ~$0.01/minute. To reduce costs:

- Implement silence detection
- Set session timeouts
- Add usage limits
- Close inactive sessions

## Security

- ✅ API keys stored in backend only
- ✅ WebSocket over TLS in production
- ✅ Permission checks before recording
- ✅ No audio data logged

## Next Steps

1. ✅ Test basic functionality
2. ✅ Integrate with your AI system
3. ✅ Add voice commands parsing
4. ✅ Implement UI customization
5. ✅ Add error handling
6. ✅ Test on physical devices

## Support

- 📖 See `VOICE_TO_TEXT_INTEGRATION.md` for detailed docs
- 🔧 Check backend logs for debugging
- 🎯 Review `example_usage.dart` for patterns
- 📊 Monitor AssemblyAI usage in dashboard

---

**Quick Links:**

- AssemblyAI Dashboard: https://www.assemblyai.com/app
- Flutter Sound Docs: https://pub.dev/packages/flutter_sound
- GetX Docs: https://pub.dev/packages/get

**Made with ❤️ for AI Kiosk System**

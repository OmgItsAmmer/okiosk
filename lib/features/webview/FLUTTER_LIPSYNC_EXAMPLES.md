# Flutter Integration Examples for Lip-Sync Avatar

Three methods to integrate the lip-sync avatar in your Flutter app.

## Method 1: React Handles Everything (Simplest)

**When to use:** React app has direct network access to Rust backend

```dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AvatarWebView extends StatefulWidget {
  @override
  _AvatarWebViewState createState() => _AvatarWebViewState();
}

class _AvatarWebViewState extends State<AvatarWebView> {
  late WebViewController _controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Avatar Assistant')),
      body: WebView(
        initialUrl: 'http://localhost:3000',  // Your React app
        javascriptMode: JavascriptMode.unrestricted,
        onWebViewCreated: (WebViewController controller) {
          _controller = controller;
        },
      ),
    );
  }
}
```

**That's it!** React handles all lip-sync generation internally.

---

## Method 2: Flutter Sends Text, React Generates Lip-Sync

**When to use:** You want Flutter to control what the avatar says

```dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';

class AvatarController extends StatefulWidget {
  @override
  _AvatarControllerState createState() => _AvatarControllerState();
}

class _AvatarControllerState extends State<AvatarController> {
  late WebViewController _controller;

  // Make avatar speak text
  Future<void> speakText(String text) async {
    final message = jsonEncode({
      'type': 'speak_text',
      'text': text,
    });
    
    await _controller.runJavascript('''
      window.postMessage($message, '*');
    ''');
  }

  // Make avatar respond to AI command
  Future<void> sendAICommand(String command) async {
    final message = jsonEncode({
      'type': 'ai_command',
      'command': command,
    });
    
    await _controller.runJavascript('''
      window.postMessage($message, '*');
    ''');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Avatar Controller')),
      body: Column(
        children: [
          Expanded(
            child: WebView(
              initialUrl: 'http://localhost:3000',
              javascriptMode: JavascriptMode.unrestricted,
              onWebViewCreated: (WebViewController controller) {
                _controller = controller;
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () => speakText('Welcome to our restaurant!'),
                  child: Text('Welcome Message'),
                ),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => sendAICommand('add 2 pizzas to cart'),
                  child: Text('AI Command Example'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

**React side** (add to your React app):

```javascript
// Listen for Flutter messages
window.addEventListener('message', async (event) => {
  try {
    const message = JSON.parse(event.data);
    
    if (message.type === 'speak_text') {
      // Generate lip-sync and play
      const data = await generateLipSync(message.text);
      setAudioSource(getAudioSource(data));
      setVisemes(formatVisemesForThreeJS(data.visemes));
    }
    
    if (message.type === 'ai_command') {
      // Process AI command with lip-sync
      const response = await generateFromAICommand(message.command);
      if (response?.lip_sync) {
        setAudioSource(getAudioSource(response.lip_sync));
        setVisemes(formatVisemesForThreeJS(response.lip_sync.visemes));
      }
    }
  } catch (e) {
    console.error('Failed to parse message:', e);
  }
});
```

---

## Method 3: Flutter Fetches Lip-Sync Data, Sends to React (Advanced)

**When to use:** Flutter needs full control over backend communication

```dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdvancedAvatarController extends StatefulWidget {
  @override
  _AdvancedAvatarControllerState createState() => _AdvancedAvatarControllerState();
}

class _AdvancedAvatarControllerState extends State<AdvancedAvatarController> {
  late WebViewController _controller;
  final String backendUrl = 'http://localhost:8080';

  // Generate lip-sync from text
  Future<void> generateAndSpeakText(String text) async {
    try {
      // 1. Fetch lip-sync data from Rust backend
      final response = await http.post(
        Uri.parse('$backendUrl/api/ai/lip-sync'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to generate lip-sync');
      }

      final lipSyncData = jsonDecode(response.body);

      // 2. Send to React WebView
      await sendLipSyncToAvatar(lipSyncData);
    } catch (e) {
      print('Error generating lip-sync: $e');
    }
  }

  // Send AI command and get response with lip-sync
  Future<void> sendAICommandWithLipSync(String command) async {
    try {
      // 1. Send AI command to backend
      final response = await http.post(
        Uri.parse('$backendUrl/api/ai/command-with-lipsync'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'prompt': command,
          'session_id': 'flutter_session',
          'customer_id': null,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('AI command failed');
      }

      final data = jsonDecode(response.body);

      // 2. Show AI response message
      print('AI Response: ${data['message']}');

      // 3. Send lip-sync to avatar
      if (data['lip_sync'] != null) {
        await sendLipSyncToAvatar(data['lip_sync']);
      }

      // 4. Handle actions (if needed)
      if (data['actions_executed'] != null) {
        print('Actions executed: ${data['actions_executed']}');
        // Update Flutter UI accordingly
      }
    } catch (e) {
      print('Error with AI command: $e');
    }
  }

  // Send lip-sync data to React avatar
  Future<void> sendLipSyncToAvatar(Map<String, dynamic> lipSyncData) async {
    final message = jsonEncode({
      'type': 'lip_sync_data',
      'data': lipSyncData,
    });

    await _controller.runJavascript('''
      window.postMessage($message, '*');
    ''');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Advanced Avatar Control')),
      body: Column(
        children: [
          Expanded(
            child: WebView(
              initialUrl: 'http://localhost:3000',
              javascriptMode: JavascriptMode.unrestricted,
              onWebViewCreated: (WebViewController controller) {
                _controller = controller;
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () => generateAndSpeakText('Hello! Welcome!'),
                  child: Text('Custom Message'),
                ),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => sendAICommandWithLipSync('show menu'),
                  child: Text('AI: Show Menu'),
                ),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => sendAICommandWithLipSync('add 2 burgers to cart'),
                  child: Text('AI: Add Burgers'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## Integration with Existing Voice Assistant

If you already have a voice assistant (like from `README_VOICE_ASSISTANT.md`), integrate lip-sync:

```dart
class VoiceAvatarScreen extends StatefulWidget {
  @override
  _VoiceAvatarScreenState createState() => _VoiceAvatarScreenState();
}

class _VoiceAvatarScreenState extends State<VoiceAvatarScreen> {
  late WebViewController _avatarController;
  final String backendUrl = 'http://localhost:8080';
  
  // Your existing voice recording logic
  Future<void> handleVoiceInput(String audioData) async {
    try {
      // 1. Send audio to backend for transcription
      final transcription = await transcribeAudio(audioData);
      print('User said: $transcription');
      
      // 2. Send to AI for processing (with lip-sync)
      final response = await http.post(
        Uri.parse('$backendUrl/api/ai/command-with-lipsync'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'prompt': transcription,
          'session_id': 'voice_session',
        }),
      );
      
      final data = jsonDecode(response.body);
      
      // 3. Make avatar speak the response
      if (data['lip_sync'] != null) {
        final message = jsonEncode({
          'type': 'lip_sync_data',
          'data': data['lip_sync'],
        });
        
        await _avatarController.runJavascript('''
          window.postMessage($message, '*');
        ''');
      }
      
      // 4. Handle actions (cart updates, etc.)
      handleAIActions(data['actions_executed']);
      
    } catch (e) {
      print('Voice processing error: $e');
    }
  }
  
  Future<String> transcribeAudio(String audioData) async {
    // Your existing transcription logic
    return "show menu"; // Example
  }
  
  void handleAIActions(List actions) {
    // Your existing action handling
    print('Executing actions: $actions');
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Avatar WebView
          WebView(
            initialUrl: 'http://localhost:3000',
            javascriptMode: JavascriptMode.unrestricted,
            onWebViewCreated: (controller) {
              _avatarController = controller;
            },
          ),
          
          // Voice button overlay
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                onPressed: () {
                  // Your voice recording logic
                  startVoiceRecording();
                },
                child: Icon(Icons.mic),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## Complete Example: Kiosk with Avatar

```dart
class KioskAvatarScreen extends StatefulWidget {
  @override
  _KioskAvatarScreenState createState() => _KioskAvatarScreenState();
}

class _KioskAvatarScreenState extends State<KioskAvatarScreen> {
  late WebViewController _controller;
  final String backendUrl = 'http://localhost:8080';
  String sessionId = 'kiosk_${DateTime.now().millisecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    // Welcome message when kiosk starts
    Future.delayed(Duration(seconds: 2), () {
      avatarSpeak('Welcome to our restaurant! How can I help you today?');
    });
  }

  // Make avatar speak
  Future<void> avatarSpeak(String text) async {
    final message = jsonEncode({'type': 'speak_text', 'text': text});
    await _controller.runJavascript('window.postMessage($message, "*");');
  }

  // Process user command
  Future<void> processCommand(String command) async {
    try {
      final response = await http.post(
        Uri.parse('$backendUrl/api/ai/command-with-lipsync'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'prompt': command,
          'session_id': sessionId,
        }),
      );

      final data = jsonDecode(response.body);

      // Make avatar speak the response
      if (data['lip_sync'] != null) {
        final message = jsonEncode({
          'type': 'lip_sync_data',
          'data': data['lip_sync'],
        });
        await _controller.runJavascript('window.postMessage($message, "*");');
      }

      // Update kiosk state
      handleActions(data);
    } catch (e) {
      avatarSpeak('Sorry, I encountered an error. Please try again.');
    }
  }

  void handleActions(Map<String, dynamic> data) {
    // Navigate to appropriate screen based on actions
    final actions = data['actions_executed'] as List?;
    if (actions == null) return;

    if (actions.contains('show_menu')) {
      Navigator.pushNamed(context, '/menu');
    } else if (actions.contains('generate_bill')) {
      Navigator.pushNamed(context, '/checkout');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Avatar at top
          SizedBox(
            height: 300,
            child: WebView(
              initialUrl: 'http://localhost:3000',
              javascriptMode: JavascriptMode.unrestricted,
              onWebViewCreated: (controller) => _controller = controller,
            ),
          ),
          
          // Kiosk interface below
          Positioned(
            top: 300,
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              children: [
                // Quick action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => processCommand('show menu'),
                      child: Text('Show Menu'),
                    ),
                    ElevatedButton(
                      onPressed: () => processCommand('view cart'),
                      child: Text('View Cart'),
                    ),
                    ElevatedButton(
                      onPressed: () => processCommand('checkout'),
                      child: Text('Checkout'),
                    ),
                  ],
                ),
                // Voice button
                SizedBox(height: 20),
                FloatingActionButton.extended(
                  onPressed: () {
                    // Start voice recording
                  },
                  icon: Icon(Icons.mic),
                  label: Text('Speak to order'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## Testing

### 1. Start Services

```bash
# Terminal 1: Rust backend
cd kks_online_backend
cargo run

# Terminal 2: React avatar
cd my-avatar-app
npm run dev
```

### 2. Run Flutter App

```bash
cd okiosk
flutter run
```

### 3. Test Integration

- Tap buttons to trigger avatar speech
- Avatar should speak with lip-sync
- Check console logs for debugging

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| WebView not loading | Check React dev server is running |
| No lip movement | Check avatar model has morph targets |
| JavaScript errors | Enable `debuggingEnabled: true` in WebView |
| Network errors | Check backend URL is correct |

---

## Summary

**Method 1**: Simplest - React handles everything  
**Method 2**: Balanced - Flutter controls text, React generates lip-sync  
**Method 3**: Full control - Flutter fetches and sends lip-sync data  

Choose based on your needs! All methods work with the same Rust backend and React avatar.


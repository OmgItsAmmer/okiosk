/// Example Usage for Voice Assistant Module
///
/// This file demonstrates how to integrate the voice assistant
/// into your Flutter application.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'voice_assistant.dart';

/// Example 1: Basic Voice Assistant Screen
class VoiceAssistantExample extends StatelessWidget {
  const VoiceAssistantExample({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize the voice controller
    final voiceController = Get.put(VoiceController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Assistant Example'),
      ),
      body: Center(
        child: VoiceAssistantWidget(
          onTranscriptionComplete: () {
            // Get the transcribed text
            final text = voiceController.getTranscriptionForAI();

            // Show in a dialog
            Get.dialog(
              AlertDialog(
                title: const Text('Transcription Complete'),
                content: Text(text),
                actions: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Example 2: Simple Voice Button
class VoiceButtonExample extends StatelessWidget {
  const VoiceButtonExample({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(VoiceController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Button Example'),
      ),
      body: Center(
        child: VoiceButton(
          size: 80,
          activeColor: Colors.red,
          inactiveColor: Colors.blue,
          onTranscriptionComplete: () {
            final controller = Get.find<VoiceController>();
            final text = controller.finalTranscription;

            Get.snackbar(
              'Transcription',
              text,
              snackPosition: SnackPosition.BOTTOM,
            );
          },
        ),
      ),
    );
  }
}

/// Example 3: Voice-Enabled Chat
class VoiceEnabledChatExample extends StatefulWidget {
  const VoiceEnabledChatExample({super.key});

  @override
  State<VoiceEnabledChatExample> createState() =>
      _VoiceEnabledChatExampleState();
}

class _VoiceEnabledChatExampleState extends State<VoiceEnabledChatExample> {
  final TextEditingController textController = TextEditingController();
  final List<String> messages = [];
  late VoiceController voiceController;

  @override
  void initState() {
    super.initState();
    voiceController = Get.put(VoiceController());
  }

  void sendMessage(String message) {
    if (message.trim().isEmpty) return;

    setState(() {
      messages.add(message);
    });

    textController.clear();

    // Process message with AI here
    debugPrint('Processing: $message');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice-Enabled Chat'),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(messages[index]),
                );
              },
            ),
          ),

          // Input area with voice button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Voice button
                VoiceButton(
                  size: 48,
                  onTranscriptionComplete: () {
                    final text = voiceController.getTranscriptionForAI();
                    sendMessage(text);
                  },
                ),

                const SizedBox(width: 8),

                // Text input
                Expanded(
                  child: TextField(
                    controller: textController,
                    decoration: const InputDecoration(
                      hintText: 'Type or speak...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: sendMessage,
                  ),
                ),

                const SizedBox(width: 8),

                // Send button
                IconButton(
                  onPressed: () => sendMessage(textController.text),
                  icon: const Icon(Icons.send),
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Example 4: POS Integration
class VoicePOSExample extends StatelessWidget {
  const VoicePOSExample({super.key});

  @override
  Widget build(BuildContext context) {
    final voiceController = Get.put(VoiceController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice POS'),
      ),
      body: Row(
        children: [
          // Product area
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.grey.shade200,
              child: const Center(
                child: Text('Product Grid'),
              ),
            ),
          ),

          // Voice assistant sidebar
          Container(
            width: 350,
            color: Colors.white,
            child: Column(
              children: [
                // Voice assistant
                VoiceAssistantWidget(
                  compactMode: false,
                  showTranscription: true,
                  onTranscriptionComplete: () {
                    final command = voiceController.getTranscriptionForAI();
                    _processVoiceCommand(command);
                  },
                ),

                const Divider(),

                // Order summary
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: const Text('Order Summary'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _processVoiceCommand(String command) {
    // Parse and execute voice command
    debugPrint('Voice command: $command');

    // Examples:
    // "Add 2 coffees to cart"
    // "Show me pizzas"
    // "Clear cart"
    // "Checkout"
  }
}

/// Example 5: Custom Configuration
class CustomConfigExample extends StatelessWidget {
  const CustomConfigExample({super.key});

  @override
  Widget build(BuildContext context) {
    final voiceController = Get.put(VoiceController());

    // Set custom WebSocket URL (e.g., for production server)
    voiceController.setWebSocketUrl('ws://your-server.com:8080/ws/voice');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Config Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Status display
            Obx(() {
              return Text(
                'State: ${voiceController.voiceStateObs.value}',
                style: const TextStyle(fontSize: 18),
              );
            }),

            const SizedBox(height: 20),

            // Live transcription
            Obx(() {
              final text = voiceController.currentTranscriptionObs.value;
              return Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 32),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  text.isEmpty ? 'No transcription yet' : text,
                  textAlign: TextAlign.center,
                ),
              );
            }),

            const SizedBox(height: 20),

            // Voice button
            VoiceButton(size: 80),

            const SizedBox(height: 20),

            // Manual controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => voiceController.startRecording(),
                  child: const Text('Start'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => voiceController.stopRecording(),
                  child: const Text('Stop'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => voiceController.toggleMute(),
                  child: const Text('Mute/Unmute'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => voiceController.clearTranscription(),
                  child: const Text('Clear'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Main example app
void main() {
  runApp(const VoiceAssistantExampleApp());
}

class VoiceAssistantExampleApp extends StatelessWidget {
  const VoiceAssistantExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Voice Assistant Examples',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ExampleSelector(),
    );
  }
}

class ExampleSelector extends StatelessWidget {
  const ExampleSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Assistant Examples'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildExampleTile(
            context,
            'Basic Voice Assistant',
            'Full-featured voice assistant widget',
            () => Get.to(() => const VoiceAssistantExample()),
          ),
          _buildExampleTile(
            context,
            'Simple Voice Button',
            'Minimalist voice button',
            () => Get.to(() => const VoiceButtonExample()),
          ),
          _buildExampleTile(
            context,
            'Voice-Enabled Chat',
            'Chat interface with voice input',
            () => Get.to(() => const VoiceEnabledChatExample()),
          ),
          _buildExampleTile(
            context,
            'POS Integration',
            'Point of sale with voice commands',
            () => Get.to(() => const VoicePOSExample()),
          ),
          _buildExampleTile(
            context,
            'Custom Configuration',
            'Manual controls and custom setup',
            () => Get.to(() => const CustomConfigExample()),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleTile(
    BuildContext context,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}

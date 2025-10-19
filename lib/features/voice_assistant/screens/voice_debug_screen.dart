// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../controller/voice_controller.dart';
// import '../utils/desktop_permission_helper.dart';
// import '../services/voice_recording_service.dart';

// /// Voice Debug Screen
// /// Provides comprehensive debugging information for voice assistant issues
// class VoiceDebugScreen extends StatefulWidget {
//   const VoiceDebugScreen({super.key});

//   @override
//   State<VoiceDebugScreen> createState() => _VoiceDebugScreenState();
// }

// class _VoiceDebugScreenState extends State<VoiceDebugScreen> {
//   final VoiceController _voiceController = Get.find<VoiceController>();
//   Map<String, dynamic> _diagnostics = {};
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadDiagnostics();
//   }

//   Future<void> _loadDiagnostics() async {
//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       final diagnostics =
//           await DesktopPermissionHelper.getPermissionDiagnostics();
//       setState(() {
//         _diagnostics = diagnostics;
//         _isLoading = false;
//       });
//     } catch (e) {
//       debugPrint('Error loading diagnostics: $e');
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Voice Assistant Debug'),
//         backgroundColor: Theme.of(context).primaryColor,
//         foregroundColor: Colors.white,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildHeader(),
//             const SizedBox(height: 20),
//             _buildVoiceControllerStatus(),
//             const SizedBox(height: 20),
//             _buildPermissionDiagnostics(),
//             const SizedBox(height: 20),
//             _buildActionButtons(),
//             const SizedBox(height: 20),
//             _buildDebugLogs(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildHeader() {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(
//                   Icons.bug_report,
//                   color: Theme.of(context).primaryColor,
//                   size: 24,
//                 ),
//                 const SizedBox(width: 8),
//                 Text(
//                   'Voice Assistant Debug Information',
//                   style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                         fontWeight: FontWeight.bold,
//                       ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             const Text(
//               'This screen helps diagnose microphone and voice assistant issues.',
//               style: TextStyle(color: Colors.grey),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildVoiceControllerStatus() {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Voice Controller Status',
//               style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                     fontWeight: FontWeight.bold,
//                   ),
//             ),
//             const SizedBox(height: 12),
//             Obx(() {
//               final state = _voiceController.voiceStateObs.value;
//               final error = _voiceController.errorMessage;
//               final isRecording = _voiceController.isRecording;
//               final duration = _voiceController.recordingDuration;

//               return Column(
//                 children: [
//                   _buildStatusRow(
//                       'State', state.toString(), _getStateColor(state)),
//                   _buildStatusRow('Recording', isRecording ? 'Yes' : 'No',
//                       isRecording ? Colors.red : Colors.grey),
//                   _buildStatusRow('Duration', '${duration.toStringAsFixed(1)}s',
//                       Colors.blue),
//                   if (error.isNotEmpty)
//                     _buildStatusRow('Error', error, Colors.red),
//                 ],
//               );
//             }),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildPermissionDiagnostics() {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Text(
//                   'Permission Diagnostics',
//                   style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                         fontWeight: FontWeight.bold,
//                       ),
//                 ),
//                 const Spacer(),
//                 if (_isLoading)
//                   const SizedBox(
//                     width: 16,
//                     height: 16,
//                     child: CircularProgressIndicator(strokeWidth: 2),
//                   )
//                 else
//                   IconButton(
//                     onPressed: _loadDiagnostics,
//                     icon: const Icon(Icons.refresh),
//                     tooltip: 'Refresh diagnostics',
//                   ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             if (_diagnostics.isEmpty && !_isLoading)
//               const Text(
//                 'No diagnostic information available',
//                 style: TextStyle(color: Colors.grey),
//               )
//             else
//               ..._diagnostics.entries.map((entry) {
//                 return _buildStatusRow(
//                   entry.key,
//                   entry.value.toString(),
//                   _getDiagnosticColor(entry.key, entry.value),
//                 );
//               }),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildActionButtons() {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Debug Actions',
//               style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                     fontWeight: FontWeight.bold,
//                   ),
//             ),
//             const SizedBox(height: 12),
//             Wrap(
//               spacing: 8,
//               runSpacing: 8,
//               children: [
//                 ElevatedButton.icon(
//                   onPressed: () async {
//                     try {
//                       await _voiceController.clearTranscription();
//                       Get.snackbar('Success', 'Transcription cleared');
//                     } catch (e) {
//                       Get.snackbar(
//                           'Error', 'Failed to clear transcription: $e');
//                     }
//                   },
//                   icon: const Icon(Icons.clear, size: 18),
//                   label: const Text('Clear Transcription'),
//                 ),
//                 ElevatedButton.icon(
//                   onPressed: () async {
//                     try {
//                       await _loadDiagnostics();
//                       Get.snackbar('Success', 'Diagnostics refreshed');
//                     } catch (e) {
//                       Get.snackbar(
//                           'Error', 'Failed to refresh diagnostics: $e');
//                     }
//                   },
//                   icon: const Icon(Icons.refresh, size: 18),
//                   label: const Text('Refresh Diagnostics'),
//                 ),
//                 ElevatedButton.icon(
//                   onPressed: () async {
//                     try {
//                       final service = VoiceRecordingService();
//                       final initialized = await service.initialize();
//                       Get.snackbar(
//                         initialized ? 'Success' : 'Failed',
//                         initialized
//                             ? 'Recording service initialized'
//                             : 'Failed to initialize recording service',
//                       );
//                     } catch (e) {
//                       Get.snackbar(
//                           'Error', 'Failed to test recording service: $e');
//                     }
//                   },
//                   icon: const Icon(Icons.mic, size: 18),
//                   label: const Text('Test Recording Service'),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDebugLogs() {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Debug Information',
//               style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                     fontWeight: FontWeight.bold,
//                   ),
//             ),
//             const SizedBox(height: 12),
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade100,
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: Colors.grey.shade300),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Common Issues & Solutions:',
//                     style: TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 8),
//                   const Text('1. Microphone Permission: Check system settings'),
//                   const Text('2. Audio Device: Ensure microphone is connected'),
//                   const Text('3. Flutter Sound: Check package compatibility'),
//                   const Text('4. Desktop Platform: Verify audio drivers'),
//                   const SizedBox(height: 8),
//                   const Text(
//                     'For detailed logs, check the console output.',
//                     style: TextStyle(fontStyle: FontStyle.italic),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStatusRow(String label, String value, Color color) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 120,
//             child: Text(
//               '$label:',
//               style: const TextStyle(fontWeight: FontWeight.w500),
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value,
//               style: TextStyle(color: color),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Color _getStateColor(dynamic state) {
//     if (state.toString().contains('error')) return Colors.red;
//     if (state.toString().contains('recording')) return Colors.green;
//     if (state.toString().contains('idle')) return Colors.blue;
//     return Colors.grey;
//   }

//   Color _getDiagnosticColor(String key, dynamic value) {
//     if (key.contains('Status') && value.toString().contains('granted')) {
//       return Colors.green;
//     }
//     if (key.contains('Status') && value.toString().contains('denied')) {
//       return Colors.red;
//     }
//     if (key.contains('Working') && value == true) {
//       return Colors.green;
//     }
//     if (key.contains('Working') && value == false) {
//       return Colors.red;
//     }
//     return Colors.grey;
//   }
// }

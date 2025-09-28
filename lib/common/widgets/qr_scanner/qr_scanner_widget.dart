// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';

// import '../../../utils/constants/colors.dart';
// import '../../../utils/constants/sizes.dart';

// class QRScannerWidget extends StatefulWidget {
//   final Function(String) onQRCodeScanned;
//   final String title;
//   final String subtitle;

//   const QRScannerWidget({
//     super.key,
//     required this.onQRCodeScanned,
//     this.title = 'Scan Customer QR Code',
//     this.subtitle = 'Position the QR code within the frame to scan',
//   });

//   @override
//   State<QRScannerWidget> createState() => _QRScannerWidgetState();
// }

// class _QRScannerWidgetState extends State<QRScannerWidget> {
//   MobileScannerController cameraController = MobileScannerController();
//   bool _isScanning = true;

//   @override
//   void dispose() {
//     cameraController.dispose();
//     super.dispose();
//   }

//   void _onDetect(BarcodeCapture capture) {
//     if (!_isScanning) return;

//     final List<Barcode> barcodes = capture.barcodes;
//     for (final barcode in barcodes) {
//       if (barcode.rawValue != null) {
//         _isScanning = false;
//         widget.onQRCodeScanned(barcode.rawValue!);
//         break;
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         backgroundColor: Colors.black,
//         title: Text(
//           widget.title,
//           style: const TextStyle(color: Colors.white),
//         ),
//         leading: IconButton(
//           icon: const Icon(Icons.close, color: Colors.white),
//           onPressed: () => Get.back(),
//         ),
//         actions: [
//           IconButton(
//             icon: Icon(
//               cameraController.torchEnabled ? Icons.flash_on : Icons.flash_off,
//               color: Colors.white,
//             ),
//             onPressed: () => cameraController.toggleTorch(),
//           ),
//           IconButton(
//             icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
//             onPressed: () => cameraController.switchCamera(),
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             flex: 4,
//             child: Stack(
//               children: [
//                 MobileScanner(
//                   controller: cameraController,
//                   onDetect: _onDetect,
//                 ),
//                 // Overlay with scanning frame
//                 Container(
//                   decoration: ShapeDecoration(
//                     shape: QrScannerOverlayShape(
//                       borderColor: TColors.primary,
//                       borderRadius: 10,
//                       borderLength: 30,
//                       borderWidth: 10,
//                       cutOutSize: 250,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Expanded(
//             flex: 1,
//             child: Container(
//               padding: const EdgeInsets.all(TSizes.defaultSpace),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text(
//                     widget.subtitle,
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 16,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                   const SizedBox(height: TSizes.spaceBtwItems),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                     children: [
//                       ElevatedButton.icon(
//                         onPressed: () {
//                           setState(() {
//                             _isScanning = true;
//                           });
//                         },
//                         icon: const Icon(Icons.refresh),
//                         label: const Text('Retry Scan'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: TColors.primary,
//                           foregroundColor: Colors.white,
//                         ),
//                       ),
//                       ElevatedButton.icon(
//                         onPressed: () => Get.back(),
//                         icon: const Icon(Icons.close),
//                         label: const Text('Cancel'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.grey[700],
//                           foregroundColor: Colors.white,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// /// Custom overlay shape for QR scanner
// class QrScannerOverlayShape extends ShapeBorder {
//   const QrScannerOverlayShape({
//     this.borderColor = Colors.red,
//     this.borderWidth = 3.0,
//     this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
//     this.borderRadius = 0,
//     this.borderLength = 40,
//     double? cutOutSize,
//   }) : cutOutSize = cutOutSize ?? 250;

//   final Color borderColor;
//   final double borderWidth;
//   final Color overlayColor;
//   final double borderRadius;
//   final double borderLength;
//   final double cutOutSize;

//   @override
//   EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

//   @override
//   Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
//     return Path()
//       ..fillType = PathFillType.evenOdd
//       ..addPath(getOuterPath(rect), Offset.zero);
//   }

//   @override
//   Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
//     Path getLeftTopPath(Rect rect) {
//       return Path()
//         ..moveTo(rect.left, rect.bottom)
//         ..lineTo(rect.left, rect.top + borderRadius)
//         ..quadraticBezierTo(
//             rect.left, rect.top, rect.left + borderRadius, rect.top)
//         ..lineTo(rect.right, rect.top);
//     }

//     return getLeftTopPath(rect)
//       ..lineTo(rect.right, rect.bottom)
//       ..lineTo(rect.left, rect.bottom)
//       ..lineTo(rect.left, rect.top);
//   }

//   @override
//   void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
//     final width = rect.width;
//     final height = rect.height;
//     final borderOffset = borderWidth / 2;
//     final cutOutWidth = cutOutSize + borderOffset;
//     final cutOutHeight = cutOutSize + borderOffset;

//     final cutOutRect = Rect.fromLTWH(
//       rect.left + width / 2 - cutOutWidth / 2 + borderOffset,
//       rect.top + height / 2 - cutOutHeight / 2 + borderOffset,
//       cutOutWidth,
//       cutOutHeight,
//     );

//     final overlayPaint = Paint()..color = overlayColor;
//     final borderPaint = Paint()
//       ..color = borderColor
//       ..strokeWidth = borderWidth
//       ..style = PaintingStyle.stroke;

//     final outerRRect = RRect.fromRectAndRadius(rect, Radius.zero);
//     final innerRRect =
//         RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius));
//     canvas.drawDRRect(outerRRect, innerRRect, overlayPaint);

//     // Draw corner lines
//     final path = Path();

//     // Top-left corner
//     path.moveTo(cutOutRect.left - borderOffset, cutOutRect.top + borderLength);
//     path.lineTo(cutOutRect.left - borderOffset, cutOutRect.top + borderRadius);
//     path.quadraticBezierTo(
//         cutOutRect.left - borderOffset,
//         cutOutRect.top - borderOffset,
//         cutOutRect.left + borderRadius,
//         cutOutRect.top - borderOffset);
//     path.lineTo(cutOutRect.left + borderLength, cutOutRect.top - borderOffset);

//     // Top-right corner
//     path.moveTo(cutOutRect.right + borderOffset - borderLength,
//         cutOutRect.top - borderOffset);
//     path.lineTo(cutOutRect.right - borderRadius, cutOutRect.top - borderOffset);
//     path.quadraticBezierTo(
//         cutOutRect.right + borderOffset,
//         cutOutRect.top - borderOffset,
//         cutOutRect.right + borderOffset,
//         cutOutRect.top + borderRadius);
//     path.lineTo(cutOutRect.right + borderOffset, cutOutRect.top + borderLength);

//     // Bottom-left corner
//     path.moveTo(
//         cutOutRect.left - borderOffset, cutOutRect.bottom - borderLength);
//     path.lineTo(
//         cutOutRect.left - borderOffset, cutOutRect.bottom - borderRadius);
//     path.quadraticBezierTo(
//         cutOutRect.left - borderOffset,
//         cutOutRect.bottom + borderOffset,
//         cutOutRect.left + borderRadius,
//         cutOutRect.bottom + borderOffset);
//     path.lineTo(
//         cutOutRect.left + borderLength, cutOutRect.bottom + borderOffset);

//     // Bottom-right corner
//     path.moveTo(cutOutRect.right + borderOffset - borderLength,
//         cutOutRect.bottom + borderOffset);
//     path.lineTo(
//         cutOutRect.right - borderRadius, cutOutRect.bottom + borderOffset);
//     path.quadraticBezierTo(
//         cutOutRect.right + borderOffset,
//         cutOutRect.bottom + borderOffset,
//         cutOutRect.right + borderOffset,
//         cutOutRect.bottom - borderRadius);
//     path.lineTo(
//         cutOutRect.right + borderOffset, cutOutRect.bottom - borderLength);

//     canvas.drawPath(path, borderPaint);
//   }

//   @override
//   ShapeBorder scale(double t) {
//     return QrScannerOverlayShape(
//       borderColor: borderColor,
//       borderWidth: borderWidth,
//       overlayColor: overlayColor,
//     );
//   }
// }

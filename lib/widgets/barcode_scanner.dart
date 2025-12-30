import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      _isProcessing = true;
      final value = barcodes.first.rawValue!;

      // Return the scanned value and close the scanner
      Navigator.pop(context, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: controller.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off);
                  case TorchState.on:
                    return const Icon(Icons.flash_on);
                }
              },
            ),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera Preview
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),

          // Overlay with scan area
          Container(
            decoration: ShapeDecoration(
              shape: _ScanOverlayShape(),
            ),
          ),

          // Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'Point camera at barcode',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),

          // Manual entry button
          Positioned(
            bottom: 32,
            left: 16,
            right: 16,
            child: ElevatedButton.icon(
              onPressed: () => _showManualEntryDialog(context),
              icon: const Icon(Icons.edit),
              label: const Text('Enter ID Manually'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showManualEntryDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Record ID'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Enter ID number',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(this.context, value); // Return value
              }
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }
}

class _ScanOverlayShape extends ShapeBorder {
  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path();

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final path = Path()..addRect(rect);

    // Create a centered square cutout
    const size = 250.0;
    final cutout = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: rect.center,
        width: size,
        height: size,
      ),
      const Radius.circular(16),
    );

    path.addRRect(cutout);
    path.fillType = PathFillType.evenOdd;

    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    final path = getOuterPath(rect);
    canvas.drawPath(path, paint);

    // Draw corner brackets
    const size = 250.0;
    final center = rect.center;
    final scanRect = Rect.fromCenter(
      center: center,
      width: size,
      height: size,
    );

    final bracketPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    const bracketLength = 30.0;
    const radius = 16.0;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.left, scanRect.top + bracketLength)
        ..lineTo(scanRect.left, scanRect.top + radius)
        ..arcToPoint(
          Offset(scanRect.left + radius, scanRect.top),
          radius: const Radius.circular(radius),
        )
        ..lineTo(scanRect.left + bracketLength, scanRect.top),
      bracketPaint,
    );

    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.right - bracketLength, scanRect.top)
        ..lineTo(scanRect.right - radius, scanRect.top)
        ..arcToPoint(
          Offset(scanRect.right, scanRect.top + radius),
          radius: const Radius.circular(radius),
        )
        ..lineTo(scanRect.right, scanRect.top + bracketLength),
      bracketPaint,
    );

    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.left, scanRect.bottom - bracketLength)
        ..lineTo(scanRect.left, scanRect.bottom - radius)
        ..arcToPoint(
          Offset(scanRect.left + radius, scanRect.bottom),
          radius: const Radius.circular(radius),
        )
        ..lineTo(scanRect.left + bracketLength, scanRect.bottom),
      bracketPaint,
    );

    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.right - bracketLength, scanRect.bottom)
        ..lineTo(scanRect.right - radius, scanRect.bottom)
        ..arcToPoint(
          Offset(scanRect.right, scanRect.bottom - radius),
          radius: const Radius.circular(radius),
        )
        ..lineTo(scanRect.right, scanRect.bottom - bracketLength),
      bracketPaint,
    );
  }

  @override
  ShapeBorder scale(double t) => this;
}

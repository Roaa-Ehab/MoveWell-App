import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movewell/core/theme/colors.dart';
import 'package:movewell/core/services/chat_service.dart';

import 'package:mobile_scanner/mobile_scanner.dart'
    if (dart.library.html) 'package:mobile_scanner/mobile_scanner.dart';

class DoctorQrScannerScreen extends StatefulWidget {
  const DoctorQrScannerScreen({super.key});

  @override
  State<DoctorQrScannerScreen> createState() => _DoctorQrScannerScreenState();
}

class _DoctorQrScannerScreenState extends State<DoctorQrScannerScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _manualIdController = TextEditingController();
  final TextEditingController _manualNameController = TextEditingController();
  final TextEditingController _manualEmailController = TextEditingController();
  
  MobileScannerController? _cameraController;
  bool _hasScanned = false;
  bool _isManualMode = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  void _initCamera() {
    if (!mounted) return;
    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _manualIdController.dispose();
    _manualNameController.dispose();
    _manualEmailController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned || !mounted) return;
    
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final data = barcode.rawValue!;
    if (!data.startsWith('MOVEWELL_PATIENT|')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid QR code. Not a MoveWell patient.')),
      );
      return;
    }

    setState(() => _hasScanned = true);
    _cameraController?.stop();

    final parts = data.split('|');
    final patientId = parts.length > 1 ? parts[1] : '';
    final name = parts.length > 2 ? parts[2] : 'Unknown';
    final email = parts.length > 3 ? parts[3] : '';

    _showPatientFoundSheet(patientId: patientId, name: name, email: email);
  }

  Future<void> _addPatientManually() async {
    final patientId = _manualIdController.text.trim();
    final name = _manualNameController.text.trim();
    final email = _manualEmailController.text.trim();

    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter patient name and email')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final finalPatientId = patientId.isNotEmpty ? patientId : 'temp_${DateTime.now().millisecondsSinceEpoch}';
      await _chatService.createConversation(finalPatientId);
      
      if (mounted) {
        setState(() => _isSubmitting = false);
        setState(() => _isManualMode = false);
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name added to your patients.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add patient: $e')),
        );
      }
    }
  }

  void _showPatientFoundSheet({
    required String patientId,
    required String name,
    required String email,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4ECDC4).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF4ECDC4),
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Patient Found!',
                  style: GoogleFonts.leagueSpartan(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.surface,
                        child: Text(
                          name.isNotEmpty ? name[0] : '?',
                          style: GoogleFonts.leagueSpartan(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        name,
                        style: GoogleFonts.leagueSpartan(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: GoogleFonts.leagueSpartan(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      try {
                        if (patientId.isNotEmpty) {
                          await _chatService.createConversation(patientId);
                        }
                        if (mounted) {
                          Navigator.pop(context, true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$name added to your patients.')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to add patient: $e')),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Add to My Patients',
                      style: GoogleFonts.leagueSpartan(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() => _hasScanned = false);
                    _cameraController?.start();
                  },
                  child: Text(
                    'Scan Again',
                    style: GoogleFonts.leagueSpartan(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildManualEntryForm() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Add Patient Manually',
          style: GoogleFonts.leagueSpartan(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _isManualMode = false),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            TextField(
              controller: _manualIdController,
              decoration: const InputDecoration(
                labelText: 'Patient ID (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _manualNameController,
              decoration: const InputDecoration(
                labelText: 'Full Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _manualEmailController,
              decoration: const InputDecoration(
                labelText: 'Email Address *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _addPatientManually,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'Add Patient',
                        style: GoogleFonts.leagueSpartan(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isManualMode) {
      return _buildManualEntryForm();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _cameraController!,
            onDetect: _onDetect,
          ),
          _buildOverlay(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Scan Patient QR',
                    style: GoogleFonts.leagueSpartan(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _isManualMode = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.edit, color: Colors.white, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            'Manual',
                            style: GoogleFonts.leagueSpartan(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  'Point camera at patient\'s QR code',
                  style: GoogleFonts.leagueSpartan(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scanSize = constraints.maxWidth * 0.7;
        final left = (constraints.maxWidth - scanSize) / 2;
        final top = (constraints.maxHeight - scanSize) / 2 - 30;

        return IgnorePointer(
          child: CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: ScannerOverlayPainter(
              scanRect: Rect.fromLTWH(left, top, scanSize, scanSize),
              cornerColor: AppColors.primary,
            ),
          ),
        );
      },
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  final Rect scanRect;
  final Color cornerColor;

  ScannerOverlayPainter({
    required this.scanRect,
    required this.cornerColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Dark overlay
    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.6);
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(scanRect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(overlayPath, overlayPaint);

    // Draw corners
    final cornerPaint = Paint()
      ..color = cornerColor
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    const cornerLength = 30.0;
    
    // Top-left
    canvas.drawLine(Offset(scanRect.left, scanRect.top + cornerLength), Offset(scanRect.left, scanRect.top), cornerPaint);
    canvas.drawLine(Offset(scanRect.left, scanRect.top), Offset(scanRect.left + cornerLength, scanRect.top), cornerPaint);

    // Top-right
    canvas.drawLine(Offset(scanRect.right, scanRect.top + cornerLength), Offset(scanRect.right, scanRect.top), cornerPaint);
    canvas.drawLine(Offset(scanRect.right, scanRect.top), Offset(scanRect.right - cornerLength, scanRect.top), cornerPaint);

    // Bottom-left
    canvas.drawLine(Offset(scanRect.left, scanRect.bottom - cornerLength), Offset(scanRect.left, scanRect.bottom), cornerPaint);
    canvas.drawLine(Offset(scanRect.left, scanRect.bottom), Offset(scanRect.left + cornerLength, scanRect.bottom), cornerPaint);

    // Bottom-right
    canvas.drawLine(Offset(scanRect.right, scanRect.bottom - cornerLength), Offset(scanRect.right, scanRect.bottom), cornerPaint);
    canvas.drawLine(Offset(scanRect.right, scanRect.bottom), Offset(scanRect.right - cornerLength, scanRect.bottom), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:movewell/core/theme/colors.dart';
import 'package:movewell/core/services/doctor_service.dart';

class DoctorQrScannerScreen extends StatefulWidget {
  const DoctorQrScannerScreen({super.key});

  @override
  State<DoctorQrScannerScreen> createState() => _DoctorQrScannerScreenState();
}

class _DoctorQrScannerScreenState extends State<DoctorQrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final DoctorService _doctorService = DoctorService();
  bool _hasScanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_hasScanned) return;
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
    _controller.stop();

    final parts = data.split('|');
    final email = parts.length > 2 ? parts[2] : '';

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid QR: No email found')),
      );
      setState(() => _hasScanned = false);
      _controller.start();
      return;
    }

    try {
      final patientData = await _doctorService.getPatientByEmail(email);
      if (mounted) {
        _showPatientFoundSheet(patientData);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Patient not found: $e')),
        );
        setState(() => _hasScanned = false);
        _controller.start();
      }
    }
  }

  void _showPatientFoundSheet(Map<String, dynamic> patient) async {
    final patientUserId = patient['userId']['_id'];
    final patientName = patient['userId']['name'] ?? 'Patient';
    final patientEmail = patient['userId']['email'] ?? '';
    final diagnosis = patient['injuryType'] ?? 'Not specified';
    final bloodType = patient['bloodType'] ?? 'N/A';
    final height = patient['height'] != null ? '${patient['height']} cm' : 'N/A';
    final weight = patient['weight'] != null ? '${patient['weight']} kg' : 'N/A';
    final emergency = patient['emergencyContact'] ?? 'N/A';

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
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.surface,
                        child: Text(
                          patientName.isNotEmpty ? patientName[0] : '?',
                          style: GoogleFonts.leagueSpartan(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        patientName,
                        style: GoogleFonts.leagueSpartan(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        patientEmail,
                        style: GoogleFonts.leagueSpartan(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: 12),
                      _buildDetailRow('Diagnosis', diagnosis),
                      _buildDetailRow('Blood Type', bloodType),
                      _buildDetailRow('Height', height),
                      _buildDetailRow('Weight', weight),
                      _buildDetailRow('Emergency', emergency),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Adding patient...')),
                      );
                      
                      try {
                        await _doctorService.addPatientToMyList(patientUserId);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$patientName added to your patients.'),
                              backgroundColor: const Color(0xFF4ECDC4),
                            ),
                          );
                          Navigator.pop(context, true);
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to add patient: $e')),
                          );
                          setState(() => _hasScanned = false);
                          _controller.start();
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
                    _controller.start();
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: GoogleFonts.leagueSpartan(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.leagueSpartan(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
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
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
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
                  const SizedBox(width: 44),
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
          child: Stack(
            children: [
              // Semi-transparent background with cutout
              CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: _OverlayPainter(
                  cutoutRect: Rect.fromLTWH(left, top, scanSize, scanSize),
                ),
              ),
              // White corners
              Positioned(
                left: left,
                top: top,
                child: _buildCorner(isLeft: true, isTop: true),
              ),
              Positioned(
                right: constraints.maxWidth - left - scanSize,
                top: top,
                child: _buildCorner(isLeft: false, isTop: true),
              ),
              Positioned(
                left: left,
                bottom: constraints.maxHeight - top - scanSize,
                child: _buildCorner(isLeft: true, isTop: false),
              ),
              Positioned(
                right: constraints.maxWidth - left - scanSize,
                bottom: constraints.maxHeight - top - scanSize,
                child: _buildCorner(isLeft: false, isTop: false),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCorner({required bool isLeft, required bool isTop}) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? BorderSide(color: Colors.white, width: 4) : BorderSide.none,
          left: isLeft ? BorderSide(color: Colors.white, width: 4) : BorderSide.none,
          right: !isLeft ? BorderSide(color: Colors.white, width: 4) : BorderSide.none,
          bottom: !isTop ? BorderSide(color: Colors.white, width: 4) : BorderSide.none,
        ),
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final Rect cutoutRect;

  _OverlayPainter({required this.cutoutRect});

  @override
  void paint(Canvas canvas, Size size) {
    final RRect rRect = RRect.fromRectAndRadius(
      cutoutRect, 
      const Radius.circular(24) 
    );

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRRect(rRect),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.6),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:movewell/core/theme/colors.dart';

class DoctorQrScannerScreen extends StatefulWidget {
  const DoctorQrScannerScreen({super.key});

  @override
  State<DoctorQrScannerScreen> createState() => _DoctorQrScannerScreenState();
}

class _DoctorQrScannerScreenState extends State<DoctorQrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _hasScanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
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
    final name = parts.length > 1 ? parts[1] : 'Unknown';
    final email = parts.length > 2 ? parts[2] : '';
    final bloodType = parts.length > 3 ? parts[3] : 'N/A';
    final height = parts.length > 4 ? parts[4] : 'N/A';
    final weight = parts.length > 5 ? parts[5] : 'N/A';
    final diagnosis = parts.length > 6 ? parts[6] : 'N/A';
    final emergency = parts.length > 7 ? parts[7] : 'N/A';

    _showPatientFoundSheet(
      name: name,
      email: email,
      bloodType: bloodType,
      height: height,
      weight: weight,
      diagnosis: diagnosis,
      emergency: emergency,
    );
  }

  void _showPatientFoundSheet({
    required String name,
    required String email,
    required String bloodType,
    required String height,
    required String weight,
    required String diagnosis,
    required String emergency,
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
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pop(context, true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$name added to your patients.'),
                          backgroundColor: const Color(0xFF4ECDC4),
                        ),
                      );
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
                        color: Colors.white.withValues(alpha: 0.15),
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
                  color: Colors.black.withValues(alpha: 0.6),
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

        return Stack(
          children: [
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.5),
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  Positioned(
                    left: left,
                    top: top,
                    child: Container(
                      width: scanSize,
                      height: scanSize,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: left - 2,
              top: top - 2,
              child: _buildCorner(true, true),
            ),
            Positioned(
              right: left - 2,
              top: top - 2,
              child: _buildCorner(false, true),
            ),
            Positioned(
              left: left - 2,
              bottom: constraints.maxHeight - top - scanSize - 2,
              child: _buildCorner(true, false),
            ),
            Positioned(
              right: left - 2,
              bottom: constraints.maxHeight - top - scanSize - 2,
              child: _buildCorner(false, false),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCorner(bool isLeft, bool isTop) {
    return SizedBox(
      width: 32,
      height: 32,
      child: CustomPaint(
        painter: _CornerPainter(
          isLeft: isLeft,
          isTop: isTop,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final bool isLeft;
  final bool isTop;
  final Color color;

  _CornerPainter({
    required this.isLeft,
    required this.isTop,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    if (isLeft && isTop) {
      path.moveTo(0, size.height);
      path.lineTo(0, 8);
      path.quadraticBezierTo(0, 0, 8, 0);
      path.lineTo(size.width, 0);
    } else if (!isLeft && isTop) {
      path.moveTo(0, 0);
      path.lineTo(size.width - 8, 0);
      path.quadraticBezierTo(size.width, 0, size.width, 8);
      path.lineTo(size.width, size.height);
    } else if (isLeft && !isTop) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height - 8);
      path.quadraticBezierTo(0, size.height, 8, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(size.width, 0);
      path.lineTo(size.width, size.height - 8);
      path.quadraticBezierTo(size.width, size.height, size.width - 8, size.height);
      path.lineTo(0, size.height);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
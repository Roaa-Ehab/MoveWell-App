import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:movewell/core/theme/colors.dart';
import 'package:movewell/core/services/agora_service.dart';
import 'package:movewell/core/features/video_session/screens/video_session_screen.dart';
import 'package:provider/provider.dart';
import 'package:movewell/core/features/auth/providers/auth_provider.dart';

class WaitingRoomScreen extends StatefulWidget {
  final String channelName;
  final String remoteName;

  const WaitingRoomScreen({
    super.key,
    required this.channelName,
    this.remoteName = 'your therapist',
  });

  @override
  State<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends State<WaitingRoomScreen> {
  final AgoraService _agora = AgoraService();
  bool _isMicOn = true;
  bool _isCamOn = true;
  bool _isInitializing = true;
  bool _permissionDenied = false;
  bool _isDoctor = false;

  @override
  void initState() {
    super.initState();
    _checkRole();
    _initAgora();
  }

  void _checkRole() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _isDoctor = authProvider.userRole == 'doctor';
  }

  Future<void> _initAgora() async {
    final granted = await _agora.requestPermissions();
    if (!granted) {
      if (mounted) {
        setState(() {
          _permissionDenied = true;
          _isInitializing = false;
        });
      }
      return;
    }

    await _agora.initialize();

    if (mounted) {
      setState(() => _isInitializing = false);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _joinCall() {
    // Patient = 1, Doctor = 2
    final int uid = _isDoctor ? 2 : 1;
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => VideoSessionScreen(
          channelName: widget.channelName,
          remoteName: widget.remoteName,
          initialMicOn: _isMicOn,
          initialCamOn: _isCamOn,
          uid: uid,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      _agora.dispose();
                      Navigator.pop(context);
                    },
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Ready to join?',
                      style: GoogleFonts.leagueSpartan(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.remoteName} is waiting.',
                      style: GoogleFonts.leagueSpartan(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 48),

                    Container(
                      width: double.infinity,
                      height: 380,
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 2),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: Stack(
                        children: [
                          if (_permissionDenied)
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.no_photography_rounded, size: 48, color: Colors.grey[600]),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Camera permission denied',
                                    style: GoogleFonts.leagueSpartan(color: Colors.grey[500], fontSize: 14),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () => openAppSettings(),
                                    child: Text('Open Settings', style: GoogleFonts.leagueSpartan(
                                      color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                            )
                          else if (_isInitializing)
                            const Center(
                              child: CircularProgressIndicator(color: AppColors.primary),
                            )
                          else if (_isCamOn && _agora.engine != null)
                            AgoraVideoView(
                              controller: VideoViewController(
                                rtcEngine: _agora.engine!,
                                canvas: const VideoCanvas(uid: 0),
                              ),
                            )
                          else
                            Center(
                              child: Icon(
                                Icons.videocam_off_rounded,
                                size: 80,
                                color: Colors.grey[600],
                              ),
                            ),

                          Positioned(
                            bottom: 20,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildToggle(
                                  icon: _isMicOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                                  isActive: _isMicOn,
                                  onTap: () {
                                    setState(() => _isMicOn = !_isMicOn);
                                    _agora.engine?.muteLocalAudioStream(!_isMicOn);
                                  },
                                ),
                                const SizedBox(width: 20),
                                _buildToggle(
                                  icon: _isCamOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                                  isActive: _isCamOn,
                                  onTap: () {
                                    setState(() => _isCamOn = !_isCamOn);
                                    _agora.engine?.muteLocalVideoStream(!_isCamOn);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_isInitializing || _permissionDenied) ? null : _joinCall,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.3),
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Join Call',
                          style: GoogleFonts.leagueSpartan(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggle({required IconData icon, required bool isActive, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withValues(alpha: 0.2) : AppColors.sos.withValues(alpha: 0.8),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:movewell/core/services/agora_service.dart';
import 'package:movewell/core/theme/colors.dart';

class VideoSessionScreen extends StatefulWidget {
  final String channelName;
  final String remoteName;
  final bool initialMicOn;
  final bool initialCamOn;
  final int uid;

  const VideoSessionScreen({
    super.key,
    required this.channelName,
    required this.uid,
    this.remoteName = 'your therapist',
    this.initialMicOn = true,
    this.initialCamOn = true,
  });

  @override
  State<VideoSessionScreen> createState() => _VideoSessionScreenState();
}

class _VideoSessionScreenState extends State<VideoSessionScreen> {
  final AgoraService _agora = AgoraService();
  bool _isMicOn = true;
  bool _isCamOn = true;
  int? _remoteUid;
  bool _isJoining = true;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _isMicOn = widget.initialMicOn;
    _isCamOn = widget.initialCamOn;
    _setupCallbacks();
    _initializeAndJoin();
  }

  void _setupCallbacks() {
    _agora.onJoinSuccess = () {
      if (mounted) {
        setState(() {
          _isJoining = false;
          _isConnected = true;
        });
        _agora.engine?.muteLocalVideoStream(false);
        _agora.engine?.muteLocalAudioStream(false);
      }
    };

    _agora.onRemoteUserJoined = (uid) {
      if (mounted) {
        setState(() {
          _remoteUid = uid;
        });
      }
    };

    _agora.onRemoteUserLeft = (uid) {
      if (mounted) {
        setState(() {
          _remoteUid = null;
        });
      }
    };

    _agora.onDisconnected = () {
      if (mounted) {
        _endCall();
      }
    };
  }

  Future<void> _initializeAndJoin() async {
    await _agora.initialize();
    await _agora.joinChannel(widget.channelName, widget.uid);
  }

  Future<void> _endCall() async {
    await _agora.dispose();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _agora.onJoinSuccess = null;
    _agora.onRemoteUserJoined = null;
    _agora.onRemoteUserLeft = null;
    _agora.onDisconnected = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: (_remoteUid != null && _agora.engine != null && _isConnected)
                ? AgoraVideoView(
                    controller: VideoViewController.remote(
                      rtcEngine: _agora.engine!,
                      canvas: VideoCanvas(uid: _remoteUid),
                      connection: RtcConnection(channelId: widget.channelName),
                    ),
                  )
                : Container(
                    color: const Color(0xFF1A1A1A),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey[850],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person, size: 50, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isJoining
                              ? 'Connecting...'
                              : (_remoteUid == null && _isConnected)
                                  ? 'Waiting for ${widget.remoteName} to join...'
                                  : 'Connecting to ${widget.remoteName}...',
                          style: GoogleFonts.leagueSpartan(
                            color: Colors.white70,
                            fontSize: 18,
                          ),
                        ),
                        if (_isJoining) ...[
                          const SizedBox(height: 20),
                          const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                              strokeWidth: 2.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            right: 20,
            child: GestureDetector(
              onTap: () => _agora.switchCamera(),
              child: Container(
                width: 120,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                ),
                clipBehavior: Clip.hardEdge,
                child: (_isCamOn && _agora.engine != null && _isConnected)
                    ? AgoraVideoView(
                        controller: VideoViewController(
                          rtcEngine: _agora.engine!,
                          canvas: const VideoCanvas(uid: 0),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.videocam_off_rounded, size: 40, color: Colors.grey),
                      ),
              ),
            ),
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            left: 20,
            child: GestureDetector(
              onTap: () => _endCall(),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
              ),
            ),
          ),

          if (_remoteUid != null && _isConnected)
            Positioned(
              top: MediaQuery.of(context).padding.top + 32,
              left: 80,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4ECDC4).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4ECDC4),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Connected',
                      style: GoogleFonts.leagueSpartan(
                        color: const Color(0xFF4ECDC4),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildControlButton(
                  _isMicOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                  _isMicOn
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppColors.sos.withValues(alpha: 0.8),
                  onTap: () {
                    _agora.toggleMic();
                    setState(() => _isMicOn = _agora.isMicOn);
                  },
                ),
                const SizedBox(width: 20),
                _buildControlButton(
                  Icons.call_end_rounded,
                  AppColors.sos,
                  padding: 20,
                  iconSize: 32,
                  onTap: () => _endCall(),
                ),
                const SizedBox(width: 20),
                _buildControlButton(
                  _isCamOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                  _isCamOn
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppColors.sos.withValues(alpha: 0.8),
                  onTap: () {
                    _agora.toggleCamera();
                    setState(() => _isCamOn = _agora.isCamOn);
                  },
                ),
                const SizedBox(width: 20),
                _buildControlButton(
                  Icons.flip_camera_ios_rounded,
                  Colors.white.withValues(alpha: 0.2),
                  onTap: () => _agora.switchCamera(),
                ),
              ],
            ),
          ),

          // WAITING MESSAGE
          if (_remoteUid == null && !_isJoining && _isConnected)
            Positioned(
              bottom: 110,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Waiting for ${widget.remoteName} to join...',
                    style: GoogleFonts.leagueSpartan(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton(
    IconData icon,
    Color bgColor, {
    double padding = 16,
    double iconSize = 24,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: iconSize),
      ),
    );
  }
}
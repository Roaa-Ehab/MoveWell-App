import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

class AgoraService {
  static final AgoraService _instance = AgoraService._internal();
  factory AgoraService() => _instance;
  AgoraService._internal();

  static const String appId = 'de585668e3ba4ffd955428708e57c178';

  RtcEngine? _engine;
  bool _isInitialized = false;
  bool _isInChannel = false;
  bool _isMicOn = true;
  bool _isCamOn = true;
  int? _remoteUid;

  Function()? onJoinSuccess;
  Function(int)? onRemoteUserJoined;
  Function(int)? onRemoteUserLeft;
  Function()? onDisconnected;

  RtcEngine? get engine => _engine;
  bool get isInitialized => _isInitialized;
  bool get isInChannel => _isInChannel;
  bool get isMicOn => _isMicOn;
  bool get isCamOn => _isCamOn;
  int? get remoteUid => _remoteUid;

  Future<bool> requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();
    return cameraStatus.isGranted && micStatus.isGranted;
  }

  Future<void> initialize() async {
    if (_isInitialized && _engine != null) return;

    _engine = createAgoraRtcEngine();
    await _engine!.initialize(const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    _engine!.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        _isInChannel = true;
        onJoinSuccess?.call();
      },
      onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
        _remoteUid = remoteUid;
        onRemoteUserJoined?.call(remoteUid);
      },
      onUserOffline: (RtcConnection connection, int remoteUid,
          UserOfflineReasonType reason) {
        _remoteUid = null;
        onRemoteUserLeft?.call(remoteUid);
      },
      onConnectionLost: (RtcConnection connection) {
        onDisconnected?.call();
      },
    ));

    await _engine!.enableVideo();
    await _engine!.setupLocalVideo(const VideoCanvas(uid: 0));
    await _engine!.startPreview();

    _isMicOn = true;
    _isCamOn = true;
    _isInitialized = true;
  }

  Future<void> joinChannel(String channelName, int uid) async {
    if (!_isInitialized || _engine == null) {
      throw Exception('AgoraService not initialized');
    }

    _remoteUid = null;

    await _engine!.joinChannel(
      token: '',
      channelId: channelName,
      uid: uid,
      options: const ChannelMediaOptions(
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
  }

  Future<void> leaveChannel() async {
    if (_engine != null && _isInChannel) {
      await _engine!.leaveChannel();
      _isInChannel = false;
      _remoteUid = null;
    }
  }

  Future<void> toggleMic() async {
    _isMicOn = !_isMicOn;
    await _engine?.muteLocalAudioStream(!_isMicOn);
  }

  Future<void> toggleCamera() async {
    _isCamOn = !_isCamOn;
    await _engine?.muteLocalVideoStream(!_isCamOn);
  }

  Future<void> switchCamera() async {
    await _engine?.switchCamera();
  }

  Future<void> dispose() async {
    await leaveChannel();
    if (_engine != null) {
      await _engine!.stopPreview();
      await _engine!.release();
      _engine = null;
      _isInitialized = false;
    }

    onJoinSuccess = null;
    onRemoteUserJoined = null;
    onRemoteUserLeft = null;
    onDisconnected = null;
  }

  static String channelForAppointment(String appointmentId) {
    return 'movewell_$appointmentId';
  }
}
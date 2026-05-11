import 'package:dio/dio.dart';
import 'package:movewell/core/network/api_client.dart';

class VideoCallService {
  final Dio _dio = ApiClient().dio;

  Future<Map<String, dynamic>> createRoom(String sessionId) async {
    try {
      final response = await _dio.post('/video-call/create-room', data: {
        'sessionId': sessionId,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> joinRoom(String roomId) async {
    try {
      final response = await _dio.post('/video-call/join-room', data: {
        'roomId': roomId,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}
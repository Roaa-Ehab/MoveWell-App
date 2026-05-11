import 'package:dio/dio.dart';
import 'package:movewell/core/network/api_client.dart';

class ChatService {
  final Dio _dio = ApiClient().dio;

  Future<List<dynamic>> getConversations() async {
    try {
      final response = await _dio.get('/chat/conversations');
      return response.data;
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getMessages(String conversationId) async {
    try {
      final response = await _dio.get('/chat/messages/$conversationId');
      return response.data;
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> sendMessage(String conversationId, String message) async {
    try {
      final response = await _dio.post('/chat/messages', data: {
        'conversationId': conversationId,
        'message': message,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createConversation(String patientId) async {
    try {
      final response = await _dio.post('/chat/conversations', data: {
        'patientId': patientId,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}
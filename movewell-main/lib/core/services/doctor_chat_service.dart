import 'package:dio/dio.dart';
import 'package:movewell/core/network/api_client.dart';

class DoctorChatService {
  final Dio _dio = ApiClient().dio;

  Future<List<dynamic>> getAllDoctors() async {
    try {
      final response = await _dio.get('/users/doctors');
      return response.data ?? [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getDoctorById(String doctorId) async {
    try {
      final response = await _dio.get('/users/$doctorId');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getConversations() async {
    try {
      final response = await _dio.get('/chat/conversations');
      return response.data;
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> createConversation(String doctorId) async {
    try {
      final response = await _dio.post('/chat/conversations', data: {
        'doctorId': doctorId,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}
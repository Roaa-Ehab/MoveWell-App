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

  // For DOCTOR creating conversation with PATIENT
  Future<Map<String, dynamic>> createConversation(String patientId) async {
    try {
      final response = await _dio.post('/chat/conversations', data: {
        'patientId': patientId,  // ← Send patientId, not doctorId
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}
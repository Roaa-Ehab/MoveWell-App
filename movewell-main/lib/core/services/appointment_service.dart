import 'package:dio/dio.dart';
import 'package:movewell/core/network/api_client.dart';

class AppointmentService {
  final Dio _dio = ApiClient().dio;

  Future<List<dynamic>> getAppointments() async {
    try {
      final response = await _dio.get('/appointments');
      return response.data;
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> createAppointment(Map<String, dynamic> data) async {
    final response = await _dio.post('/appointments', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> updateAppointmentStatus(String id, String status) async {
    final response = await _dio.patch('/appointments/$id/status', data: {
      'status': status,
    });
    return response.data;
  }

  Future<List<dynamic>> getDoctors() async {
    try {
      final response = await _dio.get('/users/doctors');
      return response.data;
    } catch (e) {
      return [];
    }
  }
}
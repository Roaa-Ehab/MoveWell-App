import 'package:dio/dio.dart';
import 'package:movewell/core/network/api_client.dart';

class PatientService {
  final Dio _dio = ApiClient().dio;

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _dio.get('/patients/profile');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
  try {
    final response = await _dio.put('/patients/profile', data: data);
    return response.data;
  } catch (e) {
    rethrow;
  }
}

  Future<List<dynamic>> getExercises() async {
    try {
      final response = await _dio.get('/exercises');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getPlans() async {
    try {
      final response = await _dio.get('/plans/patient/me');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getTracking() async {
    try {
      final response = await _dio.get('/tracking/me');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> submitTracking(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/tracking', data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getSessions() async {
    try {
      final response = await _dio.get('/sessions/me');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createSession(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/sessions', data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getReports() async {
    try {
      final response = await _dio.get('/reports/patient/me');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> uploadFile(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      final response = await _dio.post('/patients/upload', data: formData);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getDoctors() async {
    try {
      final response = await _dio.get('/users/doctors');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}
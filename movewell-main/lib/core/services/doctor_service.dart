import 'package:dio/dio.dart';
import 'package:movewell/core/network/api_client.dart';

class DoctorService {
  final Dio _dio = ApiClient().dio;

  Future<List<dynamic>> getPatients() async {
    try {
      final response = await _dio.get('/patients');
      return response.data;
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getPatientById(String patientId) async {
    try {
      final response = await _dio.get('/patients/$patientId');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getSchedule() async {
    try {
      final response = await _dio.get('/appointments');
      return response.data;
    } catch (e) {
      return [];
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

  Future<Map<String, dynamic>> createPlan(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/plans', data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createReport(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/reports', data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updatePatientStatus(String patientId, String status, String diagnosis) async {
    try {
      final response = await _dio.patch('/patients/$patientId/status', data: {
        'status': status,
        'injuryType': diagnosis,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getClinicalNotes(String patientId) async {
    try {
      final response = await _dio.get('/clinical-notes/patient/$patientId');
      return response.data;
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> addClinicalNote(String patientId, String type, String content) async {
    try {
      final response = await _dio.post('/clinical-notes', data: {
        'patientId': patientId,
        'type': type,
        'content': content,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getPatientReports(String patientId) async {
    try {
      final response = await _dio.get('/reports/patient/$patientId');
      return response.data;
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getHomeVisits(String patientId) async {
    try {
      final response = await _dio.get('/home-visits/patient/$patientId');
      return response.data;
    } catch (e) {
      return [];
    }
  }

  Future<double> getPatientAdherence(String patientId) async {
    try {
      final response = await _dio.get('/tracking/summary/$patientId');
      final data = response.data;
      if (data != null && data['averageProgress'] != null) {
        return (data['averageProgress'] as num).toDouble() / 100;
      }
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  Future<Map<String, dynamic>> getPatientTrackingSummary(String patientId) async {
    try {
      final response = await _dio.get('/tracking/summary/$patientId');
      return response.data;
    } catch (e) {
      return {
        'totalEntries': 0,
        'averageProgress': 0,
        'initialProgress': 0,
        'currentProgress': 0,
        'progressImprovement': 0,
      };
    }
  }
}
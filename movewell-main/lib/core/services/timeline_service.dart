import 'package:dio/dio.dart';
import 'package:movewell/core/network/api_client.dart';

class TimelineService {
  final Dio _dio = ApiClient().dio;

  Future<List<dynamic>> getMedicalRecords() async {
    try {
      final response = await _dio.get('/timeline/records');
      return response.data;
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getReminders() async {
    try {
      final response = await _dio.get('/timeline/reminders');
      return response.data;
    } catch (e) {
      return [];
    }
  }
}
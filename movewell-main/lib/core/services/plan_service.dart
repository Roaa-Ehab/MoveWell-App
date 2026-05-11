import 'package:dio/dio.dart';
import 'package:movewell/core/network/api_client.dart';

class PlanService {
  final Dio _dio = ApiClient().dio;

  Future<List<dynamic>> getMyPlans() async {
    try {
      final response = await _dio.get('/plans/patient/me');
      return response.data;
    } catch (e) {
      return [];
    }
  }
}
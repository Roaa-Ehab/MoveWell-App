import 'package:dio/dio.dart';
import 'package:movewell/core/network/api_client.dart';

class AuthRepository {
  final Dio _dio = ApiClient().dio;

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: data,
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}
import 'package:dio/dio.dart';
import 'package:movewell/core/network/api_client.dart';
import 'package:file_picker/file_picker.dart';

class ReportService {
  
  final Dio _dio = ApiClient().dio;

  Future<List<dynamic>> getMyReports() async {
    try {
      final response = await _dio.get('/reports');
      return response.data;
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> uploadReport(PlatformFile file) async {
    String fileName = file.name;
    
    MultipartFile multipartFile;
    
    if (file.bytes != null) {
      multipartFile = MultipartFile.fromBytes(
        file.bytes!,
        filename: fileName,
      );
    } else if (file.path != null) {
      multipartFile = await MultipartFile.fromFile(
        file.path!,
        filename: fileName,
      );
    } else {
      throw Exception('Could not read file');
    }
    
    final formData = FormData.fromMap({
      'file': multipartFile,
      'title': fileName,
    });
    
    final response = await _dio.post(
      '/reports',
      data: formData,
      options: Options(
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      ),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getReportById(String reportId) async {
    try {
      final response = await _dio.get('/reports/$reportId');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteReport(String reportId) async {
    try {
      await _dio.delete('/reports/$reportId');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getReportsByPatient(String patientId) async {
    try {
      final response = await _dio.get('/reports/patient/$patientId');
      return response.data;
    } catch (e) {
      return [];
    }
  }
}
import 'package:flutter/material.dart';
import 'package:movewell/core/features/auth/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository = AuthRepository();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _userId;
  String? get userId => _userId;

  String _userRole = 'patient';
  String get userRole => _userRole;

  String _userName = '';
  String get userName => _userName;

  String _userEmail = '';
  String get userEmail => _userEmail;

  String? _userPhone;
  String? get userPhone => _userPhone;

  void setRole(String role) {
    _userRole = role;
    notifyListeners();
  }

  Future<void> updateUserInfo(String name, String email, String? phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setString('user_email', email);
    if (phone != null && phone.isNotEmpty) {
      await prefs.setString('user_phone', phone);
      _userPhone = phone;
    }
    _userName = name;
    _userEmail = email;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      final data = await _repository.login(email, password);
      final token = data['token'];
      final userId = data['_id'];
      final name = data['name'];
      final role = data['role'];
      
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        await prefs.setString('user_id', userId);
        await prefs.setString('user_name', name);
        await prefs.setString('user_email', email);
        await prefs.setString('user_role', role);
        
        _userId = userId;
        _userName = name;
        _userEmail = email;
        _userRole = role;
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false, error: _getErrorMessage(e));
      return false;
    }
  }

  Future<bool> register(Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      final requestData = {
        'name': data['name'],
        'email': data['email'],
        'password': data['password'],
        'role': _userRole,
      };
      
      if (_userRole == 'patient') {
        if (data.containsKey('phone')) requestData['phone'] = data['phone'];
        if (data.containsKey('age')) requestData['age'] = data['age'];
      }
      
      if (_userRole == 'doctor') {
        if (data.containsKey('license')) requestData['license'] = data['license'];
        if (data.containsKey('specialty')) requestData['specialty'] = data['specialty'];
        if (data.containsKey('clinic')) requestData['clinic'] = data['clinic'];
        if (data.containsKey('experience')) requestData['experience'] = data['experience'];
      }
      
      final responseData = await _repository.register(requestData);
      final token = responseData['token'];
      final userId = responseData['_id'];
      final name = responseData['name'];
      final role = responseData['role'];
      final email = data['email'];
      
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        await prefs.setString('user_id', userId);
        await prefs.setString('user_name', name);
        await prefs.setString('user_email', email);
        await prefs.setString('user_role', role);
        
        _userId = userId;
        _userName = name;
        _userEmail = email;
        _userRole = role;
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false, error: _getErrorMessage(e));
      return false;
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is DioException) {
      if (error.response != null && error.response!.data != null) {
        final data = error.response!.data;
        if (data is Map && data.containsKey('message')) {
          return data['message'];
        }
      }
      if (error.type == DioExceptionType.connectionTimeout) {
        return 'Connection timeout. Check your internet.';
      }
      if (error.type == DioExceptionType.connectionError) {
        return 'Cannot connect to server. Make sure backend is running on port 5000';
      }
    }
    return error.toString().replaceAll('Exception:', '');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_role');
    _userId = null;
    _userName = '';
    _userEmail = '';
    _userRole = 'patient';
    notifyListeners();
  }

  Future<String> getSavedRole() async {
    final prefs = await SharedPreferences.getInstance();
    _userRole = prefs.getString('user_role') ?? 'patient';
    _userId = prefs.getString('user_id');
    _userName = prefs.getString('user_name') ?? '';
    _userEmail = prefs.getString('user_email') ?? '';
    return _userRole;
  }

  Future<String?> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  void _setLoading(bool value, {String? error}) {
    _isLoading = value;
    _errorMessage = error;
    notifyListeners();
  }
}
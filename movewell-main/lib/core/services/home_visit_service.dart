import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class HomeVisitService {
  static const String _visitsKey = 'home_visits';
  static const String _addressKey = 'home_address';

  Future<List<Map<String, dynamic>>> getUpcomingVisits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? visitsJson = prefs.getString(_visitsKey);
      if (visitsJson != null) {
        List<dynamic> visits = json.decode(visitsJson);
        return visits.map((v) => Map<String, dynamic>.from(v)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> requestVisit(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    
    List<Map<String, dynamic>> visits = await getUpcomingVisits();
    
    final newVisit = {
      'providerType': data['providerType'],
      'date': data['date'],
      'time': data['time'],
      'reason': data['reason'],
      'status': 'Scheduled',
      'createdAt': DateTime.now().toIso8601String(),
    };
    
    visits.add(newVisit);
    
    await prefs.setString(_visitsKey, json.encode(visits));
    
    return {'success': true, 'message': 'Visit requested', 'visit': newVisit};
  }

  Future<void> cancelVisit(int index) async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> visits = await getUpcomingVisits();
    if (index < visits.length) {
      visits.removeAt(index);
      await prefs.setString(_visitsKey, json.encode(visits));
    }
  }

  Future<String> getAddress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_addressKey) ?? '123 MUST, Apt 4B, Cairo, Egypt';
  }

  Future<void> saveAddress(String address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_addressKey, address);
  }
}
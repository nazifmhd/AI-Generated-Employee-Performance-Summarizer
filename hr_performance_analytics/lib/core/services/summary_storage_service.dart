import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SummaryStorageService {
  static const _storageKey = 'employee_summaries';

  static Future<void> saveSummaries(List<Map<String, dynamic>> summaries) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = jsonEncode(summaries);
    await prefs.setString(_storageKey, jsonList);
  }

  static Future<List<Map<String, dynamic>>> loadSummaries() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null) return [];
    final List<dynamic> decoded = jsonDecode(jsonString);
    return decoded.cast<Map<String, dynamic>>();
  }

  static Future<void> clearSummaries() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StatisticsProvider with ChangeNotifier {
  int _analyzedCount = 0;
  int _generatedCount = 0;
  int _savedCount = 0;
  
  int get analyzedCount => _analyzedCount;
  int get generatedCount => _generatedCount;
  int get savedCount => _savedCount;
  
  // Load stats from SharedPreferences when the app starts
  Future<void> loadStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _analyzedCount = prefs.getInt('analyzed_count') ?? 0;
      _generatedCount = prefs.getInt('generated_count') ?? 0;
      _savedCount = prefs.getInt('saved_count') ?? 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading statistics: $e');
    }
  }
  
  // Save stats to SharedPreferences
  Future<void> _saveStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('analyzed_count', _analyzedCount);
      await prefs.setInt('generated_count', _generatedCount);
      await prefs.setInt('saved_count', _savedCount);
    } catch (e) {
      debugPrint('Error saving statistics: $e');
    }
  }
  
  // Increment the number of employees analyzed
  Future<void> incrementAnalyzedCount(int count) async {
    _analyzedCount += count;
    notifyListeners();
    await _saveStatistics();
  }
  
  // Increment the number of summaries generated
  Future<void> incrementGeneratedCount(int count) async {
    _generatedCount += count;
    notifyListeners();
    await _saveStatistics();
  }
  
  // Increment the number of summaries saved
  Future<void> incrementSavedCount(int count) async {
    _savedCount += count;
    notifyListeners();
    await _saveStatistics();
  }
  
  // Reset all statistics (for testing purposes)
  Future<void> resetStatistics() async {
    _analyzedCount = 0;
    _generatedCount = 0;
    _savedCount = 0;
    notifyListeners();
    await _saveStatistics();
  }
}
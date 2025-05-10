import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/employee_performance.dart';
import '../core/services/summary_storage_service.dart';
import '../core/services/mock_summary_service.dart';
import '../providers/statistics_provider.dart'; // Add this import

class SummaryProvider with ChangeNotifier {
  // Toggle this for development/production
  static const bool USE_MOCK_SERVICE = false;
  // Maximum number of employees to process in one request
  static const int BATCH_SIZE = 5;
  
  bool isLoading = false;
  List<Map<String, dynamic>> summaries = [];
  String errorMessage = '';
  double _progress = 0.0;
  final StatisticsProvider? statisticsProvider; // Add this

  double get progress => _progress;
  
  // Update constructor to take statisticsProvider
  SummaryProvider({this.statisticsProvider});

  /// Generate summaries by sending data to the backend
  Future<void> generateSummaries(List<EmployeePerformance> employees) async {
    isLoading = true;
    errorMessage = '';
    _progress = 0.0;
    summaries = [];
    notifyListeners();
    
    // Update statistics - employees analyzed
    statisticsProvider?.incrementAnalyzedCount(employees.length);
    
    // Skip API call if using mock service
    if (USE_MOCK_SERVICE) {
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
      summaries = MockSummaryService.generateMockSummaries(employees);
      _progress = 1.0;
      isLoading = false;
      notifyListeners();
      
      // Update statistics - summaries generated
      statisticsProvider?.incrementGeneratedCount(summaries.length);
      
      await saveToLocalHistory();
      return;
    }

    try {
      // Process employees in batches to avoid timeouts
      final int totalEmployees = employees.length;
      final int numberOfBatches = (totalEmployees / BATCH_SIZE).ceil();
      
      for (int i = 0; i < numberOfBatches; i++) {
        int startIndex = i * BATCH_SIZE;
        int endIndex = (startIndex + BATCH_SIZE < totalEmployees) 
            ? startIndex + BATCH_SIZE 
            : totalEmployees;
        
        List<EmployeePerformance> batch = employees.sublist(startIndex, endIndex);
        
        // Make sure the URL is exactly the same as the one we tested
        final url = Uri.parse('http://192.168.8.139:8000/generate-summaries');
        
        // Create the request body
        final data = {
          "employees": batch.map((e) => {
            "name": e.name,
            "id": e.id,
            "department": e.department,
            "month": e.month,
            "tasksCompleted": e.tasksCompleted,
            "goalsMet": e.goalsMet,
            "peerFeedback": e.peerFeedback,
            "managerComments": e.managerComments,
          }).toList()
        };
        
        debugPrint('Sending batch ${i+1}/${numberOfBatches}');
        
        final response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(data),
        ).timeout(const Duration(seconds: 60));
        
        if (response.statusCode >= 400) {
          debugPrint('Server error: ${response.statusCode}, Body: ${response.body}');
          throw Exception('Server error ${response.statusCode}: ${response.body}');
        }
        
        final decoded = jsonDecode(response.body);
        debugPrint('Response decoded successfully: ${decoded["summaries"].length} summaries');
        
        // Inspect the first summary to verify fields
        if (decoded["summaries"].isNotEmpty) {
          debugPrint('First summary example: ${jsonEncode(decoded["summaries"][0])}');
        }
        
        summaries.addAll(List<Map<String, dynamic>>.from(decoded["summaries"]));
        
        // Update progress
        _progress = (i + 1) / numberOfBatches;
        notifyListeners();
      }
      
      // Update statistics - summaries generated
      statisticsProvider?.incrementGeneratedCount(summaries.length);
      
      // Clear any previous error message
      errorMessage = '';
    } catch (e) {
      debugPrint('Error generating summaries: $e');
      errorMessage = 'Connection to AI service failed. Using local summarization instead.';
      
      // Use mock service to generate summaries locally when backend is unavailable
      summaries = MockSummaryService.generateMockSummaries(employees);
      
      // Update statistics even for mock summaries
      statisticsProvider?.incrementGeneratedCount(summaries.length);
    } finally {
      isLoading = false;
      _progress = 1.0;
      notifyListeners();
      
      // Save to local history regardless of where summaries came from
      await saveToLocalHistory();
    }
  }

  /// Save summaries locally
  Future<void> saveToLocalHistory() async {
    await SummaryStorageService.saveSummaries(summaries);
    
    // Update statistics - summaries saved
    statisticsProvider?.incrementSavedCount(summaries.length);
  }

  /// Load summaries from local history
  Future<void> loadFromLocalHistory() async {
    summaries = await SummaryStorageService.loadSummaries();
    notifyListeners();
  }

  /// Clear locally saved summaries
  Future<void> clearLocalHistory() async {
    await SummaryStorageService.clearSummaries();
    summaries = [];
    notifyListeners();
  }
  
  /// Delete a specific summary by index
  Future<void> deleteSummary(int index) async {
    if (index >= 0 && index < summaries.length) {
      // Remove the summary at the specified index
      summaries.removeAt(index);
      
      // Update the local storage with the modified list
      await saveToLocalHistory();
      
      // Notify listeners about the change
      notifyListeners();
    } else {
      throw Exception('Invalid summary index for deletion');
    }
  }
}
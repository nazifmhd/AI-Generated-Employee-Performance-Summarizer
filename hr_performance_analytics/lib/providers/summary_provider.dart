import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/employee_performance.dart';
import '../core/services/summary_storage_service.dart';
import '../core/services/mock_summary_service.dart';
import '../core/services/firestore_service.dart';
import '../providers/statistics_provider.dart';
import '../providers/auth_provider.dart';

class SummaryProvider with ChangeNotifier {
  // Toggle this for development/production
  static const bool USE_MOCK_SERVICE = false;
  // Maximum number of employees to process in one request
  static const int BATCH_SIZE = 5;
  
  bool isLoading = false;
  List<Map<String, dynamic>> summaries = [];
  String errorMessage = '';
  double _progress = 0.0;
  final StatisticsProvider? statisticsProvider;

  double get progress => _progress;

  final FirestoreService _firestoreService = FirestoreService();
  final AuthProvider? authProvider;
  
  // Constructor
  SummaryProvider({this.statisticsProvider, this.authProvider});

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
    try {
      // Ensure all summaries are serializable before saving
      List<Map<String, dynamic>> serializableSummaries = summaries.map((summary) {
        // Convert any potential Timestamp objects in the summary
        return _convertToSerializable(summary);
      }).toList();
      
      await SummaryStorageService.saveSummaries(serializableSummaries);
      
      // Update statistics - summaries saved
      statisticsProvider?.incrementSavedCount(summaries.length);
    } catch (e) {
      debugPrint('Error saving summaries to local storage: $e');
    }
  }

  /// Load summaries from local history
  Future<void> loadFromLocalHistory() async {
    try {
      summaries = await SummaryStorageService.loadSummaries();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading summaries from local storage: $e');
      // Ensure summaries is at least an empty list rather than null
      summaries = [];
      notifyListeners();
    }
  }

  /// Clear locally saved summaries
  Future<void> clearLocalHistory() async {
    await SummaryStorageService.clearSummaries();
    summaries = [];
    notifyListeners();
  }

  /// Save to Firestore (cloud sync)
  Future<void> syncToCloud() async {
    if (authProvider != null && authProvider!.isLoggedIn) {
      try {
        // Add IDs to summaries that don't have one
        for (var summary in summaries) {
          if (!summary.containsKey('id')) {
            summary['id'] = DateTime.now().millisecondsSinceEpoch.toString() + '_${summary['name']}';
          }
        }
        
        // Convert dates to Firestore compatible format
        List<Map<String, dynamic>> firestoreSummaries = summaries.map((summary) {
          return _prepareForFirestore(summary);
        }).toList();
        
        await _firestoreService.saveSummariesToFirestore(firestoreSummaries);
        debugPrint('Summaries synced to cloud successfully');
      } catch (e) {
        debugPrint('Failed to sync summaries to cloud: $e');
        rethrow;
      }
    } else {
      debugPrint('Cannot sync to cloud - user not logged in');
      throw Exception('User not logged in. Please sign in to sync data.');
    }
  }
  
  /// Load summaries from Firestore
  Future<List<Map<String, dynamic>>> loadFromFirestore() async {
    if (authProvider != null && authProvider!.isLoggedIn) {
      try {
        isLoading = true;
        notifyListeners();
        
        // Get the raw Firestore data
        List<Map<String, dynamic>> firestoreSummaries = await _firestoreService.getSummariesFromFirestore();
        
        // Convert Timestamps to serializable format
        summaries = firestoreSummaries.map((summary) {
          return _convertToSerializable(summary);
        }).toList();
        
        // Also save to local storage for offline access
        await saveToLocalHistory();
        
        debugPrint('Loaded ${summaries.length} summaries from Firestore');
        return summaries;
      } catch (e) {
        debugPrint('Error loading from Firestore: $e');
        // Fall back to local storage
        await loadFromLocalHistory();
        return summaries;
      } finally {
        isLoading = false;
        notifyListeners();
      }
    } else {
      // If not logged in, just load from local storage
      await loadFromLocalHistory();
      return summaries;
    }
  }
  
  /// Delete a summary (both locally and from cloud if signed in)
  Future<void> deleteSummary(int index) async {
    if (index >= 0 && index < summaries.length) {
      final summary = summaries[index];
      
      // Remove from local list
      summaries.removeAt(index);
      
      // Update local storage
      await saveToLocalHistory();
      
      // Delete from Firestore if user is logged in and summary has an ID
      if (authProvider != null && authProvider!.isLoggedIn && summary['id'] != null) {
        try {
          await _firestoreService.deleteSummary(summary['id'].toString());
          debugPrint('Successfully deleted summary from Firestore: ${summary['id']}');
        } catch (e) {
          debugPrint('Error deleting from Firestore: $e');
          // Continue anyway since we've already updated local state
        }
      }
      
      notifyListeners();
    } else {
      throw Exception('Invalid summary index for deletion');
    }
  }
  
  // Helper Methods for Firestore/JSON conversion
  
  /// Convert a map with potential Timestamp objects to a fully serializable map
  Map<String, dynamic> _convertToSerializable(Map<String, dynamic> doc) {
    final result = <String, dynamic>{};
    
    for (var entry in doc.entries) {
      if (entry.value is Timestamp) {
        // Convert Timestamp to ISO string
        result[entry.key] = (entry.value as Timestamp).toDate().toIso8601String();
      } else if (entry.value is DateTime) {
        // Convert DateTime to ISO string
        result[entry.key] = (entry.value as DateTime).toIso8601String();
      } else if (entry.value is Map) {
        // Recursively convert nested maps
        result[entry.key] = _convertToSerializable(entry.value as Map<String, dynamic>);
      } else if (entry.value is List) {
        // Handle lists
        result[entry.key] = _convertListToSerializable(entry.value as List);
      } else {
        // Keep other types as is
        result[entry.key] = entry.value;
      }
    }
    
    return result;
  }
  
  /// Convert list elements to serializable format
  List _convertListToSerializable(List list) {
    return list.map((item) {
      if (item is Timestamp) {
        return item.toDate().toIso8601String();
      } else if (item is DateTime) {
        return item.toIso8601String();
      } else if (item is Map) {
        return _convertToSerializable(item as Map<String, dynamic>);
      } else if (item is List) {
        return _convertListToSerializable(item);
      }
      return item;
    }).toList();
  }
  
  /// Convert a map with string dates to Firestore format with Timestamps
  Map<String, dynamic> _prepareForFirestore(Map<String, dynamic> data) {
    final result = <String, dynamic>{};
    
    for (var entry in data.entries) {
      if (entry.value is DateTime) {
        // Convert DateTime directly to Timestamp
        result[entry.key] = Timestamp.fromDate(entry.value as DateTime);
      } else if (entry.value is String && 
                _isIsoDateString(entry.value as String)) {
        // Convert ISO date strings to Timestamp
        try {
          result[entry.key] = Timestamp.fromDate(DateTime.parse(entry.value as String));
        } catch (e) {
          // If parsing fails, keep the original value
          result[entry.key] = entry.value;
        }
      } else if (entry.value is Map) {
        // Recursively convert nested maps
        result[entry.key] = _prepareForFirestore(entry.value as Map<String, dynamic>);
      } else if (entry.value is List) {
        // Handle lists
        result[entry.key] = _prepareListForFirestore(entry.value as List);
      } else {
        // Keep other types as is
        result[entry.key] = entry.value;
      }
    }
    
    return result;
  }
  
  /// Convert list elements to Firestore format
  List _prepareListForFirestore(List list) {
    return list.map((item) {
      if (item is DateTime) {
        return Timestamp.fromDate(item);
      } else if (item is String && _isIsoDateString(item)) {
        try {
          return Timestamp.fromDate(DateTime.parse(item));
        } catch (e) {
          return item;
        }
      } else if (item is Map) {
        return _prepareForFirestore(item as Map<String, dynamic>);
      } else if (item is List) {
        return _prepareListForFirestore(item);
      }
      return item;
    }).toList();
  }
  
  /// Check if a string is in ISO date format
  bool _isIsoDateString(String value) {
    return RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}').hasMatch(value);
  }
}
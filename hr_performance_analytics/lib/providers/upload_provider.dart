import 'dart:io';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/employee_performance.dart';
import '../core/services/csv_service.dart';

class UploadProvider with ChangeNotifier {
  List<EmployeePerformance> _parsedData = [];
  List<List<dynamic>> _rawData = [];
  bool _isDataLoaded = false;
  String _fileName = '';

  List<EmployeePerformance> get parsedData => _parsedData;
  List<List<dynamic>> get rawData => _rawData;
  bool get isDataLoaded => _isDataLoaded;
  String get fileName => _fileName;

  Future<void> pickAndParseCsv() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true, // Get the file data directly
      );

      if (result != null && result.files.isNotEmpty && result.files.single.bytes != null) {
        // Get file bytes and name
        final Uint8List bytes = result.files.single.bytes!;
        _fileName = result.files.single.name;
        
        // Convert bytes to string and parse CSV
        final String csvString = String.fromCharCodes(bytes);
        
        // Parse raw CSV data using the service
        final fields = CsvService.parseCsv(csvString);
        _rawData = fields;
        
        // Skip header row and map to model objects
        if (fields.length > 1) {
          _parsedData = fields.skip(1).map((row) => EmployeePerformance.fromCsv(row)).toList();
          _isDataLoaded = true;
        } else {
          _isDataLoaded = false;
        }
      }
    } catch (e) {
      _isDataLoaded = false;
      debugPrint('Error in pickAndParseCsv: $e');
    }
    
    notifyListeners();
  }

  void updateParsedData(List<List<dynamic>> data) {
    _rawData = data;
    
    if (data.length > 1) {
      try {
        _parsedData = data.skip(1).map((row) => EmployeePerformance.fromCsv(row)).toList();
        _isDataLoaded = true;
      } catch (e) {
        _isDataLoaded = false;
        debugPrint('Error in updateParsedData: $e');
      }
    } else {
      _isDataLoaded = false;
    }
    
    notifyListeners();
  }

  void clearData() {
    _parsedData = [];
    _rawData = [];
    _isDataLoaded = false;
    _fileName = '';
    notifyListeners();
  }
}
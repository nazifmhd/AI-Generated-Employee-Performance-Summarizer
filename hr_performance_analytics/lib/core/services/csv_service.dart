import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';

class CsvService {
  // Method to parse CSV content into a List of List
  static List<List<dynamic>> parseCsv(String fileContent) {
    try {
      // Use a more error-tolerant CSV converter with better options
      return const CsvToListConverter(
        shouldParseNumbers: false, // Keep everything as strings to avoid parsing errors
        fieldDelimiter: ',', // Explicitly specify delimiter
        eol: '\n', // Set end of line character
      ).convert(fileContent);
    } catch (e) {
      debugPrint('CSV parsing error: $e');
      throw Exception('Error parsing CSV: ${e.toString()}');
    }
  }
  
  // Add a method to validate the CSV structure
  static bool validateCsvStructure(List<dynamic> headers, List<String> requiredHeaders) {
    if (headers.isEmpty) {
      return false;
    }
    
    // Convert headers to lowercase for case-insensitive comparison
    final lowerCaseHeaders = headers.map((h) => h.toString().toLowerCase().trim()).toList();
    
    // Check if all required headers are present
    return requiredHeaders.every(
      (required) => lowerCaseHeaders.contains(required.toLowerCase())
    );
  }
}
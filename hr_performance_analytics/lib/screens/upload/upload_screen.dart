import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:provider/provider.dart';
import '../../../core/services/csv_service.dart';
import '../../../core/constants.dart';
import '../../../providers/upload_provider.dart';
import '../../../models/employee_performance.dart';
import '../../../providers/summary_provider.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  late List<List<dynamic>> _csvData;
  String _errorMessage = '';
  String _fileName = '';
  bool _isLoading = false;
  bool _fileUploaded = false;

  @override
  void initState() {
    super.initState();
    _csvData = [];
  }

  Future<void> _pickFile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Pick the file using file picker with better error handling
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true, // This ensures we get the file data directly
      );

      if (result != null &&
          result.files.isNotEmpty &&
          result.files.single.bytes != null) {
        // Use the bytes directly rather than file path
        final bytes = result.files.single.bytes!;
        final fileContent = String.fromCharCodes(bytes);

        setState(() {
          _fileName = result.files.single.name;
        });

        _parseCSV(fileContent);
      } else {
        setState(() {
          _errorMessage = 'No file selected or file could not be read.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error selecting file: ${e.toString()}';
        _isLoading = false;
      });
      debugPrint('File picker error: $e');
    }
  }

  void _parseCSV(String fileContent) {
    try {
      // Parse CSV data using the service
      List<List<dynamic>> data = CsvService.parseCsv(fileContent);

      if (data.isEmpty) {
        setState(() {
          _errorMessage = 'The CSV file is empty.';
          _isLoading = false;
        });
        return;
      }

      // Validate CSV structure
      if (!_validateCsvStructure(data[0])) {
        setState(() {
          _errorMessage =
              'Invalid CSV format. Please check the required columns.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _csvData = data;
        _isLoading = false;
        _fileUploaded = true;
      });

      // Use a safer approach to update the provider with WidgetsBinding
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          try {
            // Get provider without listening (to avoid rebuild cycles)
            final provider = Provider.of<UploadProvider>(
              context,
              listen: false,
            );
            provider.updateParsedData(data);
          } catch (e) {
            debugPrint('Provider error: $e');
            // The UI will still work even if provider update fails
          }
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to parse CSV file: ${e.toString()}';
        _isLoading = false;
      });
      debugPrint('CSV parsing error: $e');
    }
  }

  bool _validateCsvStructure(List<dynamic> headers) {
    // Required column headers
    final requiredHeaders = [
      'Employee Name',
      'Employee ID',
      'Department',
      'Month',
      'Tasks Completed',
      'Goals Met (%)',
    ];

    // Convert headers to lowercase for case-insensitive comparison
    final lowerCaseHeaders =
        headers.map((h) => h.toString().toLowerCase().trim()).toList();

    // Check if all required headers are present
    return requiredHeaders.every(
      (required) => lowerCaseHeaders.contains(required.toLowerCase()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Performance Data'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Upload Employee Performance Data',
                style: AppConstants.headingStyle,
              ),
              const SizedBox(height: 15),
              const Text(
                'Import a CSV file containing employee performance metrics to generate AI summaries.',
                style: AppConstants.bodyTextStyle,
              ),

              const SizedBox(height: 30),

              // Upload Card
              _buildUploadCard(),

              const SizedBox(height: 20),

              // CSV Data Preview
              if (_csvData.isNotEmpty) ...[
                _buildDataPreviewCard(),

                const SizedBox(height: 25),

                // Next Step Button when data is loaded
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    // Replace the onPressed method with this implementation
                    onPressed:
                        _fileUploaded
                            ? () async {
                              // Get the providers
                              final uploadProvider =
                                  Provider.of<UploadProvider>(
                                    context,
                                    listen: false,
                                  );
                              final summaryProvider =
                                  Provider.of<SummaryProvider>(
                                    context,
                                    listen: false,
                                  );

                              // Show loading dialog
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const CircularProgressIndicator(),
                                        const SizedBox(height: 16),
                                        const Text('Generating summaries...'),
                                      ],
                                    ),
                                  );
                                },
                              );

                              // Determine which data source to use
                              List<EmployeePerformance> employeesToProcess = [];
                              if (uploadProvider.parsedData.isNotEmpty) {
                                employeesToProcess = uploadProvider.parsedData;
                              } else if (_csvData.length > 1) {
                                // Fallback to local data
                                for (int i = 1; i < _csvData.length; i++) {
                                  try {
                                    employeesToProcess.add(
                                      EmployeePerformance.fromCsv(_csvData[i]),
                                    );
                                  } catch (e) {
                                    debugPrint(
                                      'Error converting row to EmployeePerformance: $e',
                                    );
                                  }
                                }
                              }

                              // Generate summaries with error handling built into the provider
                              await summaryProvider.generateSummaries(
                                employeesToProcess,
                              );

                              // Close loading dialog and navigate regardless of source
                              if (Navigator.canPop(context))
                                Navigator.pop(context);
                              Navigator.pushNamed(context, '/summary');
                            }
                            : null,
                    child: const Text(
                      'Continue to Generate Summaries',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],

              // CSV requirements and format guide
              if (_csvData.isEmpty) _buildCsvFormatGuide(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Upload icon
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _fileUploaded ? Icons.check_circle : Icons.cloud_upload_rounded,
              size: 50,
              color: _fileUploaded ? Colors.green : AppConstants.primaryColor,
            ),
          ),

          const SizedBox(height: 20),

          // File name display
          if (_fileName.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      _fileUploaded
                          ? Colors.green.shade300
                          : Colors.grey.shade300,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description,
                    color:
                        _fileUploaded
                            ? Colors.green.shade700
                            : Colors.grey.shade700,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _fileName,
                      style: TextStyle(
                        color:
                            _fileUploaded
                                ? Colors.green.shade800
                                : Colors.grey.shade800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_fileUploaded)
                    const Icon(Icons.check_circle_outline, color: Colors.green),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Upload status message
          if (_fileUploaded) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'File uploaded successfully! ${_csvData.length - 1} rows found.',
                      style: const TextStyle(color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Upload button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: _isLoading ? null : _pickFile,
              icon:
                  _isLoading
                      ? SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : Icon(_fileUploaded ? Icons.refresh : Icons.upload_file),
              label: Text(_fileUploaded ? 'Change File' : 'Select CSV File'),
            ),
          ),

          // Error message
          if (_errorMessage.isNotEmpty) ...[
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDataPreviewCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.table_chart, color: AppConstants.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Data Preview',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${_csvData.length - 1} employees',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: _getDataColumns(),
              rows: _getDataRows(),
              columnSpacing: 30,
              headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Showing ${_getDataRows().length} of ${_csvData.length - 1} rows',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<DataColumn> _getDataColumns() {
    if (_csvData.isEmpty || _csvData[0].isEmpty) {
      return [const DataColumn(label: Text('No Data'))];
    }

    return _csvData[0]
        .map(
          (header) => DataColumn(
            label: Text(
              header.toString(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        )
        .toList();
  }

  List<DataRow> _getDataRows() {
    if (_csvData.isEmpty || _csvData.length < 2) {
      return [
        const DataRow(cells: [DataCell(Text('No Data'))]),
      ];
    }

    // Display only the first few rows to avoid overwhelming the UI
    final rowsToShow = _csvData.length > 6 ? 5 : _csvData.length - 1;

    return _csvData
        .sublist(1, 1 + rowsToShow) // Skip header row
        .map(
          (row) => DataRow(
            cells:
                row
                    .map(
                      (cell) => DataCell(
                        Text(cell.toString(), overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
          ),
        )
        .toList();
  }

  Widget _buildCsvFormatGuide() {
    return Container(
      margin: const EdgeInsets.only(top: 30),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                "CSV Format Requirements",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            "Your CSV file should include the following columns:",
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 10),
          _buildRequiredField("Employee Name"),
          _buildRequiredField("Employee ID"),
          _buildRequiredField("Department"),
          _buildRequiredField("Month"),
          _buildRequiredField("Tasks Completed"),
          _buildRequiredField("Goals Met (%)"),
          _buildOptionalField("Peer Feedback"),
          _buildOptionalField("Manager Comments"),
        ],
      ),
    );
  }

  Widget _buildRequiredField(String fieldName) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Text(fieldName, style: const TextStyle(fontSize: 14)),
          const Text(
            " (required)",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionalField(String fieldName) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(Icons.circle_outlined, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(fieldName, style: const TextStyle(fontSize: 14)),
          const Text(
            " (optional)",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

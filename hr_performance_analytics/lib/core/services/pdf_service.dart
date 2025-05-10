import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;

class PdfService {
  // Add this method to load custom fonts
  static Future<pw.Font> _loadFont() async {
    try {
      final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      return pw.Font.ttf(fontData);
    } catch (e) {
      // If font loading fails, fall back to the default font
      print('Failed to load Roboto font: $e');
      return pw.Font.helvetica();
    }
  }

  static Future<pw.ThemeData> _getTheme() async {
    final font = await _loadFont();
    return pw.ThemeData.withFont(
      base: font,
      bold: font,
      italic: font,
      boldItalic: font,
    );
  }

  static Future<void> exportSummariesAsPdf(List<Map<String, dynamic>> summaries) async {
    // Get theme with custom font
    final theme = await _getTheme();
    final pdf = pw.Document(theme: theme);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('Employee Performance Summary')),
          ...summaries.map((s) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('${s["name"]} (${s["department"]})', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text(s["summary"]),
                  pw.Divider(),
                ],
              )),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  /// Export a single summary as PDF
  static Future<void> exportSingleSummaryAsPdf(Map<String, dynamic> summary) async {
    // Get theme with custom font
    final theme = await _getTheme();
    final pdf = pw.Document(theme: theme);
    
    // Format the date for the filename
    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd').format(now);
    final employeeName = summary['name'].toString().replaceAll(' ', '_');

    // Create a PDF document
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 20),
          child: pw.Text(
            'Generated on ${DateFormat('MMMM d, yyyy').format(now)}',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey700,
            ),
          ),
        ),
        build: (pw.Context context) => [
          // Header with logo and title
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'PERFORMANCE SUMMARY',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 24,
                    color: PdfColors.indigo700,
                  ),
                ),
                pw.Container(
                  height: 50,
                  width: 50,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.indigo50,
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    summary['name'].toString()[0].toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.indigo700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Rest of your PDF generation code remains the same
          pw.SizedBox(height: 20),
          
          // Employee information section
          pw.Container(
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Employee Name',
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.Text(
                          summary['name'] ?? 'N/A',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Employee ID',
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.Text(
                          summary['id'] ?? 'N/A',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 15),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Department',
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.Text(
                          summary['department'] ?? 'N/A',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Month',
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.Text(
                          summary['month'] ?? 'N/A',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Rest of your existing code...
          pw.SizedBox(height: 20),
          
          // Performance metrics
          pw.Container(
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildMetricItem(
                  'Tasks Completed', 
                  summary['tasksCompleted'] ?? 'N/A',
                ),
                _buildMetricItem(
                  'Goals Met', 
                  summary['goalsMet'] ?? 'N/A',
                ),
              ],
            ),
          ),
          
          pw.SizedBox(height: 30),
          
          // Performance summary
          pw.Container(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'PERFORMANCE SUMMARY',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.indigo700,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Divider(color: PdfColors.indigo200),
                pw.SizedBox(height: 10),
                pw.Text(
                  summary['summary'] ?? 'No summary available.',
                  style: const pw.TextStyle(
                    fontSize: 12,
                    lineSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          
          // Additional sections if data is available
          if (summary['peerFeedback'] != null && summary['peerFeedback'].toString().isNotEmpty) ...[
            pw.SizedBox(height: 20),
            pw.Text(
              'PEER FEEDBACK',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.indigo700,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Divider(color: PdfColors.indigo200),
            pw.SizedBox(height: 10),
            pw.Text(
              summary['peerFeedback'].toString(),
              style: const pw.TextStyle(
                fontSize: 12,
                lineSpacing: 1.5,
              ),
            ),
          ],
          
          if (summary['managerComments'] != null && summary['managerComments'].toString().isNotEmpty) ...[
            pw.SizedBox(height: 20),
            pw.Text(
              'MANAGER COMMENTS',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.indigo700,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Divider(color: PdfColors.indigo200),
            pw.SizedBox(height: 10),
            pw.Text(
              summary['managerComments'].toString(),
              style: const pw.TextStyle(
                fontSize: 12,
                lineSpacing: 1.5,
              ),
            ),
          ],
        ],
      ),
    );

    // Show print dialog to save or print the PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${employeeName}_Performance_Summary_${formattedDate}.pdf',
    );
  }
  
  // Helper method to build metric item
  static pw.Widget _buildMetricItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.indigo900,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 12,
            color: PdfColors.grey700,
          ),
        ),
      ],
    );
  }
}
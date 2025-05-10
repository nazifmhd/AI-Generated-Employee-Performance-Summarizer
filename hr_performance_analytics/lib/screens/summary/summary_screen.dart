import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../providers/summary_provider.dart';
import '../../core/services/pdf_service.dart';
import '../../core/constants.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, double> _departmentAverages = {};
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateDepartmentAverages();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
    // In the _calculateDepartmentAverages method
  void _calculateDepartmentAverages() {
    final summaryProvider = Provider.of<SummaryProvider>(context, listen: false);
    
    // Debug: Print the entire summaries list
    debugPrint('Full summaries data: ${jsonEncode(summaryProvider.summaries)}');
    
    // Reset department data
    Map<String, List<double>> deptData = {};
    
    // Debug the summaries
    debugPrint('Number of summaries: ${summaryProvider.summaries.length}');
    
    for (var summary in summaryProvider.summaries) {
      // Debug each summary
      debugPrint('Processing summary: ${summary["name"]} - ${summary["department"]}');
      
      // Check if required fields exist
      if (!summary.containsKey("department") || !summary.containsKey("goalsMet")) {
        debugPrint('ERROR: Missing required fields in summary: $summary');
        continue;
      }
      
      final dept = summary["department"] as String;
      final goalString = summary["goalsMet"] as String? ?? "0%";
      
      // Debug the goalString
      debugPrint('Goals string: $goalString');
      
      // Handle percentage format properly
      final goals = double.tryParse(goalString.replaceAll('%', '')) ?? 0;
      debugPrint('Parsed goals value: $goals');
      
      deptData.putIfAbsent(dept, () => []).add(goals);
    }
    
    // Calculate averages
    Map<String, double> averages = {};
    deptData.forEach((dept, values) {
      if (values.isNotEmpty) {
        final avg = values.reduce((a, b) => a + b) / values.length;
        averages[dept] = avg;
        debugPrint('Department: $dept, Average: $avg');
      }
    });
    
    setState(() {
      _departmentAverages = averages;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _calculateDepartmentAverages();
  }

  @override
  void didUpdateWidget(covariant SummaryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateDepartmentAverages();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Performance Summaries"),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Summaries"),
            Tab(text: "Analytics"),
          ],
          labelColor: AppConstants.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppConstants.primaryColor,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_alt),
            tooltip: "Export All",
            onPressed: _exportAllSummaries,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: "Save Summaries",
            onPressed: _saveSummaries,
          ),
        ],
      ),
      body: Consumer<SummaryProvider>(
        builder: (context, summaryProvider, child) {
          if (summaryProvider.isLoading) {
            return _buildLoadingState();
          }
          
          if (summaryProvider.summaries.isEmpty) {
            return _buildEmptyState();
          }
          
          return TabBarView(
            controller: _tabController,
            children: [
              _buildSummariesTab(summaryProvider),
              _buildAnalyticsTab(summaryProvider),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            "Generating AI Summaries...",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "This may take a few moments",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.summarize_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 20),
          Text(
            "No Summaries Generated",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Upload employee data first to generate AI summaries",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            icon: const Icon(Icons.upload_file),
            label: const Text("Upload Data"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/upload');
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummariesTab(SummaryProvider provider) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header with summary info
        _buildSummaryHeader(provider.summaries.length),
        
        // List of summaries
        ...provider.summaries.map((summary) => _buildSummaryCard(summary)),
      ],
    );
  }
  
  Widget _buildSummaryHeader(int count) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppConstants.primaryColor.withOpacity(0.2),
                child: Icon(
                  Icons.summarize,
                  color: AppConstants.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "AI-Generated Performance Summaries",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    Text(
                      "$count ${count == 1 ? 'summary' : 'summaries'} generated",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            "These AI-generated summaries provide concise evaluations of employee performance based on the data you provided. Review and edit as needed before sharing with your team.",
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummaryCard(Map<String, dynamic> summary) {
    final goalsMet = summary["goalsMet"] as String? ?? "0%";
    final goalsValue = double.tryParse(goalsMet.replaceAll('%', '')) ?? 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: _getDepartmentColor(summary["department"] as String),
                  child: Text(
                    (summary["name"] as String).isNotEmpty 
                        ? (summary["name"] as String)[0].toUpperCase() 
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary["name"] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "${summary["department"]} · ${summary["month"]}",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.task_alt,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Tasks: ${summary["tasksCompleted"] ?? 'N/A'}",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.trending_up,
                            size: 16,
                            color: _getGoalColor(goalsValue),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Goals: $goalsMet",
                            style: TextStyle(
                              fontSize: 13,
                              color: _getGoalColor(goalsValue),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(),
            ),
            Text(
              summary["summary"] as String,
              style: const TextStyle(
                height: 1.5,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.edit_note, size: 18),
                  label: const Text("Edit"),
                  onPressed: () => _editSummary(summary),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.picture_as_pdf, size: 18),
                  label: const Text("PDF"),
                  onPressed: () => _exportSinglePdf(summary),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text("Share"),
                  onPressed: () => _shareSummary(summary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAnalyticsTab(SummaryProvider provider) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Goals Achievement by Department",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Average percentage of goals met per department",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 250,
                  child: _departmentAverages.isEmpty
                      ? Center(child: Text("No data available", style: TextStyle(color: Colors.grey.shade500)))
                      : _DepartmentBarChart(departmentAverages: _departmentAverages),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildPerformanceByMonthCard(provider),
        const SizedBox(height: 20),
        _buildTaskDistributionCard(provider),
        const SizedBox(height: 20),
        _buildFeedbackAnalysisCard(provider),
        const SizedBox(height: 20),
        _buildPerfomanceBreakdownCard(provider),
      ],
    );
  }

  // New chart: Performance by Month
  Widget _buildPerformanceByMonthCard(SummaryProvider provider) {
    // Process data for monthly performance
    Map<String, List<double>> monthlyData = {};
    for (var summary in provider.summaries) {
      final month = summary["month"] as String? ?? "Unknown";
      final goalString = summary["goalsMet"] as String? ?? "0%";
      final goals = double.tryParse(goalString.replaceAll('%', '')) ?? 0;
      monthlyData.putIfAbsent(month, () => []).add(goals);
    }
    
    // Calculate averages by month
    Map<String, double> monthlyAverages = {};
    monthlyData.forEach((month, values) {
      if (values.isNotEmpty) {
        final avg = values.reduce((a, b) => a + b) / values.length;
        monthlyAverages[month] = avg;
      }
    });

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Performance Trends by Month",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Average goals achieved by month",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: monthlyAverages.isEmpty
                  ? Center(child: Text("No data available", style: TextStyle(color: Colors.grey.shade500)))
                  : _MonthlyPerformanceChart(monthlyAverages: monthlyAverages),
            ),
          ],
        ),
      ),
    );
  }

  // New chart: Task Distribution
  Widget _buildTaskDistributionCard(SummaryProvider provider) {
    // Calculate task distribution across departments
    Map<String, List<int>> departmentTasks = {};
    for (var summary in provider.summaries) {
      final dept = summary["department"] as String? ?? "Unknown";
      final tasksStr = summary["tasksCompleted"] as String? ?? "0";
      final tasks = int.tryParse(tasksStr) ?? 0;
      departmentTasks.putIfAbsent(dept, () => []).add(tasks);
    }
    
    // Calculate average tasks per department
    Map<String, double> taskAverages = {};
    departmentTasks.forEach((dept, tasks) {
      if (tasks.isNotEmpty) {
        final avg = tasks.reduce((a, b) => a + b) / tasks.length;
        taskAverages[dept] = avg;
      }
    });

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Tasks Completed by Department",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Average number of tasks completed per department",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: taskAverages.isEmpty
                  ? Center(child: Text("No data available", style: TextStyle(color: Colors.grey.shade500)))
                  : _TaskDistributionChart(taskAverages: taskAverages),
            ),
          ],
        ),
      ),
    );
  }

  // New chart: Feedback Analysis
  Widget _buildFeedbackAnalysisCard(SummaryProvider provider) {
    // Count different feedback types
    Map<String, int> feedbackCounts = {};
    int totalWithFeedback = 0;
    
    for (var summary in provider.summaries) {
      final feedback = summary["peerFeedback"] as String? ?? "";
      if (feedback.isNotEmpty) {
        feedbackCounts[feedback] = (feedbackCounts[feedback] ?? 0) + 1;
        totalWithFeedback++;
      }
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Peer Feedback Analysis",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Distribution of different types of peer feedback",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: feedbackCounts.isEmpty
                  ? Center(child: Text("No feedback data available", style: TextStyle(color: Colors.grey.shade500)))
                  : _FeedbackPieChart(feedbackData: feedbackCounts, totalCount: totalWithFeedback),
            ),
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: feedbackCounts.entries.map((entry) {
                final Color color = _getFeedbackColor(entry.key);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        entry.key,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const Spacer(),
                      Text(
                        '${entry.value} (${(entry.value / totalWithFeedback * 100).toStringAsFixed(1)}%)',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getFeedbackColor(String feedback) {
    final Map<String, Color> feedbackColors = {
      'Great team player': Colors.green,
      'Excellent communicator': Colors.blue,
      'Needs improvement': Colors.orange,
    };
    
    return feedbackColors[feedback] ?? 
      Colors.primaries[feedback.hashCode % Colors.primaries.length];
  }
  
  Widget _buildPerfomanceBreakdownCard(SummaryProvider provider) {
    // Count employees in different performance brackets
    int outstanding = 0;
    int good = 0;
    int average = 0;
    int needsImprovement = 0;
    
    for (var summary in provider.summaries) {
      final goalString = summary["goalsMet"] as String? ?? "0%";
      final goals = double.tryParse(goalString.replaceAll('%', '')) ?? 0;
      
      if (goals >= 90) {
        outstanding++;
      } else if (goals >= 75) {
        good++;
      } else if (goals >= 60) {
        average++;
      } else {
        needsImprovement++;
      }
    }
    
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Performance Breakdown",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildPerformanceRow(
              label: "Outstanding (90-100%)",
              count: outstanding,
              total: provider.summaries.length,
              color: Colors.green,
            ),
            _buildPerformanceRow(
              label: "Good (75-89%)",
              count: good,
              total: provider.summaries.length,
              color: Colors.blue,
            ),
            _buildPerformanceRow(
              label: "Average (60-74%)",
              count: average,
              total: provider.summaries.length,
              color: Colors.amber,
            ),
            _buildPerformanceRow(
              label: "Needs Improvement (<60%)",
              count: needsImprovement,
              total: provider.summaries.length,
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPerformanceRow({
    required String label,
    required int count,
    required int total,
    required Color color,
  }) {
    final percentage = total > 0 ? (count / total * 100) : 0;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                "$count ${count == 1 ? 'employee' : 'employees'} (${percentage.toStringAsFixed(1)}%)",
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: color.withOpacity(0.1),
              color: color,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getDepartmentColor(String department) {
    final Map<String, Color> departmentColors = {
      'Engineering': Colors.blue,
      'Marketing': Colors.purple,
      'Sales': Colors.orange,
      'HR': Colors.teal,
      'Finance': Colors.green,
      'Product': Colors.indigo,
    };
    
    return departmentColors[department] ?? Colors.grey.shade700;
  }
  
  Color _getGoalColor(double goalValue) {
    if (goalValue >= 90) return Colors.green.shade700;
    if (goalValue >= 75) return Colors.blue.shade700;
    if (goalValue >= 60) return Colors.amber.shade700;
    return Colors.red.shade700;
  }
  
  void _editSummary(Map<String, dynamic> summary) {
    // This would be implemented with a TextEditingController and a form
    // Show a dialog or navigate to an edit screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Edit feature not implemented yet")),
    );
  }
  
  void _exportSinglePdf(Map<String, dynamic> summary) {
    try {
      PdfService.exportSingleSummaryAsPdf(summary);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("PDF exported successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error exporting PDF: ${e.toString()}")),
      );
    }
  }
  
  void _exportAllSummaries() {
    try {
      final summaryProvider = Provider.of<SummaryProvider>(context, listen: false);
      PdfService.exportSummariesAsPdf(summaryProvider.summaries);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All summaries exported to PDF")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error exporting PDF: ${e.toString()}")),
      );
    }
  }
  
  void _saveSummaries() {
    try {
      final summaryProvider = Provider.of<SummaryProvider>(context, listen: false);
      summaryProvider.saveToLocalHistory();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Summaries saved successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving summaries: ${e.toString()}")),
      );
    }
  }
  
  void _shareSummary(Map<String, dynamic> summary) {
    // This would use a share package
    // For now just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality not implemented yet')),
    );
  }
}

class _DepartmentBarChart extends StatelessWidget {
  final Map<String, double> departmentAverages;
  
  const _DepartmentBarChart({required this.departmentAverages});
  
  @override
  Widget build(BuildContext context) {
    if (departmentAverages.isEmpty) {
      return const Center(child: Text("No data available"));
    }
    
    final sortedDepts = departmentAverages.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final barGroups = <BarChartGroupData>[];
    
    for (int i = 0; i < sortedDepts.length; i++) {
      final entry = sortedDepts[i];
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: entry.value,
              width: 22,
              color: _getBarColor(entry.value),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
          showingTooltipIndicators: [0],
        ),
      );
    }

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        alignment: BarChartAlignment.spaceAround,
        maxY: 100, // Goals are percentages
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value >= 0 && value < sortedDepts.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      sortedDepts[value.toInt()].key,
                      style: const TextStyle(
                        fontSize: 11,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35,
              getTitlesWidget: (value, meta) {
                if (value % 20 == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      '${value.toInt()}%',
                      style: const TextStyle(
                        fontSize: 11,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(
          show: false,
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipPadding: const EdgeInsets.all(8),
            tooltipMargin: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final dept = sortedDepts[group.x].key;
              final value = rod.toY.toStringAsFixed(1);
              return BarTooltipItem(
                '$dept\n$value%',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
  
  Color _getBarColor(double value) {
    if (value >= 90) return Colors.green;
    if (value >= 75) return Colors.blue;
    if (value >= 60) return Colors.amber;
    return Colors.redAccent;
  }
}

// New chart classes for the added visualizations

class _MonthlyPerformanceChart extends StatelessWidget {
  final Map<String, double> monthlyAverages;
  
  const _MonthlyPerformanceChart({required this.monthlyAverages});
  
  @override
  Widget build(BuildContext context) {
    final months = ["January", "February", "March", "April"];
    final monthsWithData = months.where((m) => monthlyAverages.containsKey(m)).toList();
    
    final spots = <FlSpot>[];
    for (int i = 0; i < monthsWithData.length; i++) {
      final month = monthsWithData[i];
      if (monthlyAverages.containsKey(month)) {
        spots.add(FlSpot(i.toDouble(), monthlyAverages[month]!));
      }
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value >= 0 && value < monthsWithData.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      monthsWithData[value.toInt()],
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35,
              getTitlesWidget: (value, meta) {
                if (value % 20 == 0) {
                  return Text(
                    '${value.toInt()}%',
                    style: const TextStyle(fontSize: 11),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: false,
        ),
        minX: 0,
        maxX: monthsWithData.length - 1.0,
        minY: 0,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskDistributionChart extends StatelessWidget {
  final Map<String, double> taskAverages;
  
  const _TaskDistributionChart({required this.taskAverages});
  
  @override
  Widget build(BuildContext context) {
    if (taskAverages.isEmpty) {
      return const Center(child: Text("No data available"));
    }
    
    final sortedDepts = taskAverages.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final barGroups = <BarChartGroupData>[];
    
    for (int i = 0; i < sortedDepts.length; i++) {
      final entry = sortedDepts[i];
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: entry.value,
              width: 22,
              color: AppConstants.primaryColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
          showingTooltipIndicators: [0],
        ),
      );
    }

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        alignment: BarChartAlignment.spaceAround,
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value >= 0 && value < sortedDepts.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      sortedDepts[value.toInt()].key,
                      style: const TextStyle(
                        fontSize: 11,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35,
              getTitlesWidget: (value, meta) {
                if (value % 5 == 0) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 11),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 5,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(
          show: false,
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipPadding: const EdgeInsets.all(8),
            tooltipMargin: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final dept = sortedDepts[group.x].key;
              final value = rod.toY.toStringAsFixed(1);
              return BarTooltipItem(
                '$dept\n$value tasks',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FeedbackPieChart extends StatelessWidget {
  final Map<String, int> feedbackData;
  final int totalCount;
  
  const _FeedbackPieChart({required this.feedbackData, required this.totalCount});
  
  @override
  Widget build(BuildContext context) {
    if (feedbackData.isEmpty) {
      return const Center(child: Text("No feedback data available"));
    }

    // Define colors for feedback types
    final Map<String, Color> feedbackColors = {
      'Great team player': Colors.green,
      'Excellent communicator': Colors.blue,
      'Needs improvement': Colors.orange,
    };
    
    int i = 0;
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: feedbackData.entries.map((entry) {
          final color = feedbackColors[entry.key] ?? 
            Colors.primaries[i++ % Colors.primaries.length];
          final percentage = (entry.value / totalCount * 100).toStringAsFixed(1);
          
          return PieChartSectionData(
            color: color,
            value: entry.value.toDouble(),
            title: '$percentage%',
            radius: 100,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
      ),
    );
  }
}
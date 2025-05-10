import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/summary_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants.dart';
import '../../core/services/pdf_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isLoading = true;
  String _filterDepartment = "All";
  bool _isDisposed = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
  
  Future<void> _loadData() async {
    if (_isDisposed) return;
    
    // Only set loading state if the widget is still mounted
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    
    try {
      final summaryProvider = Provider.of<SummaryProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      if (authProvider.isLoggedIn) {
        // Try to load from Firestore first if user is logged in
        await summaryProvider.loadFromFirestore();
      } else {
        // Fall back to local storage
        await summaryProvider.loadFromLocalHistory();
      }
    } catch (e) {
      debugPrint('Error loading summaries: $e');
    } finally {
      // Check if widget is still mounted before updating state
      if (mounted && !_isDisposed) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance History'),
        centerTitle: true,
        actions: [
          // Add cloud sync icon for Firebase sync
          IconButton(
            icon: const Icon(Icons.cloud_sync),
            tooltip: 'Sync with Cloud',
            onPressed: () async {
              final provider = Provider.of<SummaryProvider>(context, listen: false);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              
              if (!authProvider.isLoggedIn) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please sign in to sync with cloud')),
                );
                return;
              }
              
              if (mounted) {
                setState(() {
                  _isLoading = true;
                });
              }
              
              try {
                await provider.syncToCloud();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Summaries synced to cloud successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error syncing: ${e.toString()}')),
                  );
                }
              } finally {
                if (mounted && !_isDisposed) {
                  setState(() {
                    _isLoading = false;
                  });
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading 
        ? _buildLoadingView()
        : Consumer<SummaryProvider>(
            builder: (context, summaryProvider, child) {
              final summaries = summaryProvider.summaries;
              
              if (summaries.isEmpty) {
                return _buildEmptyState();
              }
              
              // Get list of unique departments for filtering with null safety
              final departments = [
                "All", 
                ...{...summaries.map((s) => s['department'] as String? ?? 'Unknown')}
              ];
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header and filter section
                  _buildHeaderSection(summaries.length, departments),
                  
                  // Summaries list
                  Expanded(
                    child: _buildSummariesList(summaries),
                  ),
                ],
              );
            },
          ),
    );
  }
  
  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading saved summaries...'),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history,
              size: 80,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Saved Summaries',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Generate performance summaries first to see them here',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/upload');
            },
            icon: const Icon(Icons.add),
            label: const Text('Create New Summary'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeaderSection(int totalCount, List<String> departments) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: AppConstants.primaryColor),
              const SizedBox(width: 8),
              const Text(
                'Saved Performance Summaries',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$totalCount ${totalCount == 1 ? 'summary' : 'summaries'} saved',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          
          // Department filter
          if (departments.length > 2) // Only show filter if there's more than 1 department (+All)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: departments.map((dept) {
                  final isSelected = _filterDepartment == dept;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(dept),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (mounted && !_isDisposed) {
                          setState(() {
                            _filterDepartment = dept;
                          });
                        }
                      },
                      backgroundColor: Colors.grey.shade100,
                      selectedColor: AppConstants.primaryColor.withOpacity(0.2),
                      checkmarkColor: AppConstants.primaryColor,
                      labelStyle: TextStyle(
                        color: isSelected ? AppConstants.primaryColor : Colors.black,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildSummariesList(List<Map<String, dynamic>> allSummaries) {
    // Filter summaries by department if needed
    final summaries = _filterDepartment == "All"
        ? allSummaries
        : allSummaries.where((s) => (s['department'] as String? ?? 'Unknown') == _filterDepartment).toList();
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: summaries.length,
      itemBuilder: (context, index) {
        final summary = summaries[index];
        final dateCreated = summary['dateCreated'] ?? DateTime.now().toString();
        
        // Add null checks for all fields used in the UI
        final name = summary['name'] as String? ?? 'Unknown';
        final department = summary['department'] as String? ?? 'Unknown';
        final month = summary['month'] as String? ?? '';
        final goalsMet = summary['goalsMet'] as String? ?? '0%';
        final summaryText = summary['summary'] as String? ?? 'No summary available';
        
        // Get cloud sync status
        final isSynced = summary['syncedAt'] != null;
        
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
                // Header section with employee info
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _getAvatarColor(department),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            children: [
                              Text(
                                '$department · $month',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              if (isSynced) ...[
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.cloud_done,
                                  size: 14,
                                  color: Colors.green.shade700,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Chip(
                          label: Text(
                            goalsMet,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: _getGoalColor(goalsMet),
                          padding: EdgeInsets.zero,
                          labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        Text(
                          _formatDate(dateCreated),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const Divider(height: 24),
                
                // Summary content
                Text(
                  summaryText,
                  style: const TextStyle(height: 1.4),
                ),
                
                const SizedBox(height: 16),
                
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('Details'),
                      onPressed: () => _showSummaryDetails(context, summary),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blueGrey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.share, size: 16),
                      label: const Text('Share'),
                      onPressed: () {
                        // Share functionality
                        _shareSummary(summary);
                      },
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Delete'),
                      onPressed: () => _confirmDelete(context, summary, allSummaries.indexOf(summary)),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Color _getAvatarColor(String department) {
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
  
  Color _getGoalColor(String goalsMet) {
    final percent = double.tryParse(goalsMet.replaceAll('%', '')) ?? 0;
    
    if (percent >= 100) return Colors.green.shade100;
    if (percent >= 80) return Colors.lightGreen.shade100;
    if (percent >= 60) return Colors.amber.shade100;
    return Colors.red.shade100;
  }
  
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      return 'Date unknown';
    }
  }
  
  void _showSummaryDetails(BuildContext context, Map<String, dynamic> summary) {
    if (!mounted) return;
    
    // Add null checks for all displayed fields
    final name = summary['name'] as String? ?? 'Unknown';
    final department = summary['department'] as String? ?? 'Unknown';
    final month = summary['month'] as String? ?? '';
    final id = summary['id']?.toString() ?? 'N/A';
    final tasksCompleted = summary['tasksCompleted'] as String? ?? 'N/A';
    final goalsMet = summary['goalsMet'] as String? ?? '0%';
    final peerFeedback = summary['peerFeedback'] as String? ?? '';
    final managerComments = summary['managerComments'] as String? ?? '';
    final summaryText = summary['summary'] as String? ?? 'No summary available';
    final isSynced = summary['syncedAt'] != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    height: 5,
                    width: 40,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: _getAvatarColor(department),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: Colors.white, 
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Employee ID: $id',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSynced)
                      Tooltip(
                        message: 'Synced to cloud',
                        child: Icon(
                          Icons.cloud_done,
                          color: Colors.green.shade700,
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                const Divider(),
                
                _buildDetailRow('Department', department),
                _buildDetailRow('Month', month),
                _buildDetailRow('Tasks Completed', tasksCompleted),
                _buildDetailRow('Goals Met', goalsMet),
                
                const Divider(),
                const SizedBox(height: 10),
                
                const Text(
                  'Performance Summary',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  summaryText,
                  style: const TextStyle(height: 1.5),
                ),
                
                if (peerFeedback.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Peer Feedback',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    peerFeedback,
                    style: const TextStyle(height: 1.5),
                  ),
                ],
                
                if (managerComments.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Manager Comments',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    managerComments,
                    style: const TextStyle(height: 1.5),
                  ),
                ],
                
                const SizedBox(height: 40),
                
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _exportAsPdf(summary),
                        icon: const Icon(Icons.download),
                        label: const Text('Export as PDF'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: AppConstants.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Only show sync button if not already synced
                    if (!isSynced)
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, _) {
                          if (!authProvider.isLoggedIn) {
                            return const SizedBox.shrink();
                          }
                          
                          return ElevatedButton.icon(
                            onPressed: () async {
                              Navigator.pop(context);
                              final provider = Provider.of<SummaryProvider>(context, listen: false);
                              try {
                                await provider.syncToCloud();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Summary synced to cloud')),
                                  );
                                  // Reload data to update sync status
                                  _loadData();
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error syncing: ${e.toString()}')),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.cloud_upload),
                            label: const Text('Sync'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              backgroundColor: Colors.blueGrey,
                              foregroundColor: Colors.white,
                            ),
                          );
                        },
                      ),
                  ],
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _confirmDelete(BuildContext context, Map<String, dynamic> summary, int index) {
    if (!mounted) return;
    
    final name = summary['name'] as String? ?? 'Unknown';
    final isSynced = summary['syncedAt'] != null;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Summary?'),
        content: Text(
          'Are you sure you want to delete the performance summary for $name?' +
          (isSynced ? ' This will also remove it from cloud storage.' : '')
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSummary(index);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }
  
  void _deleteSummary(int index) {
    if (!mounted) return;
    
    try {
      final provider = Provider.of<SummaryProvider>(context, listen: false);
      provider.deleteSummary(index);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Summary deleted')),
      );
    } catch (e) {
      debugPrint('Error deleting summary: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error deleting summary')),
      );
    }
  }
  
  void _exportAsPdf(Map<String, dynamic> summary) {
    if (!mounted) return;
    
    try {
      PdfService.exportSingleSummaryAsPdf(summary);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Summary exported as PDF')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting PDF: ${e.toString()}')),
      );
    }
  }
  
  void _shareSummary(Map<String, dynamic> summary) {
    if (!mounted) return;
    
    // This would use a share package
    // For now just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality not implemented yet')),
    );
  }
}
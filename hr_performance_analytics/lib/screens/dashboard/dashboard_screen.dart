import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants.dart';
import '../../providers/statistics_provider.dart';
import '../../providers/auth_provider.dart'; // Import AuthProvider

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load the statistics when the dashboard is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StatisticsProvider>(context, listen: false).loadStatistics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HR Performance Analytics'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              await authProvider.signOut();
              // Navigation will be handled by the StreamBuilder in MyApp
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App logo or icon
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.assessment_rounded,
                    size: 60,
                    color: AppConstants.primaryColor,
                  ),
                ),
              ),

              // Welcome section
              const Text(
                "AI Performance Summary Assistant",
                style: AppConstants.headingStyle,
              ),
              const SizedBox(height: 10),
              const Text(
                "Automate your employee performance review drafts using AI-powered natural language summaries.",
                style: AppConstants.bodyTextStyle,
              ),

              // Quick stats card - now using Consumer to get the latest stats
              Consumer<StatisticsProvider>(
                builder:
                    (context, statsProvider, child) => _buildStatsCard(
                      analyzed: statsProvider.analyzedCount,
                      generated: statsProvider.generatedCount,
                      saved: statsProvider.savedCount,
                    ),
              ),

              const SizedBox(height: 20),
              const Text(
                "What would you like to do?",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 15),

              // Feature navigation buttons
              _buildNavButton(
                context,
                icon: Icons.upload_file,
                label: "Upload Performance Data",
                description: "Import CSV with employee performance metrics",
                routeName: "/upload",
              ),
              _buildNavButton(
                context,
                icon: Icons.smart_toy,
                label: "Generate Summary",
                description: "Create AI-powered performance summaries",
                routeName: "/summary",
              ),
              _buildNavButton(
                context,
                icon: Icons.history,
                label: "Past Summaries",
                description: "View and export previously generated reports",
                routeName: "/history",
              ),

              // Help section
              const SizedBox(height: 30),
              _buildHelpSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard({
    required int analyzed,
    required int generated,
    required int saved,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            title: "Analyzed",
            value: analyzed.toString(),
            icon: Icons.analytics,
          ),
          _buildStatItem(
            title: "Generated",
            value: generated.toString(),
            icon: Icons.description,
          ),
          _buildStatItem(
            title: "Saved",
            value: saved.toString(),
            icon: Icons.save,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppConstants.primaryColor, size: 28),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildNavButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String description,
    required String routeName,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        color: Colors.white,
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.pushNamed(context, routeName);
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppConstants.primaryColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        description,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppConstants.primaryColor,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHelpSection(BuildContext context) {
    return Container(
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
              Icon(Icons.help_outline, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                "How It Works",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildHelpStep(
            number: "1",
            text: "Upload a CSV file with employee performance data",
          ),
          _buildHelpStep(
            number: "2",
            text:
                "Our AI analyzes the data to generate natural language summaries",
          ),
          _buildHelpStep(
            number: "3",
            text: "Review, edit, and export the generated performance reports",
          ),
        ],
      ),
    );
  }

  Widget _buildHelpStep({required String number, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 10, top: 2),
            height: 20,
            width: 20,
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}

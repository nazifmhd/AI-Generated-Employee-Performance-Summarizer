import 'package:flutter/material.dart';
import 'package:hr_performance_analytics/app.dart';
import 'package:provider/provider.dart';
import 'providers/upload_provider.dart';
import 'providers/summary_provider.dart';
import 'providers/statistics_provider.dart'; // Add this import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        // Register StatisticsProvider first
        ChangeNotifierProvider(create: (_) => StatisticsProvider()),
        
        // Then provide SummaryProvider with access to StatisticsProvider
        ChangeNotifierProxyProvider<StatisticsProvider, SummaryProvider>(
          create: (context) => SummaryProvider(
            statisticsProvider: Provider.of<StatisticsProvider>(context, listen: false),
          ),
          update: (context, statsProvider, previous) => 
            previous ?? SummaryProvider(statisticsProvider: statsProvider),
        ),
        
        // Keep existing providers
        ChangeNotifierProvider(create: (_) => UploadProvider()),
      ],
      child: const MyApp(),
    ),
  );
}
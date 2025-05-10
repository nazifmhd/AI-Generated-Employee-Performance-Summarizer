import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hr_performance_analytics/app.dart';
import 'package:provider/provider.dart';
import 'providers/upload_provider.dart';
import 'providers/summary_provider.dart';
import 'providers/statistics_provider.dart';
import 'providers/auth_provider.dart';
import 'core/services/firebase_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with proper options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Firebase service
  await FirebaseService.initialize();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => StatisticsProvider()),
        ChangeNotifierProxyProvider2<StatisticsProvider, AuthProvider, SummaryProvider>(
          create: (context) => SummaryProvider(
            statisticsProvider: Provider.of<StatisticsProvider>(context, listen: false),
            authProvider: Provider.of<AuthProvider>(context, listen: false),
          ),
          update: (context, statsProvider, authProvider, previous) => 
            previous ?? SummaryProvider(
              statisticsProvider: statsProvider,
              authProvider: authProvider,
            ),
        ),
        ChangeNotifierProvider(create: (_) => UploadProvider()),
      ],
      child: const MyApp(),
    ),
  );
}
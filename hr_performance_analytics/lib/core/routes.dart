import 'package:flutter/material.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/upload/upload_screen.dart';
import '../screens/summary/summary_screen.dart';
import '../screens/history/history_screen.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => const DashboardScreen(),
  '/upload': (context) => const UploadScreen(),
  '/summary': (context) => const SummaryScreen(),
  '/history': (context) => const HistoryScreen(),
};

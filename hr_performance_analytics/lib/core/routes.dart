import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/summary/summary_screen.dart';
import '../screens/upload/upload_screen.dart';
import '../screens/history/history_screen.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

// Wrap this function around routes that require authentication
Widget authRequired(BuildContext context, Widget screen) {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  if (!authProvider.isLoggedIn) {
    // Redirect to login if user is not logged in
    return const LoginScreen();
  }
  return screen;
}

final Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => authRequired(context, const DashboardScreen()),
  '/login': (context) => const LoginScreen(),
  '/upload': (context) => authRequired(context, const UploadScreen()),
  '/summary': (context) => authRequired(context, const SummaryScreen()),
  '/history': (context) => authRequired(context, const HistoryScreen()),
};
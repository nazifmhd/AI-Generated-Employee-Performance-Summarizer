import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'core/routes.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the auth provider but we'll use routes for navigation logic
    final authProvider = Provider.of<AuthProvider>(context);
    
    return MaterialApp(
      title: 'HR Performance Analytics',
      debugShowCheckedModeBanner: false,  // This removes the debug banner
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Use initialRoute instead of home
      initialRoute: '/',
      
      // Use the routes defined in routes.dart
      routes: appRoutes,
      
      // Handle unknown routes
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Page Not Found')),
          body: Center(
            child: Text('Route ${settings.name} not found'),
          ),
        ),
      ),
    );
  }
}
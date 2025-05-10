import 'package:flutter/material.dart';

class AppConstants {
  // App-wide colors
  static const primaryColor = Color(0xFF00796B); // Example: Teal Green
  static const secondaryColor = Color(0xFF004D40); // Example: Dark Teal

  // Text styles
  static const headingStyle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: primaryColor,
  );

  static const subHeadingStyle = TextStyle(
    fontSize: 18,
    color: Colors.black87,
  );

  static const bodyTextStyle = TextStyle(
    fontSize: 16,
    color: Colors.black54,
  );
}

// App routes
class AppRoutes {
  static const dashboard = '/dashboard';
  static const upload = '/upload';
  static const summary = '/summary';
  static const history = '/history';
}

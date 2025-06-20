import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class RouteGuard {
  static Route<dynamic> guardedRoute(
      BuildContext context, Widget destination, RouteSettings settings) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.isAuthenticated) {
      return MaterialPageRoute(
        builder: (context) => destination,
        settings: settings,
      );
    } else {
      // Redirect to login
      return MaterialPageRoute(
        builder: (context) => const Scaffold(
          body: Center(
            child: Text('Please login to continue'),
          ),
        ),
        settings: settings,
      );
    }
  }
}

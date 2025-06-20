import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart' as auth;
import 'providers/vehicle_provider.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_page.dart';
import 'screens/signup_page.dart';
import 'screens/home_page.dart';
import 'screens/user_profile_page.dart';
import 'screens/profile_setup_page.dart';
import 'screens/advanced_filter_page.dart';
import 'screens/guides_page.dart';
import 'screens/notifications_page.dart';
import 'screens/chatbot_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // ✅ CRITICAL FIX: Better Firebase initialization
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('✅ Firebase initialized successfully');
    } else {
      debugPrint('ℹ️ Firebase already initialized');
    }

    // ✅ CRITICAL FIX: Enable Firebase Auth persistence
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    debugPrint('✅ Firebase Auth persistence enabled');
  } catch (e) {
    debugPrint('❌ Firebase initialization error: $e');
    // Continue with app initialization even if Firebase fails
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => auth.AuthProvider()),
        ChangeNotifierProvider(create: (_) => VehicleProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          // Show loading screen while theme is loading
          if (themeProvider.isLoading) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              navigatorKey: auth
                  .navigatorKey, // ✅ FIX: Use navigatorKey from auth_provider
              home: const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            );
          }

          return MaterialApp(
            title: 'OptiMoto',
            debugShowCheckedModeBanner: false,
            navigatorKey:
                auth.navigatorKey, // ✅ FIX: Use navigatorKey from auth_provider
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode:
                themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const SplashScreen(),
            routes: {
              '/welcome': (context) => const WelcomeScreen(),
              '/login': (context) => const LoginPage(),
              '/signup': (context) => const SignupPage(),
              '/home': (context) => const HomePage(),
              '/profile': (context) => const UserProfilePage(),
              '/profile_setup': (context) => const ProfileSetupPage(),
              '/advanced_filter': (context) => const AdvancedFilterPage(),
              '/guides': (context) => const GuidesPage(),
              '/notifications': (context) => const NotificationsPage(),
              '/chatbot': (context) =>
                  const ChatbotPage(), // ✅ ADD: Chatbot route
            },
            builder: (context, widget) {
              ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
                debugPrint('❌ Widget Error: ${errorDetails.exception}');
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        const Text('Something went wrong!'),
                        const SizedBox(height: 8),
                        if (kDebugMode)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              errorDetails.exception.toString(),
                              style: const TextStyle(fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ElevatedButton(
                          onPressed: () {
                            // Try to restart the app
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/welcome',
                              (route) => false,
                            );
                          },
                          child: const Text('Restart App'),
                        ),
                      ],
                    ),
                  ),
                );
              };
              return widget!;
            },
          );
        },
      ),
    );
  }
}

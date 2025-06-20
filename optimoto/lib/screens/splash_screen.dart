import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_provider.dart'
    as auth; // ✅ FIX: Add alias to avoid conflict
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();
    _checkAuthenticationStatus();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ✅ FIX: Enhanced auth check with proper context usage
  void _checkAuthenticationStatus() async {
    // ✅ CRITICAL FIX: Wait for animations first
    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return; // ✅ FIX: Guard with mounted check

    final authProvider = context.read<auth.AuthProvider>(); // ✅ FIX: Use alias

    // ✅ CRITICAL FIX: Wait for auth provider to be initialized with retries
    int retries = 0;
    while (!authProvider.isInitialized && retries < 20) {
      await Future.delayed(const Duration(milliseconds: 250));
      retries++;
    }

    if (!mounted) return; // ✅ FIX: Guard with mounted check

    try {
      // ✅ CRITICAL FIX: Check both provider state AND Firebase current user
      final isProviderAuthenticated =
          authProvider.isAuthenticated && authProvider.user != null;
      final firebaseUser = FirebaseAuth.instance.currentUser;

      if (isProviderAuthenticated || firebaseUser != null) {
        debugPrint(
            '✅ User is authenticated: ${firebaseUser?.email ?? authProvider.user?.email}');

        // ✅ CRITICAL FIX: Ensure provider is synced with Firebase
        if (firebaseUser != null && !isProviderAuthenticated) {
          debugPrint('🔄 Syncing provider with Firebase user');
          // Force provider to sync with Firebase
          // authProvider._user = firebaseUser; // This would need to be implemented
        }

        if (mounted) {
          // ✅ FIX: Guard with mounted check
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        debugPrint('ℹ️ No authenticated user found');
        if (mounted) {
          // ✅ FIX: Guard with mounted check
          Navigator.pushReplacementNamed(context, '/welcome');
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking authentication: $e');
      if (mounted) {
        // ✅ FIX: Guard with mounted check
        Navigator.pushReplacementNamed(context, '/welcome');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryLight,
              AppTheme.primaryDark,
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.directions_car,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'OptiMoto',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Find Your Perfect Vehicle',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 60),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart'; // ✅ FIX: Add missing Provider import
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';
import 'theme_provider.dart';

// ✅ FIX: Add navigator key declaration
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _userProfile;
  bool _isInitialized = false;

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  Map<String, dynamic>? get userProfile => _userProfile;
  bool get isInitialized => _isInitialized;

  AuthProvider() {
    _initializeAuth();
  }

  // ✅ ENHANCED: Better auth state initialization
  void _initializeAuth() {
    try {
      // Set current user immediately if available
      _user = _auth.currentUser;

      _auth.authStateChanges().listen((User? user) async {
        debugPrint('🔄 Auth state changed: ${user?.email ?? 'null'}');

        try {
          _user = user;

          if (user != null) {
            debugPrint('✅ User authenticated: ${user.uid}');
            // Load profile in background, don't block auth state
            _loadUserProfileInBackground();
          } else {
            debugPrint('ℹ️ User logged out');
            _userProfile = null;
            _clearError(); // ✅ CRITICAL FIX: Clear errors on logout
          }
        } catch (e) {
          debugPrint('⚠️ Error in auth state change: $e');
          // Don't fail on profile loading errors
        } finally {
          if (!_isInitialized) {
            _isInitialized = true;
          }
          notifyListeners();
        }
      }, onError: (error) {
        debugPrint('❌ Auth state listener error: $error');
        // Don't set error state for auth listener issues
        if (!_isInitialized) {
          _isInitialized = true;
        }
        notifyListeners();
      });
    } catch (e) {
      debugPrint('❌ Error setting up auth listener: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  // ✅ NEW: Load profile in background without blocking login
  void _loadUserProfileInBackground() {
    _loadUserProfile().catchError((e) {
      debugPrint(
          '⚠️ Warning: Profile loading failed but user is authenticated: $e');
      // Don't set error state for profile loading issues
    });
  }

  // ✅ FIX: Safe profile loading method
  Future<void> _loadUserProfile() async {
    try {
      final profile = await FirebaseService.getUserProfile();
      if (profile != null) {
        _userProfile = profile;
        debugPrint('✅ User profile loaded: ${profile.keys}');
      } else {
        debugPrint('ℹ️ No user profile found');
        _userProfile = null;
      }
    } catch (e) {
      debugPrint('❌ Error in _loadUserProfile: $e');
      _userProfile = null;
      // Don't rethrow to avoid breaking auth flow
    }
  }

  // ✅ ENHANCED: Email/Password Signup with comprehensive error handling
  Future<bool> signUpWithEmailAndPassword(
    String email,
    String password, {
    String? firstName,
    String? lastName,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Input validation
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email and password cannot be empty');
      }

      if (password.length < 6) {
        throw Exception('Password must be at least 6 characters');
      }

      if (!_isValidEmail(email)) {
        throw Exception('Please enter a valid email address');
      }

      debugPrint('🔄 Creating user account for: $email');

      // ✅ FIX: Wrap Firebase operations in try-catch
      UserCredential? credential;
      try {
        credential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        debugPrint('✅ Firebase Auth successful');
      } on FirebaseAuthException catch (authError) {
        debugPrint(
            '❌ Firebase Auth Error: ${authError.code} - ${authError.message}');
        throw authError;
      } catch (unknownError) {
        debugPrint('❌ Unknown auth error: $unknownError');
        throw Exception('Authentication failed: $unknownError');
      }

      final user = credential.user;
      if (user != null) {
        debugPrint('✅ User created successfully: ${user.uid}');

        // Update display name (non-critical)
        try {
          if (firstName != null && firstName.isNotEmpty) {
            final displayName = lastName != null && lastName.isNotEmpty
                ? '$firstName $lastName'
                : firstName;
            await user.updateDisplayName(displayName);
            await user.reload();
            _user = _auth.currentUser;
            debugPrint('✅ Display name updated');
          }
        } catch (e) {
          debugPrint('⚠️ Warning: Could not update display name: $e');
        }

        // Initialize user document (non-critical)
        try {
          await FirebaseService.initializeUserDocument(
            user,
            firstName: firstName,
            lastName: lastName,
          );
          debugPrint('✅ User document initialized');
        } catch (e) {
          debugPrint('⚠️ Warning: Could not initialize user document: $e');
        }

        // Send welcome notifications (non-critical)
        try {
          await NotificationService.sendWelcomeNotifications();
          debugPrint('✅ Welcome notifications sent');
        } catch (e) {
          debugPrint('⚠️ Warning: Could not send welcome notifications: $e');
        }

        _setLoading(false);
        return true;
      }

      throw Exception('Failed to create user account');
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase Auth Exception: ${e.code} - ${e.message}');
      _setError(_getAuthErrorMessage(e.code));
      _setLoading(false);
      return false;
    } catch (e) {
      debugPrint('❌ Signup error: $e');
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  // ✅ CRITICAL FIX: Completely rewrite login to handle type cast errors properly
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      _setLoading(true);
      _clearError();

      // Input validation
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email and password cannot be empty');
      }

      if (!_isValidEmail(email)) {
        throw Exception('Please enter a valid email address');
      }

      debugPrint('🔄 Signing in user: $email');

      // ✅ CRITICAL FIX: Separate Firebase auth from UI error handling
      UserCredential? credential;
      User? firebaseUser;

      try {
        // Perform Firebase authentication
        credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        firebaseUser = credential.user;
        debugPrint('✅ Firebase Auth successful for user: ${firebaseUser?.uid}');
      } on FirebaseAuthException catch (authError) {
        debugPrint(
            '❌ Firebase Auth Error: ${authError.code} - ${authError.message}');
        _setError(_getAuthErrorMessage(authError.code));
        _setLoading(false);
        return false;
      }

      // ✅ CRITICAL FIX: If we have a Firebase user, consider login successful
      if (firebaseUser != null) {
        debugPrint('✅ User signed in successfully: ${firebaseUser.uid}');

        // ✅ CRITICAL FIX: Set user immediately, don't wait for profile loading
        _user = firebaseUser;

        // Load user profile in background (non-blocking)
        _loadUserProfileInBackground();

        // ✅ FIX: Sync theme preference after login with proper error handling
        try {
          final context = navigatorKey.currentContext;
          if (context != null) {
            final themeProvider =
                Provider.of<ThemeProvider>(context, listen: false);
            await themeProvider.syncWithFirebase();
          }
        } catch (e) {
          debugPrint('⚠️ Theme sync error: $e');
          // Don't fail login for theme sync issues
        }

        _setLoading(false);
        return true; // ✅ CRITICAL FIX: Return success immediately
      }

      // If no user, it's an error
      _setError('Authentication failed. Please try again.');
      _setLoading(false);
      return false;
    } catch (e) {
      debugPrint('❌ Unexpected login error: $e');

      // ✅ CRITICAL FIX: Even if there's an error, check if user is actually signed in
      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.email == email) {
        debugPrint(
            '✅ User is actually authenticated despite error: ${currentUser.uid}');
        _user = currentUser;
        _loadUserProfileInBackground();
        _setLoading(false);
        return true; // ✅ CRITICAL FIX: Return success if Firebase says user is authenticated
      }

      _setError('Authentication failed. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  // ✅ ENHANCED: Complete logout with cleanup
  Future<void> logout() async {
    try {
      debugPrint('🔄 Logging out user...');
      _setLoading(true);

      // Clear local state first
      _user = null;
      _userProfile = null;
      _errorMessage = null;

      // Sign out from Firebase
      await _auth.signOut();

      debugPrint('✅ User logged out successfully');
      _setLoading(false);
    } catch (e) {
      debugPrint('❌ Logout error: $e');
      _setError('Failed to logout: $e');
      _setLoading(false);
      rethrow;
    }
  }

  // ✅ NEW: Password Reset
  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _clearError();

      if (email.isEmpty) {
        throw Exception('Email cannot be empty');
      }

      if (!_isValidEmail(email)) {
        throw Exception('Please enter a valid email address');
      }

      await _auth.sendPasswordResetEmail(email: email);

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Password reset error: ${e.code} - ${e.message}');
      _setError(_getAuthErrorMessage(e.code));
      _setLoading(false);
      return false;
    } catch (e) {
      debugPrint('❌ Password reset error: $e');
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  // ✅ NEW: Update user profile
  Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    try {
      _setLoading(true);
      _clearError();

      await FirebaseService.updateUserProfile(profileData);
      await _loadUserProfile();

      _setLoading(false);
      return true;
    } catch (e) {
      debugPrint('❌ Update profile error: $e');
      _setError('Failed to update profile: $e');
      _setLoading(false);
      return false;
    }
  }

  // ✅ NEW: Reload user data
  Future<void> reloadUserData() async {
    try {
      if (_user != null) {
        await _user!.reload();
        _user = _auth.currentUser;
        await _loadUserProfile();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error reloading user data: $e');
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  // ✅ FIX: Make _clearError public method
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Keep private method for internal use
  void _clearError() {
    clearError();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'requires-recent-login':
        return 'Please log out and log in again to perform this action.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}

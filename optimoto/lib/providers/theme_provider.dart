import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_service.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool _isLoading = true;

  bool get isDarkMode => _isDarkMode;
  bool get isLoading => _isLoading;

  ThemeProvider() {
    _loadThemePreference();
  }

  // Load theme preference from local storage and Firebase
  Future<void> _loadThemePreference() async {
    try {
      // First check local storage for immediate loading
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool('dark_mode') ?? false;
      _isLoading = false;
      notifyListeners();

      // Then sync with Firebase if user is logged in
      if (FirebaseService.isAuthenticated) {
        final userPrefs = await FirebaseService.getUserPreferences();
        if (userPrefs != null && userPrefs['darkMode'] != null) {
          final firebaseDarkMode = userPrefs['darkMode'] as bool;
          if (firebaseDarkMode != _isDarkMode) {
            _isDarkMode = firebaseDarkMode;
            await prefs.setBool('dark_mode', _isDarkMode);
            notifyListeners();
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading theme preference: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Toggle dark mode
  Future<void> toggleDarkMode() async {
    try {
      _isDarkMode = !_isDarkMode;
      notifyListeners();

      // Save to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dark_mode', _isDarkMode);

      // Save to Firebase if user is logged in
      if (FirebaseService.isAuthenticated) {
        final currentPrefs = await FirebaseService.getUserPreferences() ?? {};
        currentPrefs['darkMode'] = _isDarkMode;
        await FirebaseService.updateUserPreferences(currentPrefs);
      }

      debugPrint('Dark mode ${_isDarkMode ? 'enabled' : 'disabled'}');
    } catch (e) {
      debugPrint('Error toggling dark mode: $e');
      // Revert on error
      _isDarkMode = !_isDarkMode;
      notifyListeners();
    }
  }

  // Set dark mode (called from settings)
  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode == value) return;

    try {
      _isDarkMode = value;
      notifyListeners();

      // Save to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dark_mode', _isDarkMode);

      // Save to Firebase if user is logged in
      if (FirebaseService.isAuthenticated) {
        final currentPrefs = await FirebaseService.getUserPreferences() ?? {};
        currentPrefs['darkMode'] = _isDarkMode;
        await FirebaseService.updateUserPreferences(currentPrefs);
      }

      debugPrint('Dark mode ${_isDarkMode ? 'enabled' : 'disabled'}');
    } catch (e) {
      debugPrint('Error setting dark mode: $e');
      // Revert on error
      _isDarkMode = !_isDarkMode;
      notifyListeners();
    }
  }

  // Sync with Firebase when user logs in
  Future<void> syncWithFirebase() async {
    if (!FirebaseService.isAuthenticated) return;

    try {
      final userPrefs = await FirebaseService.getUserPreferences();
      if (userPrefs != null && userPrefs['darkMode'] != null) {
        final firebaseDarkMode = userPrefs['darkMode'] as bool;
        if (firebaseDarkMode != _isDarkMode) {
          _isDarkMode = firebaseDarkMode;

          // Update local storage
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('dark_mode', _isDarkMode);

          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error syncing theme with Firebase: $e');
    }
  }
}

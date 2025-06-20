import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

class NetworkChecker {
  static bool _isOnline = true;
  static final StreamController<bool> _controller =
      StreamController<bool>.broadcast();
  static Timer? _timer;

  static bool get isOnline => _isOnline;
  static Stream<bool> get onConnectivityChanged => _controller.stream;

  static void startMonitoring() {
    _timer?.cancel();
    _timer =
        Timer.periodic(const Duration(seconds: 5), (_) => _checkConnection());
    _checkConnection();
  }

  static void stopMonitoring() {
    _timer?.cancel();
  }

  static Future<void> _checkConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));

      final newStatus = result.isNotEmpty && result[0].rawAddress.isNotEmpty;

      if (newStatus != _isOnline) {
        _isOnline = newStatus;
        _controller.add(_isOnline);
        debugPrint(
            'Network status changed: ${_isOnline ? 'Online' : 'Offline'}');
      }
    } catch (e) {
      if (_isOnline) {
        _isOnline = false;
        _controller.add(_isOnline);
        debugPrint('Network connection lost');
      }
    }
  }

  static void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}

import 'package:flutter/material.dart';
import '../services/network_checker.dart';
import '../widgets/offline_banner.dart';

class ConnectionStatusWidget extends StatefulWidget {
  final Widget child;

  const ConnectionStatusWidget({super.key, required this.child});

  @override
  State<ConnectionStatusWidget> createState() => _ConnectionStatusWidgetState();
}

class _ConnectionStatusWidgetState extends State<ConnectionStatusWidget> {
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _isOnline = NetworkChecker.isOnline;
    NetworkChecker.onConnectivityChanged.listen((isOnline) {
      if (mounted) {
        setState(() {
          _isOnline = isOnline;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        OfflineBanner(isOnline: _isOnline),
        Expanded(child: widget.child),
      ],
    );
  }
}

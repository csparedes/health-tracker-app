import 'package:flutter/material.dart';
import '../services/services.dart';

/// Widget that shows offline status indicator
class OfflineIndicator extends StatefulWidget {
  const OfflineIndicator({super.key});

  @override
  State<OfflineIndicator> createState() => _OfflineIndicatorState();
}

class _OfflineIndicatorState extends State<OfflineIndicator> {
  final ConnectivityService _connectivityService = ConnectivityService();
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _isConnected = _connectivityService.isConnected;
    _connectivityService.connectivityStream.listen((isConnected) {
      if (mounted) {
        setState(() {
          _isConnected = isConnected;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isConnected) {
      return const SizedBox.shrink(); // Don't show anything when online
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.orange[100],
      child: Row(
        children: [
          Icon(
            Icons.wifi_off,
            color: Colors.orange[800],
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sin conexión a internet - Los datos se guardan localmente',
              style: TextStyle(
                color: Colors.orange[800],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
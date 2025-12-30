import 'dart:async';
import 'dart:io';

/// Service to monitor network connectivity status
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();
  Timer? _connectivityTimer;
  bool _isConnected = false;

  /// Stream of connectivity status changes
  Stream<bool> get connectivityStream => _connectivityController.stream;

  /// Current connectivity status
  bool get isConnected => _isConnected;

  /// Start monitoring connectivity
  void startMonitoring() {
    // Check connectivity every 30 seconds
    _connectivityTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkConnectivity();
    });
    
    // Initial check
    _checkConnectivity();
  }

  /// Stop monitoring connectivity
  void stopMonitoring() {
    _connectivityTimer?.cancel();
    _connectivityTimer = null;
  }

  /// Check current connectivity status
  Future<void> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      final newStatus = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      
      if (newStatus != _isConnected) {
        _isConnected = newStatus;
        _connectivityController.add(_isConnected);
      }
    } catch (e) {
      if (_isConnected) {
        _isConnected = false;
        _connectivityController.add(_isConnected);
      }
    }
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
    _connectivityController.close();
  }
}
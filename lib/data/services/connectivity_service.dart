import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();

  bool _isConnected = true;
  bool get isConnected => _isConnected;

  Stream<bool> get connectionStream => _connectionController.stream;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    // Check initial connectivity
    await _checkConnectivity();
    
    // Listen to connectivity changes
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  /// Check current connectivity status
  Future<void> _checkConnectivity() async {
    try {
      final List<ConnectivityResult> connectivityResults = await _connectivity.checkConnectivity();
      _updateConnectionStatus(connectivityResults);
    } catch (e) {
      // If connectivity check fails, assume offline
      _updateConnectionStatus([ConnectivityResult.none]);
    }
  }

  /// Update connection status based on connectivity result
  void _updateConnectionStatus(List<ConnectivityResult> connectivityResults) {
    final bool wasConnected = _isConnected;
    
    // Check if any connection type is available
    _isConnected = connectivityResults.any((result) => 
      result == ConnectivityResult.mobile ||
      result == ConnectivityResult.wifi ||
      result == ConnectivityResult.ethernet ||
      result == ConnectivityResult.vpn
    );

    // Only emit if status changed
    if (wasConnected != _isConnected) {
      _connectionController.add(_isConnected);
    }
  }

  /// Get detailed connection info
  String getConnectionType() {
    if (!_isConnected) return 'Offline';
    
    _connectivity.checkConnectivity().then((List<ConnectivityResult> results) {
      if (results.contains(ConnectivityResult.wifi)) return 'WiFi';
      if (results.contains(ConnectivityResult.mobile)) return 'Mobile Data';
      if (results.contains(ConnectivityResult.ethernet)) return 'Ethernet';
      if (results.contains(ConnectivityResult.vpn)) return 'VPN';
      return 'Unknown';
    });
    
    return 'Connected';
  }

  /// Test actual internet connectivity (not just network connection)
  Future<bool> hasInternetAccess() async {
    try {
      final List<ConnectivityResult> connectivityResults = await _connectivity.checkConnectivity();
      
      if (connectivityResults.contains(ConnectivityResult.none)) {
        return false;
      }

      // Could add additional checks here like pinging a server
      // For now, we'll assume network connectivity means internet access
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Dispose of resources
  void dispose() {
    _connectionController.close();
  }
}

/// Convenience extension for easy access
extension ConnectivityExtension on ConnectivityService {
  /// Check if device is online
  bool get isOnline => isConnected;
  
  /// Check if device is offline
  bool get isOffline => !isConnected;
}
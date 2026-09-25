import 'package:connectivity_plus/connectivity_plus.dart';

/// Checks active device network connectivity.
class NetworkInfo {
  final Connectivity _connectivity;

  NetworkInfo([Connectivity? connectivity]) : _connectivity = connectivity ?? Connectivity();

  Future<bool> get isConnected async {
    try {
      final results = await _connectivity.checkConnectivity();
      if (results.length == 1 && results.first == ConnectivityResult.none) {
        return false;
      }
      return true;
    } catch (_) {
      return true;
    }
  }
}

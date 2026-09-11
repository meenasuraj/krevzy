import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  ConnectivityService._();

  static final Connectivity _connectivity =
      Connectivity();

  static StreamSubscription<List<ConnectivityResult>>?
      _subscription;

  static final StreamController<bool>
      _statusController =
      StreamController<bool>.broadcast();

  static bool _isOnline = true;

  static bool get isOnline => _isOnline;

  static Stream<bool> get statusStream =>
      _statusController.stream;

  static Future<void> initialize() async {
    if (_subscription != null) {
      return;
    }

    await _checkInitialStatus();

    _subscription = _connectivity.onConnectivityChanged
        .listen(
      (results) {
        final online =
            _hasConnection(results);

        _updateStatus(online);
      },
    );
  }

  static Future<void> _checkInitialStatus() async {
    try {
      final results =
          await _connectivity.checkConnectivity();

      _updateStatus(
        _hasConnection(results),
      );
    } catch (e) {
      // If the connectivity plugin itself fails,
      // don't crash the application.
      _updateStatus(true);
    }
  }

  static bool _hasConnection(
    List<ConnectivityResult> results,
  ) {
    if (results.isEmpty) {
      return false;
    }

    return results.any(
      (result) =>
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet ||
          result == ConnectivityResult.vpn ||
          result == ConnectivityResult.bluetooth ||
          result == ConnectivityResult.other,
    );
  }

  static void _updateStatus(bool online) {
    if (_isOnline == online) {
      return;
    }

    _isOnline = online;

    if (!_statusController.isClosed) {
      _statusController.add(online);
    }
  }

  static Future<void> dispose() async {
    await _subscription?.cancel();

    _subscription = null;

    await _statusController.close();
  }
}
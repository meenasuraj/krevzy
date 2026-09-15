import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Check whether this platform can use local authentication.
  static Future<bool> isAvailable() async {
    if (kIsWeb) {
      return false;
    }

    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();

      return canCheck && isSupported;
    } catch (_) {
      return false;
    }
  }

  /// Returns the biometric types available on the device.
  static Future<List<BiometricType>> availableBiometrics() async {
    if (kIsWeb) {
      return [];
    }

    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Authenticate using the device biometric.
  static Future<bool> authenticate() async {
    if (kIsWeb) {
      return false;
    }

    try {
      final available = await availableBiometrics();

      if (available.isEmpty) {
        return false;
      }

      return await _auth.authenticate(
        localizedReason: 'Authenticate to unlock krevzy',
        biometricOnly: true,
        sensitiveTransaction: true,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }

  /// Human-readable name for the available biometric.
  static Future<String> getBiometricLabel() async {
    final biometrics = await availableBiometrics();

    if (biometrics.contains(BiometricType.face)) {
      return 'Face ID';
    }

    if (biometrics.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    }

    if (biometrics.contains(BiometricType.strong)) {
      return 'Biometric';
    }

    if (biometrics.contains(BiometricType.weak)) {
      return 'Biometric';
    }

    return 'Biometric';
  }
}

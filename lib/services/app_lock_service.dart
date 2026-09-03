import 'package:shared_preferences/shared_preferences.dart';

import 'chat_lock_service.dart';

class AppLockService {
  static const String _enabledKey = 'gapshap_app_lock_enabled';
  static const String _pinHashKey = 'gapshap_app_lock_pin_hash';
  static const String _biometricEnabledKey = 'gapshap_biometric_enabled';

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  static Future<String?> getPinHash() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pinHashKey);
  }

  static Future<void> enable(String pin) async {
    final prefs = await SharedPreferences.getInstance();

    final pinHash = ChatLockService.hashPin(pin);

    await prefs.setString(_pinHashKey, pinHash);
    await prefs.setBool(_enabledKey, true);

    // Biometric starts disabled when App Lock is first enabled.
    await prefs.setBool(_biometricEnabledKey, false);
  }

  static Future<bool> verifyPin(String pin) async {
    final savedHash = await getPinHash();

    if (savedHash == null) {
      return false;
    }

    final enteredHash = ChatLockService.hashPin(pin);

    return enteredHash == savedHash;
  }

  static Future<void> changePin(String newPin) async {
    final prefs = await SharedPreferences.getInstance();

    final newPinHash = ChatLockService.hashPin(newPin);

    await prefs.setString(_pinHashKey, newPinHash);
  }

  static Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  static Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_biometricEnabledKey, enabled);
  }

  static Future<void> disable() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_pinHashKey);

    await prefs.setBool(_enabledKey, false);

    // Turning off App Lock also turns off biometric App Lock.
    await prefs.setBool(_biometricEnabledKey, false);
  }
}

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatLockService {
  static const String _storageKey = 'krevzy_chat_pin_hashes';

  /// PIN ko SHA-256 hash mein convert karta hai.
  static String hashPin(String pin) {
    return sha256.convert(utf8.encode(pin)).toString();
  }

  /// Saare chat PIN hashes load karta hai.
  static Future<Map<String, String>> loadPinHashes() async {
    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getString(_storageKey);

    if (raw == null || raw.isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is Map) {
        return Map<String, String>.from(decoded);
      }
    } catch (_) {
      // Corrupt/invalid data ho to empty map use hoga.
    }

    return {};
  }

  /// Saare chat PIN hashes save karta hai.
  static Future<void> savePinHashes(Map<String, String> pinHashes) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_storageKey, jsonEncode(pinHashes));
  }
}

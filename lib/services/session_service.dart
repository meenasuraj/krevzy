import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:universal_html/html.dart' as html;

class SessionService {
  static const String _sessionIdKey = 'gapshap_session_id';
  static const String _sessionStartedKey =
      'gapshap_session_started';

  static const String _cookieName = 'gapshap_session';

  static Future<void> startSession() async {
    final prefs = await SharedPreferences.getInstance();

    final sessionId = _generateSessionId();

    await prefs.setString(
      _sessionIdKey,
      sessionId,
    );

    await prefs.setInt(
      _sessionStartedKey,
      DateTime.now().millisecondsSinceEpoch,
    );

    _setWebCookie(sessionId);
  }

  static Future<bool> isSessionActive() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();

    final sessionId = prefs.getString(_sessionIdKey);

    if (sessionId == null || sessionId.isEmpty) {
      return false;
    }

    return true;
  }

  static Future<String?> getSessionId() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_sessionIdKey);
  }

  static Future<DateTime?> getSessionStartTime() async {
    final prefs = await SharedPreferences.getInstance();

    final timestamp = prefs.getInt(
      _sessionStartedKey,
    );

    if (timestamp == null) {
      return null;
    }

    return DateTime.fromMillisecondsSinceEpoch(
      timestamp,
    );
  }

  static Future<void> endSession() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_sessionIdKey);
    await prefs.remove(_sessionStartedKey);

    _deleteWebCookie();
  }

  static String _generateSessionId() {
    final random = Random.secure();

    final bytes = List<int>.generate(
      32,
      (_) => random.nextInt(256),
    );

    return bytes
        .map(
          (byte) => byte.toRadixString(16).padLeft(2, '0'),
        )
        .join();
  }

  static void _setWebCookie(String sessionId) {
    try {
      html.document.cookie =
          '$_cookieName=$sessionId; path=/; SameSite=Lax';
    } catch (_) {
      // Android/iOS: browser cookie system is not available.
    }
  }

  static void _deleteWebCookie() {
    try {
      html.document.cookie =
          '$_cookieName=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT';
    } catch (_) {
      // Android/iOS: browser cookie system is not available.
    }
  }
}
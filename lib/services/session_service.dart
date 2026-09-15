import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_html/html.dart' as html;

class SessionService {
  static const String _sessionIdKey = 'krevzy_session_id';
  static const String _sessionStartedKey = 'krevzy_session_started';
  static const String _cookieName = 'krevzy_session';

  static Timer? _heartbeat;
  static bool _started = false;

  static CollectionReference<Map<String, dynamic>> _sessions(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid).collection('sessions');

  static DocumentReference<Map<String, dynamic>> _user(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid);

  static Future<void> setBackground(bool inBackground) async {
    if (inBackground) {
      await markOffline();
    } else {
      await ensureSession();
    }
  }

  static Future<void> startSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (_started) {
      await touchActivity();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    var sessionId = prefs.getString(_sessionIdKey);
    var startedMillis = prefs.getInt(_sessionStartedKey);
    if (sessionId == null || sessionId.isEmpty) {
      sessionId = _generateSessionId();
      startedMillis = DateTime.now().millisecondsSinceEpoch;
      await prefs.setString(_sessionIdKey, sessionId);
      await prefs.setInt(_sessionStartedKey, startedMillis);
      _setWebCookie(sessionId);
    }

    final now = FieldValue.serverTimestamp();
    bool activityStatus = true;
    try {
      final social = await _user(user.uid).collection('settings').doc('social').get();
      activityStatus = social.data()?['activity_status'] as bool? ?? true;
    } catch (_) {}
    await _user(user.uid).set({
      'isOnline': true,
      'lastActiveAt': now,
      'activityStatus': activityStatus,
      'updatedAt': now,
    }, SetOptions(merge: true));

    await _sessions(user.uid).doc(sessionId).set({
      'sessionId': sessionId,
      'userId': user.uid,
      'device': _deviceName(),
      'platform': _platformName(),
      'startedAt': startedMillis == null
          ? now
          : Timestamp.fromMillisecondsSinceEpoch(startedMillis),
      'lastActiveAt': now,
      'endedAt': null,
    }, SetOptions(merge: true));

    _started = true;
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(const Duration(seconds: 45), (_) {
      touchActivity();
    });
  }

  static Future<void> ensureSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final id = await getSessionId();
    if (id == null || id.isEmpty) {
      await startSession();
      return;
    }
    _started = false;
    await startSession();
  }

  static Future<void> touchActivity() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final sessionId = await getSessionId();
    if (sessionId == null || sessionId.isEmpty) return;
    try {
      final now = FieldValue.serverTimestamp();
      await _user(user.uid).set({
        'isOnline': true,
        'lastActiveAt': now,
      }, SetOptions(merge: true));
      await _sessions(user.uid).doc(sessionId).set({
        'lastActiveAt': now,
        'endedAt': null,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('KREVZY activity update failed: $e');
    }
  }

  static Future<void> markOffline() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final sessionId = await getSessionId();
    final now = FieldValue.serverTimestamp();
    try {
      await _user(user.uid).set({
        'isOnline': false,
        'lastSeen': now,
        'lastActiveAt': now,
      }, SetOptions(merge: true));
      if (sessionId != null && sessionId.isNotEmpty) {
        await _sessions(user.uid).doc(sessionId).set({
          'lastActiveAt': now,
          'endedAt': now,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('KREVZY offline update failed: $e');
    }
  }

  static Future<bool> isSessionActive() async {
    final user = FirebaseAuth.instance.currentUser;
    final id = await getSessionId();
    if (user == null || id == null || id.isEmpty) return false;
    try {
      return (await _sessions(user.uid).doc(id).get()).exists;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> getSessionId() async =>
      (await SharedPreferences.getInstance()).getString(_sessionIdKey);

  static Future<DateTime?> getSessionStartTime() async {
    final timestamp = (await SharedPreferences.getInstance()).getInt(_sessionStartedKey);
    return timestamp == null ? null : DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  static Future<void> endSession() async {
    _heartbeat?.cancel();
    _heartbeat = null;
    _started = false;
    final user = FirebaseAuth.instance.currentUser;
    final sessionId = await getSessionId();
    if (user != null) {
      final now = FieldValue.serverTimestamp();
      try {
        await _user(user.uid).set({
          'isOnline': false,
          'lastSeen': now,
          'lastActiveAt': now,
        }, SetOptions(merge: true));
        if (sessionId != null && sessionId.isNotEmpty) {
          await _sessions(user.uid).doc(sessionId).set({'endedAt': now}, SetOptions(merge: true));
        }
      } catch (e) {
        debugPrint('KREVZY session end failed: $e');
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionIdKey);
    await prefs.remove(_sessionStartedKey);
    _deleteWebCookie();
  }

  static Future<void> revokeSession(String sessionId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || sessionId.isEmpty) return;
    if (sessionId == await getSessionId()) {
      await endSession();
      return;
    }
    await _sessions(user.uid).doc(sessionId).set({
      'endedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static String _deviceName() => kIsWeb ? 'Web browser' : 'Mobile device';
  static String _platformName() => kIsWeb ? 'web' : 'mobile';

  static String _generateSessionId() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static void _setWebCookie(String id) {
    try { html.document.cookie = '$_cookieName=$id; path=/; SameSite=Lax'; } catch (_) {}
  }
  static void _deleteWebCookie() {
    try { html.document.cookie = '$_cookieName=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT'; } catch (_) {}
  }
}

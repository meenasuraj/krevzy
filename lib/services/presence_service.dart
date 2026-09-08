import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PresenceService {
  PresenceService._();

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static final FirebaseAuth _auth =
      FirebaseAuth.instance;

  static Timer? _heartbeatTimer;
  static bool _initialized = false;

  static String get currentUserId {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    return user.uid;
  }

  static DocumentReference<Map<String, dynamic>> _userRef(
    String uid,
  ) {
    return _firestore
        .collection('users')
        .doc(uid);
  }

  /// Starts the user's online presence.
  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    _initialized = true;

    await setOnline();

    _heartbeatTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) async {
        try {
          await setOnline();
        } catch (_) {
          // Presence heartbeat failure must not affect the app.
        }
      },
    );
  }

  /// Marks the current user as online.
  static Future<void> setOnline() async {
    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    await _userRef(user.uid).set(
      {
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Marks the current user offline and records last seen.
  static Future<void> setOffline() async {
    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    await _userRef(user.uid).set(
      {
        'isOnline': false,
        'lastSeen': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Stops heartbeat and marks the user offline.
  static Future<void> dispose() async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    if (!_initialized) {
      return;
    }

    try {
      await setOffline();
    } catch (_) {
      // Offline update failure must not affect app shutdown.
    }

    _initialized = false;
  }

  /// Real-time presence stream for another user.
  static Stream<Map<String, dynamic>> getUserPresence(
    String userId,
  ) {
    return _userRef(userId).snapshots().map(
      (snapshot) {
        final data = snapshot.data() ?? {};

        final lastSeenTimestamp =
            data['lastSeen'];

        DateTime? lastSeen;

        if (lastSeenTimestamp is Timestamp) {
          lastSeen = lastSeenTimestamp.toDate();
        }

        return {
          'isOnline': data['isOnline'] == true,
          'lastSeen': lastSeen,
        };
      },
    );
  }

  /// Gets another user's current presence once.
  static Future<Map<String, dynamic>> getUserPresenceOnce(
    String userId,
  ) async {
    final snapshot =
        await _userRef(userId).get();

    final data = snapshot.data() ?? {};

    final lastSeenTimestamp =
        data['lastSeen'];

    DateTime? lastSeen;

    if (lastSeenTimestamp is Timestamp) {
      lastSeen = lastSeenTimestamp.toDate();
    }

    return {
      'isOnline': data['isOnline'] == true,
      'lastSeen': lastSeen,
    };
  }

  /// Converts a last-seen time into readable text.
  static String formatLastSeen(
    DateTime? lastSeen,
  ) {
    if (lastSeen == null) {
      return 'Last seen recently';
    }

    final now = DateTime.now();
    final difference =
        now.difference(lastSeen);

    if (difference.inSeconds < 60) {
      return 'Last seen just now';
    }

    if (difference.inMinutes < 60) {
      final minutes =
          difference.inMinutes;

      return 'Last seen $minutes '
          '${minutes == 1 ? 'minute' : 'minutes'} ago';
    }

    if (difference.inHours < 24) {
      final hours =
          difference.inHours;

      return 'Last seen $hours '
          '${hours == 1 ? 'hour' : 'hours'} ago';
    }

    if (difference.inDays < 7) {
      final days =
          difference.inDays;

      return 'Last seen $days '
          '${days == 1 ? 'day' : 'days'} ago';
    }

    final day =
        lastSeen.day.toString().padLeft(2, '0');

    final month =
        lastSeen.month.toString().padLeft(2, '0');

    final year =
        lastSeen.year.toString();

    return 'Last seen $day/$month/$year';
  }
}
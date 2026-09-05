import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/notification.dart';

class NotificationService {
  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static final FirebaseAuth _auth =
      FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> _notifications(
    String uid,
  ) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications');
  }

  static Stream<List<AppNotification>> getNotifications() {
    final user = _auth.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return _notifications(user.uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(AppNotification.fromFirestore)
              .toList(),
        );
  }

  static Stream<int> getUnreadCount() {
    final user = _auth.currentUser;

    if (user == null) {
      return Stream.value(0);
    }

    return _notifications(user.uid)
        .where(
          'isRead',
          isEqualTo: false,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.length,
        );
  }

  static Future<void> createNotification({
    required String receiverUserId,
    required String type,
    required String message,
    String fromUsername = '',
    String fromUserPhotoUrl = '',
    String postId = '',
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'User is not logged in.',
      );
    }

    final receiverId = receiverUserId.trim();

    if (receiverId.isEmpty) {
      throw Exception(
        'Notification receiver UID is empty.',
      );
    }

    // Don't notify yourself.
    if (receiverId == user.uid) {
      return;
    }

    final notificationRef = _notifications(
      receiverId,
    ).doc();

    final notificationData = {
      'type': type,
      'fromUserId': user.uid,
      'fromUsername': fromUsername,
      'fromUserPhotoUrl': fromUserPhotoUrl,
      'postId': postId,
      'message': message,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    };

    print(
      'CREATING NOTIFICATION\n'
      'Receiver UID: $receiverId\n'
      'Sender UID: ${user.uid}\n'
      'Type: $type\n'
      'Message: $message\n'
      'Document: ${notificationRef.path}',
    );

    try {
      await notificationRef.set(
        notificationData,
      );

      print(
        'NOTIFICATION CREATED SUCCESSFULLY: '
        '${notificationRef.path}',
      );
    } catch (e) {
      print(
        'NOTIFICATION CREATE ERROR: $e',
      );

      rethrow;
    }
  }

  // Temporary diagnostic method.
  // This creates a notification for the currently
  // logged-in user so we can verify Firestore
  // notification read/write functionality.
  static Future<void> createTestNotification() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'User is not logged in.',
      );
    }

    final notificationRef = _notifications(
      user.uid,
    ).doc();

    print(
      'CREATING TEST NOTIFICATION: '
      '${notificationRef.path}',
    );

    await notificationRef.set({
      'type': 'system',
      'fromUserId': user.uid,
      'fromUsername': 'GAPSHAP',
      'fromUserPhotoUrl': '',
      'postId': '',
      'message': 'GAPSHAP notification test successful',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    print(
      'TEST NOTIFICATION CREATED SUCCESSFULLY',
    );
  }

  static Future<void> markAsRead(
    String notificationId,
  ) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'User is not logged in.',
      );
    }

    await _notifications(user.uid)
        .doc(notificationId)
        .update({
      'isRead': true,
    });
  }

  static Future<void> markAllAsRead() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'User is not logged in.',
      );
    }

    final snapshot = await _notifications(user.uid)
        .where(
          'isRead',
          isEqualTo: false,
        )
        .get();

    if (snapshot.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.update(
        doc.reference,
        {
          'isRead': true,
        },
      );
    }

    await batch.commit();
  }

  static Future<void> deleteNotification(
    String notificationId,
  ) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'User is not logged in.',
      );
    }

    await _notifications(user.uid)
        .doc(notificationId)
        .delete();
  }
}
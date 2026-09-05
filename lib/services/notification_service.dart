import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/notification.dart';

class NotificationService {
  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static final FirebaseAuth _auth =
      FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>>
      _notifications(
    String uid,
  ) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications');
  }

  // ============================================================
  // ALL NOTIFICATIONS
  // ============================================================

  static Stream<List<AppNotification>>
      getNotifications() {
    final user = _auth.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return _notifications(user.uid)
        .orderBy(
          'createdAt',
          descending: true,
        )
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(AppNotification.fromFirestore)
              .toList(),
        );
  }

  // ============================================================
  // UNREAD NOTIFICATION COUNT
  // ============================================================

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

  // ============================================================
  // LIKE ACTIVITIES
  //
  // Includes:
  // type = like
  // type = unlike
  // ============================================================

  static Stream<
      List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      getLikeActivities() {
    final user = _auth.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return _notifications(user.uid)
        .where(
          'type',
          whereIn: [
            'like',
            'unlike',
          ],
        )
        .orderBy(
          'createdAt',
          descending: true,
        )
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs,
        );
  }

  // ============================================================
  // LIKE ACTIVITY UNREAD COUNT
  // ============================================================

  static Stream<int> getLikeActivitiesUnreadCount() {
    final user = _auth.currentUser;

    if (user == null) {
      return Stream.value(0);
    }

    return _notifications(user.uid)
        .where(
          'type',
          whereIn: [
            'like',
            'unlike',
          ],
        )
        .where(
          'isRead',
          isEqualTo: false,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.length,
        );
  }

  // ============================================================
  // CREATE NOTIFICATION
  // ============================================================

  static Future<void> createNotification({
    required String receiverUserId,
    required String type,
    required String message,
    String fromUsername = '',
    String fromUserPhotoUrl = '',
    String postId = '',
    String chatId = '',
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'User is not logged in.',
      );
    }

    final receiverId =
        receiverUserId.trim();

    if (receiverId.isEmpty) {
      throw Exception(
        'Notification receiver UID is empty.',
      );
    }

    if (receiverId == user.uid) {
      return;
    }

    final notificationRef =
        _notifications(receiverId).doc();

    await notificationRef.set({
      'type': type,
      'fromUserId': user.uid,
      'fromUsername': fromUsername,
      'fromUserPhotoUrl': fromUserPhotoUrl,
      'postId': postId,
      'chatId': chatId,
      'message': message,
      'isRead': false,
      'createdAt':
          FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // MARK LIKE ACTIVITIES AS READ
  // ============================================================

  static Future<void>
      markLikeActivitiesAsRead() async {
    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    final snapshot =
        await _notifications(user.uid)
            .where(
              'type',
              whereIn: [
                'like',
                'unlike',
              ],
            )
            .where(
              'isRead',
              isEqualTo: false,
            )
            .get();

    if (snapshot.docs.isEmpty) {
      return;
    }

    final batch =
        _firestore.batch();

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

  // ============================================================
  // MESSAGE NOTIFICATION
  // ============================================================

  static Future<void>
      createMessageNotification({
    required String receiverUserId,
    required String chatId,
    required String message,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'User is not logged in.',
      );
    }

    final senderSnapshot =
        await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

    final senderData =
        senderSnapshot.data() ?? {};

    final username =
        senderData['username']
                ?.toString()
                .trim() ??
            '';

    final name =
        senderData['name']
                ?.toString()
                .trim() ??
            '';

    final photoUrl =
        senderData['photoUrl']
                ?.toString()
                .trim() ??
            '';

    final senderLabel =
        username.isNotEmpty
            ? username
            : name.isNotEmpty
                ? name
                : 'Someone';

    final trimmedMessage =
        message.trim();

    final preview =
        trimmedMessage.length > 80
            ? '${trimmedMessage.substring(0, 80)}…'
            : trimmedMessage;

    await createNotification(
      receiverUserId:
          receiverUserId,
      type: 'message',
      message:
          '$senderLabel: $preview',
      fromUsername:
          username,
      fromUserPhotoUrl:
          photoUrl,
      chatId: chatId,
    );
  }

  // ============================================================
  // MARK CHAT NOTIFICATIONS AS READ
  // ============================================================

  static Future<void>
      markChatNotificationsAsRead(
    String chatId,
  ) async {
    final user = _auth.currentUser;

    if (user == null ||
        chatId.trim().isEmpty) {
      return;
    }

    final snapshot =
        await _notifications(user.uid)
            .where(
              'chatId',
              isEqualTo: chatId,
            )
            .get();

    final unreadDocs =
        snapshot.docs.where(
      (doc) =>
          doc.data()['isRead'] != true,
    );

    final batch =
        _firestore.batch();

    var count = 0;

    for (final doc in unreadDocs) {
      batch.update(
        doc.reference,
        {
          'isRead': true,
        },
      );
      count++;
    }

    if (count > 0) {
      await batch.commit();
    }
  }

  // ============================================================
  // TEST NOTIFICATION
  // ============================================================

  static Future<void>
      createTestNotification() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'User is not logged in.',
      );
    }

    final notificationRef =
        _notifications(user.uid).doc();

    await notificationRef.set({
      'type': 'system',
      'fromUserId': user.uid,
      'fromUsername': 'GAPSHAP',
      'fromUserPhotoUrl': '',
      'postId': '',
      'chatId': '',
      'message':
          'GAPSHAP notification test successful',
      'isRead': false,
      'createdAt':
          FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // MARK ONE AS READ
  // ============================================================

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

  // ============================================================
  // MARK ALL AS READ
  // ============================================================

  static Future<void> markAllAsRead() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'User is not logged in.',
      );
    }

    final snapshot =
        await _notifications(user.uid)
            .where(
              'isRead',
              isEqualTo: false,
            )
            .get();

    if (snapshot.docs.isEmpty) {
      return;
    }

    final batch =
        _firestore.batch();

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

  // ============================================================
  // DELETE NOTIFICATION
  // ============================================================

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
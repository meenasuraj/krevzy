import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // 1. Notifications initialize करने के लिए (Instance method)
  Future<void> initNotifications() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission for notifications');
    }

    final fcmToken = await _firebaseMessaging.getToken();
    debugPrint('FCM Token: $fcmToken');

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      if (message.notification != null) {
        debugPrint('Message notification title: ${message.notification?.title}');
      }
    });
  }

  // 2. Firestore में इन-ऐप नोटिफिकेशन सेव करने के लिए (Static method ताकि follow_service और post_service सीधे कॉल कर सकें)
  static Future<void> createNotification({
    String? receiverUserId,
    String? receiverId,
    String? senderId,
    String? fromUsername,
    String? fromUserPhotoUrl,
    String? type,
    String? message,
    String? postId,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'receiverId': receiverUserId ?? receiverId ?? '',
        'senderId': senderId ?? '',
        'fromUsername': fromUsername ?? '',
        'fromUserPhotoUrl': fromUserPhotoUrl ?? '',
        'type': type ?? 'general',
        'message': message ?? '',
        'postId': postId,
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error creating notification: $e');
    }
  }
}
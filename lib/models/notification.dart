import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String type;
  final String fromUserId;
  final String fromUsername;
  final String fromUserPhotoUrl;
  final String postId;
  final String chatId;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.fromUserId,
    required this.fromUsername,
    required this.fromUserPhotoUrl,
    required this.postId,
    required this.chatId,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};
    final timestamp = data['createdAt'];

    return AppNotification(
      id: document.id,
      type: data['type']?.toString() ?? '',
      fromUserId: data['fromUserId']?.toString() ?? '',
      fromUsername: data['fromUsername']?.toString() ?? '',
      fromUserPhotoUrl: data['fromUserPhotoUrl']?.toString() ?? '',
      postId: data['postId']?.toString() ?? '',
      chatId: data['chatId']?.toString() ?? '',
      message: data['message']?.toString() ?? '',
      isRead: data['isRead'] == true,
      createdAt: timestamp is Timestamp
          ? timestamp.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

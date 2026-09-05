import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String userId;
  final String username;
  final String userName;
  final String userPhotoUrl;
  final String caption;
  final String mediaUrl;
  final String mediaType;
  final int likesCount;
  final int commentsCount;
  final DateTime createdAt;

  const Post({
    required this.id,
    required this.userId,
    required this.username,
    required this.userName,
    required this.userPhotoUrl,
    required this.caption,
    required this.mediaUrl,
    required this.mediaType,
    required this.likesCount,
    required this.commentsCount,
    required this.createdAt,
  });

  factory Post.fromFirestore(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data() ?? {};

    final timestamp = data['createdAt'];

    return Post(
      id: document.id,
      userId: data['userId']?.toString() ?? '',
      username: data['username']?.toString() ?? '',
      userName: data['userName']?.toString() ?? '',
      userPhotoUrl: data['userPhotoUrl']?.toString() ?? '',
      caption: data['caption']?.toString() ?? '',
      mediaUrl: data['mediaUrl']?.toString() ?? '',
      mediaType: data['mediaType']?.toString() ?? 'image',
      likesCount: (data['likesCount'] as num?)?.toInt() ?? 0,
      commentsCount: (data['commentsCount'] as num?)?.toInt() ?? 0,
      createdAt: timestamp is Timestamp
          ? timestamp.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'username': username,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'caption': caption,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

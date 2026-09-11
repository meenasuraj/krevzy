import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream posts in real time from Firestore
  Stream<List<Map<String, dynamic>>> getPostsStream() {
    try {
      return _db
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'type': data['type'] ?? 'post',
            'name': data['name'] ?? 'Creator',
            'handle': data['handle'] ?? '@creator',
            'category': data['category'] ?? 'General',
            'content': data['content'] ?? '',
            'audio': data['audio'] ?? '',
            'likes': data['likes'] ?? 0,
            'comments': data['comments'] ?? 0,
            'hasMedia': data['hasMedia'] ?? false,
            'time': 'Just now',
          };
        }).toList();
      });
    } catch (e) {
      debugPrint('Error streaming posts: $e');
      return const Stream.empty();
    }
  }

  // Add a new post or reel to Firestore
  Future<void> createPost({
    required String type,
    required String name,
    required String handle,
    required String category,
    required String content,
    String? audio,
    bool hasMedia = false,
  }) async {
    try {
      await _db.collection('posts').add({
        'type': type,
        'name': name,
        'handle': handle,
        'category': category,
        'content': content,
        'audio': audio ?? '',
        'likes': 0,
        'comments': 0,
        'hasMedia': hasMedia,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error creating post in Firestore: $e');
    }
  }

  // Increment like count on a post
  Future<void> likePost(String postId, int currentLikes) async {
    try {
      await _db.collection('posts').doc(postId).update({
        'likes': currentLikes + 1,
      });
    } catch (e) {
      debugPrint('Error updating likes: $e');
    }
  }
}
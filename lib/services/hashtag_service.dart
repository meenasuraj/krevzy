import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/post.dart';

class HashtagService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static List<String> extractHashtags(String text) {
    final matches = RegExp(r'(?<![A-Za-z0-9_])#([A-Za-z0-9_]{1,50})')
        .allMatches(text);

    final result = <String>{};
    for (final match in matches) {
      final tag = match.group(1)?.trim().toLowerCase();
      if (tag != null && tag.isNotEmpty) {
        result.add(tag);
      }
    }
    return result.toList();
  }

  static Future<List<Post>> getPostsForHashtag(String hashtag) async {
    final clean = hashtag.replaceFirst('#', '').trim().toLowerCase();
    if (clean.isEmpty) return [];

    final snapshot = await _firestore
        .collection('posts')
        .where('hashtags', arrayContains: clean)
        .limit(100)
        .get();

    final posts = snapshot.docs.map(Post.fromFirestore).toList();
    posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return posts;
  }

  static Stream<List<Post>> trendingPosts({int limit = 60}) {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Post.fromFirestore).toList());
  }

  static Map<String, int> countHashtags(Iterable<Post> posts) {
    final counts = <String, int>{};
    for (final post in posts) {
      for (final tag in post.hashtags) {
        counts[tag] = (counts[tag] ?? 0) + 1;
      }
    }
    return counts;
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/post.dart';
import '../services/post_actions_service.dart';
import '../services/post_service.dart';
import '../widgets/post_card.dart';

class SavedPostsScreen extends StatelessWidget {
  const SavedPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text('Not signed in')));
    return Scaffold(
      appBar: AppBar(title: const Text('Saved posts')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: PostActionsService.savedPosts(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Unable to load saved posts.\n${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = [...snapshot.data!.docs];
          docs.sort((a, b) {
            final at = a.data()['savedAt'];
            final bt = b.data()['savedAt'];
            if (at is Timestamp && bt is Timestamp) return bt.compareTo(at);
            if (at is Timestamp) return -1;
            if (bt is Timestamp) return 1;
            return 0;
          });
          if (docs.isEmpty) return const Center(child: Text('No saved posts yet.'));
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _SavedPost(postId: docs[index].id),
          );
        },
      ),
    );
  }
}

class _SavedPost extends StatelessWidget {
  final String postId;
  const _SavedPost({required this.postId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Post?>(
      future: PostService.getPost(postId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
        }
        final post = snapshot.data;
        if (post == null) {
          return ListTile(
            title: const Text('Post no longer available'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => PostActionsService.removeSaved(postId),
            ),
          );
        }
        return PostCard(post: post);
      },
    );
  }
}

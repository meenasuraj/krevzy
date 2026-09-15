import 'package:flutter/material.dart';

import '../models/post.dart';
import '../services/hashtag_service.dart';
import '../widgets/post_card.dart';

class HashtagScreen extends StatelessWidget {
  final String hashtag;

  const HashtagScreen({super.key, required this.hashtag});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tag = hashtag.replaceFirst('#', '').trim().toLowerCase();

    return Scaffold(
      appBar: AppBar(
        title: Text('#$tag'),
      ),
      body: FutureBuilder<List<Post>>(
        future: HashtagService.getPostsForHashtag(tag),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load this hashtag.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            );
          }

          final posts = snapshot.data ?? const <Post>[];
          if (posts.isEmpty) {
            return Center(
              child: Text(
                'No posts found for #$tag',
                style: theme.textTheme.bodyLarge,
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {},
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              itemCount: posts.length,
              itemBuilder: (context, index) => PostCard(post: posts[index]),
            ),
          );
        },
      ),
    );
  }
}

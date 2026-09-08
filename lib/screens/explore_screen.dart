import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/post.dart';
import '../services/follow_service.dart';
import '../services/hashtag_service.dart';
import '../widgets/post_card.dart';
import 'hashtag_screen.dart';
import 'user_profile_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';
  bool _searching = false;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _users = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    final text = value.trim();
    setState(() => _query = text);
    if (text.isEmpty) {
      setState(() {
        _users = [];
        _searching = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _searchUsers(text);
    });
  }

  Future<void> _searchUsers(String text) async {
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) return;
    setState(() => _searching = true);
    try {
      final q = text.toLowerCase();
      final username = await FirebaseFirestore.instance
          .collection('users')
          .where('usernameLowercase', isGreaterThanOrEqualTo: q)
          .where('usernameLowercase', isLessThanOrEqualTo: '$q\uf8ff')
          .limit(30)
          .get();
      final names = await FirebaseFirestore.instance
          .collection('users')
          .where('nameLowercase', isGreaterThanOrEqualTo: q)
          .where('nameLowercase', isLessThanOrEqualTo: '$q\uf8ff')
          .limit(30)
          .get();
      final unique = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
      for (final doc in [...username.docs, ...names.docs]) {
        if (doc.id != current.uid) unique[doc.id] = doc;
      }
      if (!mounted) return;
      setState(() {
        _users = unique.values.toList();
        _searching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _users = [];
        _searching = false;
      });
    }
  }

  void _openUser(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(
          userId: doc.id,
          name: data['name']?.toString() ?? '',
          username: data['username']?.toString() ?? '',
          bio: data['bio']?.toString() ?? '',
          photoUrl: data['photoUrl']?.toString() ?? '',
          postsCount: _toInt(data['postsCount']),
          followersCount: _toInt(data['followersCount']),
          followingCount: _toInt(data['followingCount']),
        ),
      ),
    );
  }

  int _toInt(dynamic value) => value is num ? value.toInt() : int.tryParse('$value') ?? 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primary, cs.secondary],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.explore_rounded, color: cs.onPrimary),
            ),
            const SizedBox(width: 11),
            const Text('Explore'),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'For You'),
            Tab(text: 'People'),
            Tab(text: 'Hashtags'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ForYouTab(onHashtag: _openHashtag),
          _PeopleTab(
            controller: _searchController,
            query: _query,
            searching: _searching,
            users: _users,
            onChanged: _onSearchChanged,
            onUser: _openUser,
          ),
          const _HashtagsTab(),
        ],
      ),
    );
  }

  void _openHashtag(String tag) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => HashtagScreen(hashtag: tag)),
    );
  }
}

class _ForYouTab extends StatelessWidget {
  final void Function(String) onHashtag;
  const _ForYouTab({required this.onHashtag});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Post>>(
      stream: HashtagService.trendingPosts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Could not load Explore.'));
        }
        final posts = snapshot.data ?? const <Post>[];
        if (posts.isEmpty) {
          return const Center(child: Text('No posts yet. Be the first to post!'));
        }
        final counts = HashtagService.countHashtags(posts);
        final tags = counts.keys.toList()
          ..sort((a, b) => (counts[b] ?? 0).compareTo(counts[a] ?? 0));

        return RefreshIndicator(
          onRefresh: () async {},
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            children: [
              if (tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                  child: SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: tags.take(10).length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final tag = tags[index];
                        return ActionChip(
                          label: Text('#$tag'),
                          onPressed: () => onHashtag(tag),
                        );
                      },
                    ),
                  ),
                ),
              ...posts.map((post) => PostCard(post: post)),
            ],
          ),
        );
      },
    );
  }
}

class _PeopleTab extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final bool searching;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> users;
  final ValueChanged<String> onChanged;
  final void Function(QueryDocumentSnapshot<Map<String, dynamic>>) onUser;

  const _PeopleTab({
    required this.controller,
    required this.query,
    required this.searching,
    required this.users,
    required this.onChanged,
    required this.onUser,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: 'Search people...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        controller.clear();
                        onChanged('');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: cs.surfaceContainerHighest.withValues(alpha: .55),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        if (searching) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: users.isEmpty
              ? Center(
                  child: Text(
                    query.isEmpty ? 'Search for people' : 'No people found',
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: users.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final data = users[index].data();
                    final photo = data['photoUrl']?.toString() ?? '';
                    final username = data['username']?.toString() ?? '';
                    final name = data['name']?.toString() ?? '';
                    return Card(
                      child: ListTile(
                        onTap: () => onUser(users[index]),
                        leading: CircleAvatar(
                          backgroundImage: photo.isEmpty ? null : NetworkImage(photo),
                          child: photo.isEmpty
                              ? Text((name.isNotEmpty ? name : username).isNotEmpty
                                  ? (name.isNotEmpty ? name : username)[0].toUpperCase()
                                  : '?')
                              : null,
                        ),
                        title: Text(name.isNotEmpty ? name : username),
                        subtitle: username.isNotEmpty ? Text('@$username') : null,
                        trailing: _FollowButton(
                          userId: users[index].id,
                          username: username,
                          name: name,
                          photoUrl: photo,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _FollowButton extends StatelessWidget {
  final String userId;
  final String username;
  final String name;
  final String photoUrl;

  const _FollowButton({
    required this.userId,
    required this.username,
    required this.name,
    required this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: FollowService.followingStream(userId),
      builder: (context, snapshot) {
        final following = snapshot.data ?? false;
        return FilledButton.tonal(
          onPressed: () async {
            try {
              if (following) {
                await FollowService.unfollow(userId);
              } else {
                await FollowService.follow(
                  targetUserId: userId,
                  targetUsername: username,
                  targetName: name,
                  targetPhotoUrl: photoUrl,
                );
              }
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Could not update follow: $e')),
              );
            }
          },
          child: Text(following ? 'Following' : 'Follow'),
        );
      },
    );
  }
}

class _HashtagsTab extends StatelessWidget {
  const _HashtagsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Post>>(
      stream: HashtagService.trendingPosts(limit: 100),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final counts = HashtagService.countHashtags(snapshot.data ?? const <Post>[]);
        final tags = counts.keys.toList()
          ..sort((a, b) => (counts[b] ?? 0).compareTo(counts[a] ?? 0));
        if (tags.isEmpty) {
          return const Center(child: Text('No hashtags yet'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: tags.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final tag = tags[index];
            return Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.tag_rounded)),
                title: Text('#$tag', style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text('${counts[tag]} recent post${counts[tag] == 1 ? '' : 's'}'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => HashtagScreen(hashtag: tag)),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

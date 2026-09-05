import 'package:flutter/material.dart';

import '../models/post.dart';
import '../services/notification_service.dart';
import '../services/post_service.dart';
import '../widgets/post_card.dart';
import 'chats_screen.dart';
import 'create_post_screen.dart';
import 'like_activities_screen.dart';
import 'notes_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'security_center_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _pages = [
      const _HomeTab(),
      const SearchScreen(),
      const CreatePostScreen(),
      const ChatsScreen(),
      const ProfileScreen(),
    ];
  }

  void _onNavigationChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const NotificationsScreen(),
      ),
    );
  }

  void _openNotes() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const NotesScreen(),
      ),
    );
  }

  void _openLikeActivities() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const LikeActivitiesScreen(),
      ),
    );
  }

  void _openSecurityCenter() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SecurityCenterScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'GAPSHAP',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Personal Notes',
            onPressed: _openNotes,
            icon: const Icon(
              Icons.note_alt_outlined,
            ),
          ),

          IconButton(
            tooltip: 'Like Activities',
            onPressed: _openLikeActivities,
            icon: const Icon(
              Icons.favorite_border_rounded,
            ),
          ),

          StreamBuilder<int>(
            stream: NotificationService.getUnreadCount(),
            builder: (context, snapshot) {
              final unreadCount =
                  snapshot.data ?? 0;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    tooltip: unreadCount > 0
                        ? '$unreadCount unread notifications'
                        : 'Notifications',
                    onPressed: _openNotifications,
                    icon: Icon(
                      unreadCount > 0
                          ? Icons.notifications_rounded
                          : Icons
                              .notifications_none_rounded,
                    ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 5,
                      top: 5,
                      child: Container(
                        constraints:
                            const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .error,
                          borderRadius:
                              BorderRadius.circular(
                            10,
                          ),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .surface,
                            width: 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          unreadCount > 99
                              ? '99+'
                              : unreadCount.toString(),
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onError,
                            fontSize: 10,
                            fontWeight:
                                FontWeight.bold,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          IconButton(
            tooltip: 'Security Center',
            onPressed: _openSecurityCenter,
            icon: const Icon(
              Icons.shield_outlined,
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected:
            _onNavigationChanged,
        destinations: const [
          NavigationDestination(
            icon: Icon(
              Icons.home_outlined,
            ),
            selectedIcon: Icon(
              Icons.home_rounded,
            ),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.search_outlined,
            ),
            selectedIcon: Icon(
              Icons.search_rounded,
            ),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.add_box_outlined,
            ),
            selectedIcon: Icon(
              Icons.add_box_rounded,
            ),
            label: 'Create',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.chat_bubble_outline_rounded,
            ),
            selectedIcon: Icon(
              Icons.chat_bubble_rounded,
            ),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.person_outline_rounded,
            ),
            selectedIcon: Icon(
              Icons.person_rounded,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HOME TAB
// ============================================================

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await Future<void>.delayed(
          const Duration(
            milliseconds: 500,
          ),
        );
      },
      child: CustomScrollView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(
            child: _StoriesSection(),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                18,
                16,
                8,
              ),
              child: Text(
                'Latest Posts',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(
                      fontWeight:
                          FontWeight.bold,
                    ),
              ),
            ),
          ),
          const _RealPostsFeed(),
        ],
      ),
    );
  }
}

// ============================================================
// STORIES
// ============================================================

class _StoriesSection extends StatelessWidget {
  const _StoriesSection();

  @override
  Widget build(BuildContext context) {
    final stories = [
      ('Your Story', Icons.add),
      ('Friends', Icons.person),
      ('Explore', Icons.explore),
      ('Popular', Icons.trending_up),
    ];

    return SizedBox(
      height: 108,
      child: ListView.separated(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: stories.length,
        separatorBuilder: (_, _) =>
            const SizedBox(width: 18),
        itemBuilder: (context, index) {
          final story = stories[index];

          return SizedBox(
            width: 68,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 30,
                  child: Icon(
                    story.$2,
                    size: 28,
                  ),
                ),
                const SizedBox(
                  height: 7,
                ),
                Text(
                  story.$1,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// REAL FIRESTORE POSTS FEED
// ============================================================

class _RealPostsFeed
    extends StatelessWidget {
  const _RealPostsFeed();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Post>>(
      stream: PostService.getPosts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child:
                  CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(24),
                child: Text(
                  'Posts load nahi ho sake.\n\n'
                  '${snapshot.error}',
                  textAlign:
                      TextAlign.center,
                ),
              ),
            ),
          );
        }

        final posts =
            snapshot.data ?? [];

        if (posts.isEmpty) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  Icon(
                    Icons
                        .dynamic_feed_outlined,
                    size: 64,
                  ),
                  SizedBox(
                    height: 12,
                  ),
                  Text(
                    'No posts yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  SizedBox(
                    height: 6,
                  ),
                  Text(
                    'Create the first GAPSHAP post.',
                  ),
                ],
              ),
            ),
          );
        }

        return SliverList(
          delegate:
              SliverChildBuilderDelegate(
            (context, index) {
              final post =
                  posts[index];

              return PostCard(
                key: ValueKey(
                  post.id,
                ),
                post: post,
              );
            },
            childCount: posts.length,
          ),
        );
      },
    );
  }
}
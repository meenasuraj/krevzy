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
import 'explore_screen.dart';
import 'security_center_screen.dart';
import 'rooms_screen.dart';

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
      const ExploreScreen(),
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
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
  }

  void _openNotes() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const NotesScreen()));
  }

  void _openLikeActivities() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const LikeActivitiesScreen()));
  }

  void _openSecurityCenter() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const SecurityCenterScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFFF8F7FF),
        centerTitle: false,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.forum_rounded,
                color: colorScheme.onPrimary,
                size: 21,
              ),
            ),
            const SizedBox(width: 11),
            Text(
              'KREVZY',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          StreamBuilder<int>(
            stream: NotificationService.getUnreadCount(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              return _NotificationActionButton(
                unreadCount: unreadCount,
                onPressed: _openNotifications,
              );
            },
          ),
          PopupMenuButton<String>(
            tooltip: 'More',
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              switch (value) {
                case 'notes':
                  _openNotes();
                  break;
                case 'likes':
                  _openLikeActivities();
                  break;
                case 'rooms':
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RoomsScreen()),
                  );
                  break;
                case 'security':
                  _openSecurityCenter();
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'notes',
                child: Text('Personal Notes'),
              ),
              PopupMenuItem<String>(
                value: 'likes',
                child: Text('Like Activities'),
              ),
              PopupMenuItem<String>(value: 'rooms', child: Text('Rooms')),
              PopupMenuItem<String>(
                value: 'security',
                child: Text('Security Center'),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        height: 76,
        elevation: 0,
        backgroundColor: const Color(0xFFF8F7FF),
        indicatorColor: colorScheme.primaryContainer,
        selectedIndex: _currentIndex,
        onDestinationSelected: _onNavigationChanged,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.explore_rounded),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline_rounded),
            selectedIcon: Icon(Icons.add_circle_rounded),
            label: 'Create',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// NOTIFICATION ACTION BUTTON
// ============================================================

class _NotificationActionButton extends StatelessWidget {
  const _NotificationActionButton({
    required this.unreadCount,
    required this.onPressed,
  });

  final int unreadCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            tooltip: unreadCount > 0
                ? '$unreadCount unread notifications'
                : 'Notifications',
            onPressed: onPressed,
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.55,
              ),
              foregroundColor: colorScheme.onSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            icon: Icon(
              unreadCount > 0
                  ? Icons.notifications_rounded
                  : Icons.notifications_none_rounded,
              size: 21,
            ),
          ),
          if (unreadCount > 0)
            Positioned(
              right: -1,
              top: -2,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: colorScheme.error,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colorScheme.surface, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  unreadCount > 99 ? '99+' : '$unreadCount',
                  style: TextStyle(
                    color: colorScheme.onError,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
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
        await Future<void>.delayed(const Duration(milliseconds: 500));
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: _WelcomeHeader()),
          const SliverToBoxAdapter(child: _StoriesSection()),
          SliverToBoxAdapter(
            child: _SectionHeader(
              title: 'Latest Posts',
              subtitle: 'See what people are sharing',
            ),
          ),
          const _RealPostsFeed(),
        ],
      ),
    );
  }
}

// ============================================================
// WELCOME HEADER
// ============================================================

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primaryContainer,
              colorScheme.secondaryContainer,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.75),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.waving_hand_rounded,
                color: colorScheme.primary,
                size: 25,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome to KREVZY',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Share, connect and keep the conversation going.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SECTION HEADER
// ============================================================

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(subtitle, style: theme.textTheme.bodySmall),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final stories = [
      ('Your Story', Icons.add_rounded, colorScheme.primary),
      ('Friends', Icons.people_alt_outlined, colorScheme.secondary),
      ('Explore', Icons.explore_outlined, colorScheme.tertiary),
      ('Popular', Icons.trending_up_rounded, colorScheme.primary),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        height: 116,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          scrollDirection: Axis.horizontal,
          itemCount: stories.length,
          separatorBuilder: (_, _) => const SizedBox(width: 14),
          itemBuilder: (context, index) {
            final story = stories[index];

            return SizedBox(
              width: 78,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [story.$3, colorScheme.secondary],
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 29,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        child: Icon(story.$2, size: 25, color: story.$3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    story.$1,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ============================================================
// REAL FIRESTORE POSTS FEED
// ============================================================

class _RealPostsFeed extends StatelessWidget {
  const _RealPostsFeed();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Post>>(
      stream: PostService.getPosts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cloud_off_rounded,
                        size: 46,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Posts load nahi ho sake.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onErrorContainer,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        final posts = snapshot.data ?? [];

        if (posts.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 30,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.dynamic_feed_rounded,
                          size: 38,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No posts yet',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Create the first KREVZY post.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final post = posts[index];

            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: PostCard(key: ValueKey(post.id), post: post),
            );
          }, childCount: posts.length),
        );
      },
    );
  }
}

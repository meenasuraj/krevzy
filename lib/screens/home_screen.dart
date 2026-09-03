import 'package:flutter/material.dart';

import 'chats_screen.dart';
import 'profile_screen.dart';

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
      const _SearchTab(),
      const _CreateTab(),
      const ChatsScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentIndex == 4
          ? null
          : AppBar(
              title: const Text(
                'Gapshap',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              centerTitle: false,
              actions: [
                IconButton(
                  onPressed: () {
                    _showComingSoon('Likes');
                  },
                  icon: const Icon(Icons.favorite_border),
                ),
                IconButton(
                  onPressed: () {
                    _showComingSoon('Notifications');
                  },
                  icon: const Icon(Icons.notifications_none),
                ),
              ],
            ),

      body: IndexedStack(index: _currentIndex, children: _pages),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,

        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },

        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),

          NavigationDestination(
            icon: Icon(Icons.search),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),

          NavigationDestination(
            icon: Icon(Icons.add_box_outlined),
            selectedIcon: Icon(Icons.add_box),
            label: 'Create',
          ),

          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chats',
          ),

          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$feature coming soon')));
  }
}

// ============================================================================
// HOME
// ============================================================================

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Stories',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 15),

        SizedBox(
          height: 95,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const [
              _StoryItem(name: 'Your Story', icon: Icons.add),
              _StoryItem(name: 'Rahul', icon: Icons.person),
              _StoryItem(name: 'Priya', icon: Icons.person),
              _StoryItem(name: 'Aman', icon: Icons.person),
              _StoryItem(name: 'Neha', icon: Icons.person),
            ],
          ),
        ),

        const SizedBox(height: 25),

        const Text(
          'Latest Posts',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 15),

        const _PostCard(username: 'rahul', caption: 'Beautiful day! ☀️'),

        const _PostCard(username: 'priya', caption: 'Gapshap time! 💜'),
      ],
    );
  }
}

// ============================================================================
// STORY
// ============================================================================

class _StoryItem extends StatelessWidget {
  final String name;
  final IconData icon;

  const _StoryItem({required this.name, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 75,
      margin: const EdgeInsets.only(right: 14),
      child: Column(
        children: [
          CircleAvatar(radius: 30, child: Icon(icon)),

          const SizedBox(height: 6),

          Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ============================================================================
// POST
// ============================================================================

class _PostCard extends StatelessWidget {
  final String username;
  final String caption;

  const _PostCard({required this.username, required this.caption});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      clipBehavior: Clip.antiAlias,

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),

            title: Text(
              username,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            trailing: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.more_vert),
            ),
          ),

          Container(
            height: 260,
            width: double.infinity,
            color: Colors.grey.shade200,
            child: const Icon(Icons.image_outlined, size: 70),
          ),

          Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.favorite_border),
              ),

              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.chat_bubble_outline),
              ),

              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.send_outlined),
              ),

              const Spacer(),

              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.bookmark_border),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(caption, style: const TextStyle(fontSize: 15)),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SEARCH
// ============================================================================

class _SearchTab extends StatelessWidget {
  const _SearchTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Search 🔍',
        style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ============================================================================
// CREATE
// ============================================================================

class _CreateTab extends StatelessWidget {
  const _CreateTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Create Post ➕',
        style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
      ),
    );
  }
}

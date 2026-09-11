import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../utils/app_theme_data.dart';
import 'creator_studio_hub_screen.dart';
import 'explore_search_screen.dart';
import 'feed_screen.dart';
import 'messages_hub_screen.dart';
import 'user_profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final themeNotifier = AppThemeNotifier.instance;

    return AnimatedBuilder(
      animation: themeNotifier,
      builder: (context, child) {
        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: [
              const FeedScreen(),
              const ExploreSearchScreen(),
              const CreatorStudioHubScreen(),
              const MessagesHubScreen(),
              _buildProfileScreen(),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: themeNotifier.isDarkMode
                ? const Color(0xFF1F1F1F)
                : Colors.white,
            selectedItemColor: themeNotifier.primaryColor,
            unselectedItemColor: Colors.grey,
            selectedFontSize: 11,
            unselectedFontSize: 11,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_filled),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search),
                label: 'Explore',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.add_circle, size: 30),
                label: 'Studio',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_rounded),
                label: 'Chats',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileScreen() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view your profile.')),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data?.data() ?? <String, dynamic>{};

        final name =
            (data['name'] ?? data['displayName'] ?? user.displayName ?? '')
                .toString();

        final username = (data['username'] ?? data['userName'] ?? '')
            .toString();

        final bio = (data['bio'] ?? '').toString();

        final photoUrl =
            (data['photoUrl'] ?? data['photoURL'] ?? user.photoURL ?? '')
                .toString();

        final postsCount = _readInt(data['postsCount']);

        final followersCount = _readInt(data['followersCount']);

        final followingCount = _readInt(data['followingCount']);

        return UserProfileScreen(
          userId: user.uid,
          name: name,
          username: username,
          bio: bio,
          photoUrl: photoUrl,
          postsCount: postsCount,
          followersCount: followersCount,
          followingCount: followingCount,
        );
      },
    );
  }

  int _readInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

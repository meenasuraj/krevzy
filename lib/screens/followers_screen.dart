import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/follow_service.dart';
import 'public_profile_screen.dart';

class FollowersScreen extends StatelessWidget {
  final String userId;
  final String title;

  const FollowersScreen({
    super.key,
    required this.userId,
    this.title = 'Followers',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: StreamBuilder<
          List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
        stream: FollowService.followersStream(userId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Unable to load followers.'),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final followers = snapshot.data ?? [];

          if (followers.isEmpty) {
            return const Center(
              child: Text(
                'No followers yet.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.separated(
            itemCount: followers.length,
            separatorBuilder: (context, index) {
              return const Divider(height: 1);
            },
            itemBuilder: (context, index) {
              final follower = followers[index].data();

              final followerId =
                  follower['userId']?.toString() ??
                      followers[index].id;

              final name =
                  follower['name']?.toString() ?? '';

              final username =
                  follower['username']?.toString() ?? '';

              final photoUrl =
                  follower['photoUrl']?.toString() ?? '';

              return _FollowerTile(
                userId: followerId,
                name: name,
                username: username,
                photoUrl: photoUrl,
              );
            },
          );
        },
      ),
    );
  }
}

class _FollowerTile extends StatelessWidget {
  final String userId;
  final String name;
  final String username;
  final String photoUrl;

  const _FollowerTile({
    required this.userId,
    required this.name,
    required this.username,
    required this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser =
        FirebaseAuth.instance.currentUser;

    final isCurrentUser =
        currentUser != null &&
        currentUser.uid == userId;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 6,
      ),
      leading: CircleAvatar(
        radius: 25,
        backgroundImage: photoUrl.isNotEmpty
            ? NetworkImage(photoUrl)
            : null,
        child: photoUrl.isEmpty
            ? Text(
                _initials(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
      title: Text(
        name.isNotEmpty ? name : username,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: username.isNotEmpty
          ? Text('@$username')
          : null,
      onTap: isCurrentUser
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      PublicProfileScreen(
                    userId: userId,
                  ),
                ),
              );
            },
      trailing: isCurrentUser
          ? null
          : StreamBuilder<bool>(
              stream:
                  FollowService.followingStream(
                userId,
              ),
              builder: (context, snapshot) {
                final following =
                    snapshot.data ?? false;

                return OutlinedButton(
                  onPressed: () async {
                    try {
                      if (following) {
                        await FollowService.unfollow(
                          userId,
                        );
                      } else {
                        await FollowService.follow(
                          targetUserId: userId,
                          targetUsername: username,
                          targetName: name,
                          targetPhotoUrl: photoUrl,
                        );
                      }
                    } catch (e) {
                      if (!context.mounted) {
                        return;
                      }

                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                            'Action failed: $e',
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(
                    following
                        ? 'Following'
                        : 'Follow',
                  ),
                );
              },
            ),
    );
  }

  String _initials() {
    final value =
        name.isNotEmpty ? name : username;

    if (value.isEmpty) {
      return '?';
    }

    final parts =
        value.trim().split(RegExp(r'\s+'));

    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'
          .toUpperCase();
    }

    return value[0].toUpperCase();
  }
}
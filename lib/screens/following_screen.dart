import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/follow_service.dart';
import 'public_profile_screen.dart';

class FollowingScreen extends StatelessWidget {
  final String userId;
  final String title;

  const FollowingScreen({
    super.key,
    required this.userId,
    this.title = 'Following',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: StreamBuilder<
          List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
        stream:
            FollowService.followingUsersStream(userId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Unable to load following list.',
              ),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final followingUsers =
              snapshot.data ?? [];

          if (followingUsers.isEmpty) {
            return const Center(
              child: Text(
                'Not following anyone yet.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.separated(
            itemCount: followingUsers.length,
            separatorBuilder: (context, index) {
              return const Divider(height: 1);
            },
            itemBuilder: (context, index) {
              final following =
                  followingUsers[index].data();

              final followingId =
                  following['userId']?.toString() ??
                      followingUsers[index].id;

              final name =
                  following['name']?.toString() ?? '';

              final username =
                  following['username']?.toString() ?? '';

              final photoUrl =
                  following['photoUrl']?.toString() ?? '';

              return _FollowingTile(
                userId: followingId,
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

class _FollowingTile extends StatelessWidget {
  final String userId;
  final String name;
  final String username;
  final String photoUrl;

  const _FollowingTile({
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
          : OutlinedButton(
              onPressed: () async {
                try {
                  await FollowService.unfollow(
                    userId,
                  );
                } catch (e) {
                  if (!context.mounted) {
                    return;
                  }

                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    SnackBar(
                      content: Text(
                        'Unable to unfollow: $e',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Following'),
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
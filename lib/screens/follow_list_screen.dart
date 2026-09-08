import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/follow_service.dart';
import 'user_profile_screen.dart';

class FollowListScreen extends StatelessWidget {
  final String userId;
  final String title;
  final bool showFollowers;

  const FollowListScreen({
    super.key,
    required this.userId,
    required this.title,
    required this.showFollowers,
  });

  Stream<
      List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      _usersStream() {
    if (showFollowers) {
      return FollowService.followersStream(userId);
    }

    return FollowService.followingUsersStream(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<
          List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
        stream: _usersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
                  ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final documents = snapshot.data ?? [];

          if (documents.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    showFollowers
                        ? Icons.people_outline_rounded
                        : Icons.person_add_alt_1,
                    size: 64,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    showFollowers
                        ? 'No followers yet'
                        : 'Not following anyone yet',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(
              vertical: 8,
            ),
            itemCount: documents.length,
            separatorBuilder: (_, _) => const Divider(
              height: 1,
              indent: 82,
            ),
            itemBuilder: (context, index) {
              final document = documents[index];
              final data = document.data();

              final targetUserId =
                  data['userId']?.toString() ??
                      document.id;

              final name =
                  data['name']?.toString() ?? '';

              final username =
                  data['username']?.toString() ?? '';

              final photoUrl =
                  data['photoUrl']?.toString() ?? '';

              final displayName = name.isNotEmpty
                  ? name
                  : username.isNotEmpty
                      ? username
                      : 'GAPSHAP User';

              final firstLetter =
                  displayName[0].toUpperCase();

              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                leading: CircleAvatar(
                  radius: 27,
                  backgroundImage:
                      photoUrl.isNotEmpty
                          ? NetworkImage(photoUrl)
                          : null,
                  child: photoUrl.isEmpty
                      ? Text(
                          firstLetter,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        )
                      : null,
                ),
                title: Text(
                  displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: username.isNotEmpty
                    ? Text('@$username')
                    : null,
                trailing: const Icon(
                  Icons.chevron_right,
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          UserProfileScreen(
                        userId: targetUserId,
                        name: name,
                        username: username,
                        bio: '',
                        photoUrl: photoUrl,
                        postsCount: 0,
                        followersCount: 0,
                        followingCount: 0,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
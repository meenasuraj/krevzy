import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';

import '../services/notification_service.dart';

class LikeActivitiesScreen extends StatefulWidget {
  const LikeActivitiesScreen({super.key});

  @override
  State<LikeActivitiesScreen> createState() =>
      _LikeActivitiesScreenState();
}

class _LikeActivitiesScreenState
    extends State<LikeActivitiesScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markLikeActivitiesAsRead();
    });
  }

  Future<void> _markLikeActivitiesAsRead() async {
    try {
      await NotificationService.markLikeActivitiesAsRead();
    } catch (_) {
      // Activity screen should still work if marking read fails.
    }
  }

  String _formatTime(
    Timestamp? timestamp,
  ) {
    if (timestamp == null) {
      return '';
    }

    final date = timestamp.toDate();
    final now = DateTime.now();

    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}h';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays}d';
    }

    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Like Activities',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<
          List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
        stream: NotificationService.getLikeActivities(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Like activities load nahi ho saki.\n\n'
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final activities = snapshot.data ?? [];

          if (activities.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(
              vertical: 12,
            ),
            itemCount: activities.length,
            separatorBuilder: (_, _) =>
                const Divider(
              height: 1,
              indent: 76,
            ),
            itemBuilder: (context, index) {
              final doc = activities[index];
              final data = doc.data();

              final type =
                  data['type']?.toString() ?? 'like';

              final username =
                  data['fromUsername']
                          ?.toString()
                          .trim() ??
                      '';

              final photoUrl =
                  data['fromUserPhotoUrl']
                          ?.toString()
                          .trim() ??
                      '';

              final message =
                  data['message']?.toString().trim() ??
                      '';

              final isRead =
                  data['isRead'] == true;

              final timestamp =
                  data['createdAt'] as Timestamp?;

              final isUnlike =
                  type == 'unlike';

              return _ActivityTile(
                username: username.isNotEmpty
                    ? username
                    : 'Someone',
                photoUrl: photoUrl,
                message: message.isNotEmpty
                    ? message
                    : isUnlike
                        ? 'unliked your post'
                        : 'liked your post',
                time: _formatTime(timestamp),
                isRead: isRead,
                isUnlike: isUnlike,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                size: 44,
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            const Text(
              'No activity yet',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              'When someone likes your post,\\nit will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final String username;
  final String photoUrl;
  final String message;
  final String time;
  final bool isRead;
  final bool isUnlike;

  const _ActivityTile({
    required this.username,
    required this.photoUrl,
    required this.message,
    required this.time,
    required this.isRead,
    required this.isUnlike,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 13,
      ),
      color: isRead
          ? null
          : colorScheme.primary.withValues(
              alpha: 0.06,
            ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 25,
                backgroundImage: photoUrl.isNotEmpty
                    ? NetworkImage(photoUrl)
                    : null,
                child: photoUrl.isEmpty
                    ? const Icon(
                        Icons.person_rounded,
                      )
                    : null,
              ),
              Positioned(
                right: -4,
                bottom: -3,
                child: Container(
                  width: 23,
                  height: 23,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isUnlike
                        ? colorScheme
                            .surfaceContainerHighest
                        : colorScheme.error,
                    border: Border.all(
                      color: colorScheme.surface,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    isUnlike
                        ? Icons.heart_broken_rounded
                        : Icons.favorite_rounded,
                    size: 13,
                    color: isUnlike
                        ? colorScheme
                            .onSurfaceVariant
                        : colorScheme.onError,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            width: 14,
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context)
                    .style
                    .copyWith(
                      fontSize: 14,
                    ),
                children: [
                  TextSpan(
                    text: username,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: ' $message',
                  ),
                  if (time.isNotEmpty)
                    TextSpan(
                      text: '  $time',
                      style: TextStyle(
                        color: colorScheme
                            .onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (!isRead)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }
}
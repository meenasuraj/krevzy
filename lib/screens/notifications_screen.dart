import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/notification.dart';
import '../models/post.dart';
import '../services/chat_lock_service.dart';
import '../services/chat_service.dart';
import '../services/notification_service.dart';
import '../widgets/post_card.dart';
import 'chat_screen.dart';
import 'public_profile_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  String _timeAgo(DateTime time) {
    final difference = DateTime.now().difference(time);

    if (difference.inSeconds < 60) {
      return 'just now';
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

    return '${time.day}/${time.month}/${time.year}';
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'like':
        return Icons.favorite;
      case 'comment':
        return Icons.comment;
      case 'follow':
        return Icons.person_add;
      case 'message':
        return Icons.chat_bubble_rounded;
      case 'system':
        return Icons.info_outline;
      default:
        return Icons.notifications;
    }
  }

  Future<void> _createTestNotification(BuildContext context) async {
    try {
      await NotificationService.createTestNotification();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test notification created successfully')),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Test notification error: $e')));
    }
  }

  Future<void> _markAllRead(BuildContext context) async {
    try {
      await NotificationService.markAllAsRead();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications marked as read')),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _openNotification(
    BuildContext context,
    AppNotification notification,
  ) async {
    // Mark read first, but don't block navigation if this write fails.
    try {
      await NotificationService.markAsRead(notification.id);
    } catch (e) {
      debugPrint('Notification read update failed: $e');
    }

    if (!context.mounted) return;

    switch (notification.type) {
      case 'message':
        await _openMessageNotification(context, notification);
        return;

      case 'follow':
        if (notification.fromUserId.isEmpty) {
          return;
        }

        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                PublicProfileScreen(userId: notification.fromUserId),
          ),
        );
        return;

      case 'like':
      case 'comment':
        if (notification.postId.isEmpty) {
          return;
        }

        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                _PostNotificationScreen(postId: notification.postId),
          ),
        );
        return;

      default:
        return;
    }
  }

  Future<void> _openMessageNotification(
    BuildContext context,
    AppNotification notification,
  ) async {
    if (notification.fromUserId.isEmpty) {
      return;
    }

    final currentUserId = ChatService.currentUserId;

    if (notification.fromUserId == currentUserId) {
      return;
    }

    final chatId = notification.chatId.isNotEmpty
        ? notification.chatId
        : ChatService.getChatId(
            userId1: currentUserId,
            userId2: notification.fromUserId,
          );

    String displayName = notification.fromUsername.isNotEmpty
        ? '@${notification.fromUsername}'
        : 'krevzy User';

    try {
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(notification.fromUserId)
          .get();

      final userData = userSnapshot.data();

      final name = userData?['name']?.toString().trim() ?? '';

      final username = userData?['username']?.toString().trim() ?? '';

      if (name.isNotEmpty) {
        displayName = name;
      } else if (username.isNotEmpty) {
        displayName = '@$username';
      }
    } catch (e) {
      debugPrint('Notification sender lookup failed: $e');
    }

    final pinHashes = await ChatLockService.loadPinHashes();

    if (!context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatId: chatId,
          name: displayName,
          initialPinHash: pinHashes[chatId],
          onPinSet: (pinHash) async {
            final updated = Map<String, String>.from(pinHashes);

            updated[chatId] = pinHash;

            await ChatLockService.savePinHashes(updated);
          },
          onLockRemoved: () async {
            final updated = Map<String, String>.from(pinHashes);

            updated.remove(chatId);

            await ChatLockService.savePinHashes(updated);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            tooltip: 'Test notification',
            icon: const Icon(Icons.bug_report_outlined),
            onPressed: () => _createTestNotification(context),
          ),
          IconButton(
            tooltip: 'Mark all as read',
            icon: const Icon(Icons.done_all),
            onPressed: () => _markAllRead(context),
          ),
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: NotificationService.getNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load notifications.\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.notifications_none, size: 64),
                    const SizedBox(height: 12),
                    const Text(
                      'No notifications yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Likes, comments, follows and messages will appear here.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => _createTestNotification(context),
                      icon: const Icon(Icons.bug_report_outlined),
                      label: const Text('Test Notification'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notification = notifications[index];

              return _NotificationTile(
                notification: notification,
                icon: _iconForType(notification.type),
                timeAgo: _timeAgo(notification.createdAt),
                onTap: () => _openNotification(context, notification),
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final IconData icon;
  final String timeAgo;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.icon,
    required this.timeAgo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: notification.isRead
            ? null
            : Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundImage: notification.fromUserPhotoUrl.isNotEmpty
                  ? NetworkImage(notification.fromUserPhotoUrl)
                  : null,
              child: notification.fromUserPhotoUrl.isEmpty
                  ? Text(
                      notification.fromUsername.isNotEmpty
                          ? notification.fromUsername[0].toUpperCase()
                          : '?',
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.message,
                    style: TextStyle(
                      fontWeight: notification.isRead
                          ? FontWeight.normal
                          : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(timeAgo, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Icon(icon, size: 22),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// POST NOTIFICATION DESTINATION
// ============================================================================

class _PostNotificationScreen extends StatelessWidget {
  final String postId;

  const _PostNotificationScreen({required this.postId});

  Future<Post?> _loadPost() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .get();

    if (!snapshot.exists) {
      return null;
    }

    return Post.fromFirestore(snapshot);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
      body: FutureBuilder<Post?>(
        future: _loadPost(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load this post.\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final post = snapshot.data;

          if (post == null) {
            return const Center(
              child: Text('This post is no longer available.'),
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [PostCard(post: post)],
          );
        },
      ),
    );
  }
}

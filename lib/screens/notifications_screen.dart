import 'package:flutter/material.dart';

import '../models/notification.dart';
import '../services/notification_service.dart';

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
        const SnackBar(
          content: Text(
            'Test notification created successfully',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Test notification error: $e',
          ),
        ),
      );
    }
  }

  Future<void> _markAllRead(BuildContext context) async {
    try {
      await NotificationService.markAllAsRead();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'All notifications marked as read',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: $e',
          ),
        ),
      );
    }
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
            return const Center(
              child: CircularProgressIndicator(),
            );
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
                    const Icon(
                      Icons.notifications_none,
                      size: 64,
                    ),
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
                      'Likes and comments will appear here.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () =>
                          _createTestNotification(context),
                      icon: const Icon(
                        Icons.bug_report_outlined,
                      ),
                      label: const Text(
                        'Test Notification',
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1),
            itemBuilder: (context, index) {
              final notification = notifications[index];

              return _NotificationTile(
                notification: notification,
                icon: _iconForType(
                  notification.type,
                ),
                timeAgo: _timeAgo(
                  notification.createdAt,
                ),
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

  const _NotificationTile({
    required this.notification,
    required this.icon,
    required this.timeAgo,
  });

  Future<void> _markRead() async {
    if (notification.isRead) return;

    try {
      await NotificationService.markAsRead(
        notification.id,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _markRead,
      child: Container(
        color: notification.isRead
            ? null
            : Theme.of(context)
                .colorScheme
                .primary
                .withValues(alpha: 0.06),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundImage:
                  notification.fromUserPhotoUrl.isNotEmpty
                      ? NetworkImage(
                          notification.fromUserPhotoUrl,
                        )
                      : null,
              child: notification.fromUserPhotoUrl.isEmpty
                  ? Text(
                      notification.fromUsername.isNotEmpty
                          ? notification.fromUsername[0]
                              .toUpperCase()
                          : '?',
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
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
                  Text(
                    timeAgo,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              icon,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
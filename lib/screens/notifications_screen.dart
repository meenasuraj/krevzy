import 'package:flutter/material.dart';
import '../utils/app_theme_data.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _notifications = [
    {
      'title': 'New In-Reel Ad Order! 📦',
      'subtitle': 'Amit Sharma purchased 4K Wireless CCTV Kit (₹3,499)',
      'time': '10m ago',
      'type': 'ad',
      'isUnread': true,
      'icon': Icons.monetization_on,
      'color': Colors.amber,
    },
    {
      'title': 'Rahul_V commented on your reel',
      'subtitle': '"Great picture quality on that dome camera! 📷"',
      'time': '45m ago',
      'type': 'interaction',
      'isUnread': true,
      'icon': Icons.chat_bubble,
      'color': Colors.blue,
    },
    {
      'title': 'Pooja_99 started following you',
      'subtitle': 'Vidisha Security Tech gains a new follower',
      'time': '3h ago',
      'type': 'follower',
      'isUnread': false,
      'icon': Icons.person_add,
      'color': Colors.purple,
    },
    {
      'title': 'Super Tip Received! 🎉',
      'subtitle': 'Rahul sent ₹500 during your live broadcast',
      'time': 'Yesterday',
      'type': 'ad',
      'isUnread': false,
      'icon': Icons.card_giftcard,
      'color': Colors.pink,
    },
    {
      'title': 'Your reel surpassed 10k views',
      'subtitle': '"HD Smart CCTV System Offer" is trending in Vidisha',
      'time': '2 days ago',
      'type': 'interaction',
      'isUnread': false,
      'icon': Icons.trending_up,
      'color': Colors.green,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = AppThemeNotifier.instance;

    return AnimatedBuilder(
      animation: themeNotifier,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: themeNotifier.isDarkMode ? const Color(0xFF181818) : Colors.grey[100],
          appBar: AppBar(
            title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: themeNotifier.primaryColor,
            foregroundColor: Colors.white,
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Orders & Tips'),
                Tab(text: 'Interactions'),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.done_all),
                tooltip: 'Mark all as read',
                onPressed: () {
                  setState(() {
                    for (var notif in _notifications) {
                      notif['isUnread'] = false;
                    }
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All notifications marked as read!')),
                  );
                },
              ),
            ],
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildNotificationList(_notifications),
              _buildNotificationList(_notifications.where((n) => n['type'] == 'ad').toList()),
              _buildNotificationList(_notifications.where((n) => n['type'] == 'interaction' || n['type'] == 'follower').toList()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationList(List<Map<String, dynamic>> items) {
    final isDark = AppThemeNotifier.instance.isDarkMode;

    if (items.isEmpty) {
      return const Center(
        child: Text('No notifications in this filter.', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final notif = items[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: notif['isUnread']
                ? (isDark ? const Color(0xFF2C2C2C) : Colors.blue.shade50)
                : (isDark ? const Color(0xFF242424) : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: notif['isUnread']
                ? Border.all(color: AppThemeNotifier.instance.primaryColor.withValues(alpha: 0.4))
                : null,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: notif['color'].withValues(alpha: 0.15),
              child: Icon(notif['icon'], color: notif['color'], size: 20),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    notif['title'],
                    style: TextStyle(
                      fontWeight: notif['isUnread'] ? FontWeight.bold : FontWeight.w600,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                Text(
                  notif['time'],
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey[600]),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                notif['subtitle'],
                style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey[700]),
              ),
            ),
            onTap: () {
              setState(() {
                notif['isUnread'] = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Opened: ${notif['title']}')),
              );
            },
          ),
        );
      },
    );
  }
}
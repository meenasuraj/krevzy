import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/chat_service.dart';
import '../utils/app_theme_data.dart';
import 'chat_screen.dart';

class MessagesInboxScreen extends StatelessWidget {
  const MessagesInboxScreen({super.key});

  final List<Map<String, String>> _conversations = const [
    {
      'id': 'demo_rahul_verma',
      'name': 'Rahul Verma',
      'lastMessage': 'Can you show how night vision works on the dome camera?',
      'time': '10:46 AM',
      'unread': '2',
    },
    {
      'id': 'demo_pooja_sharma',
      'name': 'Pooja Sharma',
      'lastMessage':
          'Thanks for the quick response on the security kit inquiry!',
      'time': 'Yesterday',
      'unread': '0',
    },
    {
      'id': 'demo_amit_tech_support',
      'name': 'Amit Tech Support',
      'lastMessage': 'The firmware update has been successfully pushed.',
      'time': '2 days ago',
      'unread': '0',
    },
  ];

  void _openChat(BuildContext context, Map<String, String> chat) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please log in first.')));
      return;
    }

    final otherUserId = chat['id'] ?? 'unknown_contact';

    final chatId = ChatService.getChatId(
      userId1: currentUser.uid,
      userId2: otherUserId,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatId: chatId,
          name: chat['name'] ?? 'Contact',
          initialPinHash: null,
          onPinSet: (_) async {},
          onLockRemoved: () async {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = AppThemeNotifier.instance;

    return AnimatedBuilder(
      animation: themeNotifier,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: themeNotifier.isDarkMode
              ? const Color(0xFF181818)
              : Colors.grey[100],
          appBar: AppBar(
            title: const Text(
              'Direct Messages',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: themeNotifier.primaryColor,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                tooltip: 'Search',
                icon: const Icon(Icons.search_rounded),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Search conversations...')),
                  );
                },
              ),
            ],
          ),
          body: _conversations.isEmpty
              ? _buildEmptyState(context, themeNotifier)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _conversations.length,
                  itemBuilder: (context, index) {
                    final chat = _conversations[index];

                    final unreadCount =
                        int.tryParse(chat['unread'] ?? '0') ?? 0;

                    final hasUnread = unreadCount > 0;

                    final name = chat['name'] ?? 'Contact';

                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: themeNotifier.isDarkMode
                            ? const Color(0xFF242424)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundColor: themeNotifier.primaryColor
                              .withValues(alpha: 0.15),
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: themeNotifier.primaryColor,
                            ),
                          ),
                        ),
                        title: Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: themeNotifier.isDarkMode
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Text(
                            chat['lastMessage'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: themeNotifier.isDarkMode
                                  ? Colors.white60
                                  : Colors.black54,
                            ),
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              chat['time'] ?? '',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (hasUnread)
                              Container(
                                constraints: const BoxConstraints(
                                  minWidth: 22,
                                  minHeight: 22,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: themeNotifier.primaryColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  unreadCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        onTap: () => _openChat(context, chat),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    AppThemeNotifier themeNotifier,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 45,
              backgroundColor: themeNotifier.primaryColor.withValues(
                alpha: 0.12,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 42,
                color: themeNotifier.primaryColor,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No conversations yet',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a new conversation on KREVZY.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

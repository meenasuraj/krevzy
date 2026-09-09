import 'package:flutter/material.dart';
import '../utils/app_theme_data.dart';
import 'chat_screen.dart';

class MessagesInboxScreen extends StatelessWidget {
  const MessagesInboxScreen({super.key});

  final List<Map<String, String>> _conversations = const [
    {
      'name': 'Rahul Verma',
      'lastMessage': 'Can you show how night vision works on the dome camera?',
      'time': '10:46 AM',
      'unread': '2',
    },
    {
      'name': 'Pooja Sharma',
      'lastMessage': 'Thanks for the quick response on the security kit inquiry!',
      'time': 'Yesterday',
      'unread': '0',
    },
    {
      'name': 'Amit Tech Support',
      'lastMessage': 'The firmware update has been successfully pushed.',
      'time': '2 days ago',
      'unread': '0',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final themeNotifier = AppThemeNotifier.instance;

    return AnimatedBuilder(
      animation: themeNotifier,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: themeNotifier.isDarkMode ? const Color(0xFF181818) : Colors.grey[100],
          appBar: AppBar(
            title: const Text('Direct Messages', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: themeNotifier.primaryColor,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Search conversations...')),
                  );
                },
              ),
            ],
          ),
          body: ListView.builder(
            itemCount: _conversations.length,
            itemBuilder: (context, index) {
              final chat = _conversations[index];
              final hasUnread = int.parse(chat['unread']!) > 0;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: themeNotifier.isDarkMode ? const Color(0xFF242424) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: themeNotifier.primaryColor.withValues(alpha: 0.2),
                    child: Text(
                      chat['name']![0],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: themeNotifier.primaryColor,
                      ),
                    ),
                  ),
                  title: Text(
                    chat['name']!,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: themeNotifier.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      chat['lastMessage']!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: themeNotifier.isDarkMode ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        chat['time']!,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(height: 6),
                      if (hasUnread)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: themeNotifier.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            chat['unread']!,
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(peerName: chat['name']!),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}

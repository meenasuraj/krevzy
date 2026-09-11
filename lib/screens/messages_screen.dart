import 'package:flutter/material.dart';
import '../utils/app_theme_data.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  final List<Map<String, String>> _chats = const [
    {
      'name': 'Pooja Tech',
      'lastMessage': 'Can you quote a 4K PTZ camera setup for a warehouse?',
      'time': '10m ago',
      'initial': 'P',
      'unread': '2',
    },
    {
      'name': 'Amit Hardware Supplier',
      'lastMessage': 'The stock for 8-channel NVR has arrived.',
      'time': '2h ago',
      'initial': 'A',
      'unread': '0',
    },
    {
      'name': 'Rahul Sharma',
      'lastMessage': 'Thanks for the night vision configuration tutorial!',
      'time': '1d ago',
      'initial': 'R',
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
            backgroundColor: themeNotifier.isDarkMode ? const Color(0xFF222222) : Colors.white,
            elevation: 0.5,
            title: Text(
              'Messages',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: themeNotifier.isDarkMode ? Colors.white : Colors.black87,
                fontSize: 18,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.edit_note, color: themeNotifier.isDarkMode ? Colors.white : Colors.black87),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Start new message feature coming soon!')),
                  );
                },
              ),
            ],
          ),
          body: ListView.builder(
            itemCount: _chats.length,
            itemBuilder: (context, index) {
              final chat = _chats[index];
              final hasUnread = int.parse(chat['unread']!) > 0;

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 2),
                color: themeNotifier.isDarkMode ? const Color(0xFF222222) : Colors.white,
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: themeNotifier.primaryColor.withValues(alpha: 0.2),
                    child: Text(
                      chat['initial']!,
                      style: TextStyle(fontWeight: FontWeight.bold, color: themeNotifier.primaryColor),
                    ),
                  ),
                  title: Text(
                    chat['name']!,
                    style: TextStyle(
                      fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                      color: themeNotifier.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    chat['lastMessage']!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: hasUnread ? (themeNotifier.isDarkMode ? Colors.white70 : Colors.black87) : Colors.grey,
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(chat['time']!, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 4),
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Opening chat with ${chat['name']}...')),
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
import 'package:flutter/material.dart';
import '../utils/app_theme_data.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  final List<String> _contacts = const [
    'Rahul Verma',
    'Pooja Sharma',
    'Amit Tech Support',
    'Security Expert Group',
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
            title: const Text('Direct Chats', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: themeNotifier.primaryColor,
            foregroundColor: Colors.white,
          ),
          body: ListView.builder(
            itemCount: _contacts.length,
            itemBuilder: (context, index) {
              final contact = _contacts[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: themeNotifier.primaryColor.withValues(alpha: 0.2),
                  child: Text(contact[0], style: TextStyle(color: themeNotifier.primaryColor, fontWeight: FontWeight.bold)),
                ),
                title: Text(contact, style: TextStyle(color: themeNotifier.isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                subtitle: const Text('Tap to start messaging or calling', style: TextStyle(color: Colors.grey, fontSize: 12)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(peerName: contact),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
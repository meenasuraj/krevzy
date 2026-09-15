import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/chat_service.dart';
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

  String _chatIdForContact(String contact) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return 'demo_chat_${contact.toLowerCase().replaceAll(' ', '_')}';
    }

    return ChatService.getChatId(
      userId1: currentUser.uid,
      userId2: 'demo_${contact.toLowerCase().replaceAll(' ', '_')}',
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
              'Direct Chats',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: themeNotifier.primaryColor,
            foregroundColor: Colors.white,
          ),
          body: ListView.builder(
            itemCount: _contacts.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (context, index) {
              final contact = _contacts[index];

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: themeNotifier.isDarkMode
                      ? const Color(0xFF242424)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 7,
                  ),
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundColor: themeNotifier.primaryColor.withValues(
                      alpha: 0.15,
                    ),
                    child: Text(
                      contact.isNotEmpty ? contact[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: themeNotifier.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  title: Text(
                    contact,
                    style: TextStyle(
                      color: themeNotifier.isDarkMode
                          ? Colors.white
                          : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Tap to start messaging or calling',
                    style: TextStyle(
                      color: themeNotifier.isDarkMode
                          ? Colors.white60
                          : Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 15,
                    color: themeNotifier.isDarkMode
                        ? Colors.white54
                        : Colors.grey,
                  ),
                  onTap: () {
                    final currentUser = FirebaseAuth.instance.currentUser;

                    if (currentUser == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please log in first.')),
                      );
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          chatId: _chatIdForContact(contact),
                          name: contact,
                          initialPinHash: null,
                          onPinSet: (_) async {},
                          onLockRemoved: () async {},
                        ),
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

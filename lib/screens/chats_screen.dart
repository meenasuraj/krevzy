import 'package:flutter/material.dart';

import 'chat_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final List<Map<String, dynamic>> chats = const [
    {'name': 'Rahul', 'message': 'Hello 👋', 'time': '10:30 AM', 'unread': 2},
    {
      'name': 'Priya',
      'message': 'Kal milte hain 😊',
      'time': '09:45 AM',
      'unread': 0,
    },
    {
      'name': 'Aman',
      'message': 'Photo bhej dena',
      'time': 'Yesterday',
      'unread': 3,
    },
    {
      'name': 'Neha',
      'message': 'Good night 🌙',
      'time': 'Yesterday',
      'unread': 0,
    },
  ];

  // Har chat ka PIN yahan save rahega.
  final Map<String, String> _chatPins = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chats',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Search baad mein add karenge.
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Chat settings baad mein add karenge.
            },
          ),
        ],
      ),

      body: ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];

          final String chatName = chat['name'].toString();

          final String? savedPin = _chatPins[chatName];

          return _ChatTile(
            name: chatName,
            message: chat['message'].toString(),
            time: chat['time'].toString(),
            unread: chat['unread'] as int,
            isLocked: savedPin != null,

            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return ChatScreen(
                      name: chatName,

                      // Existing PIN ChatScreen ko bhej rahe hain.
                      initialPin: savedPin,

                      // Jab ChatScreen mein PIN set hoga,
                      // yahan save hoga.
                      onPinSet: (pin) {
                        setState(() {
                          _chatPins[chatName] = pin;
                        });
                      },

                      // Lock remove karne ke liye.
                      onLockRemoved: () {
                        setState(() {
                          _chatPins.remove(chatName);
                        });
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // New Chat baad mein add karenge.
        },
        child: const Icon(Icons.chat),
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final String name;
  final String message;
  final String time;
  final int unread;
  final bool isLocked;
  final VoidCallback onTap;

  const _ChatTile({
    required this.name,
    required this.message,
    required this.time,
    required this.unread,
    required this.isLocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),

      leading: CircleAvatar(
        radius: 27,
        child: Text(
          name.substring(0, 1),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),

      title: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),

          if (isLocked) const Icon(Icons.lock, size: 17),
        ],
      ),

      subtitle: Text(message, maxLines: 1, overflow: TextOverflow.ellipsis),

      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(time, style: const TextStyle(fontSize: 12)),

          if (unread > 0) ...[
            const SizedBox(height: 5),

            CircleAvatar(
              radius: 10,
              child: Text(
                '$unread',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),

      onTap: onTap,
    );
  }
}

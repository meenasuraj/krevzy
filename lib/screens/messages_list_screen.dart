import 'package:flutter/material.dart';
import 'chat_detail_screen.dart';

class MessagesListScreen extends StatelessWidget {
  const MessagesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> conversations = [
      {
        'name': 'Rahul Sharma',
        'handle': '@rahul_tech',
        'lastMessage': 'Let me know if you need any feedback on the Flutter codebase!',
        'time': '10:20 AM',
        'unreadCount': 2,
      },
      {
        'name': 'Priya Verma',
        'handle': '@priya_v',
        'lastMessage': 'The digital photo editing workflow looks amazing.',
        'time': 'Yesterday',
        'unreadCount': 0,
      },
      {
        'name': 'Amit Kumar',
        'handle': '@amit_cctv',
        'lastMessage': 'Thanks for the connection request!',
        'time': '2d ago',
        'unreadCount': 0,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: conversations.length,
        itemBuilder: (context, index) {
          final chat = conversations[index];
          final unread = chat['unreadCount'] as int;

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  chat['name'][0],
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    chat['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    chat['time'],
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  chat['lastMessage'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: unread > 0 ? Colors.black87 : Colors.grey[600],
                    fontWeight: unread > 0 ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ),
              trailing: unread > 0
                  ? Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$unread',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    )
                  : null,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatDetailScreen(
                      peerName: chat['name'],
                      peerHandle: chat['handle'],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
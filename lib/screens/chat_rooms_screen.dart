import 'package:flutter/material.dart';

import '../services/chat_room_service.dart';
import 'create_chat_room_screen.dart';
import 'chat_room_screen.dart';

class ChatRoomsScreen extends StatelessWidget {
  const ChatRoomsScreen({super.key});

  static const categories = [
    'Study',
    'Gaming',
    'Business',
    'Share Market',
    'History',
    'Geography',
    'Cricket',
    'Hockey',
    'Football',
  ];

  IconData _icon(String category) {
    switch (category) {
      case 'Study':
        return Icons.school;
      case 'Gaming':
        return Icons.sports_esports;
      case 'Business':
        return Icons.business_center;
      case 'Share Market':
        return Icons.show_chart;
      case 'History':
        return Icons.history_edu;
      case 'Geography':
        return Icons.public;
      case 'Cricket':
        return Icons.sports_cricket;
      case 'Hockey':
        return Icons.sports_hockey;
      case 'Football':
        return Icons.sports_soccer;
      default:
        return Icons.groups;
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = ChatRoomService.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('KREVZY Rooms')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateChatRoomScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Room'),
      ),
      body: StreamBuilder(
        stream: service.watchPublicRooms(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Unable to load rooms.\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final rooms = snapshot.data?.docs ?? [];

          if (rooms.isEmpty) {
            return const Center(
              child: Text(
                'No public rooms yet.\nCreate the first one!',
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 12, bottom: 100),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index].data();

              final category = room['category']?.toString() ?? 'Other';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(child: Icon(_icon(category))),
                  title: Text(
                    room['name']?.toString() ?? 'KREVZY Room',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '$category • '
                    '${room['memberCount'] ?? 0} members',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatRoomScreen(roomId: rooms[index].id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

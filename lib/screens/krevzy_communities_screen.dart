import 'package:flutter/material.dart';

import '../models/krevzy_community.dart';
import '../services/krevzy_community_service.dart';
import 'create_krevzy_room_screen.dart';
import 'krevzy_room_screen.dart';

class KrevzyCommunitiesScreen extends StatelessWidget {
  const KrevzyCommunitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = KrevzyCommunityService.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('KREVZY Communities')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateKrevzyRoomScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Room'),
      ),
      body: StreamBuilder<List<KrevzyCommunity>>(
        stream: service.watchPublicRooms(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Unable to load communities.\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final rooms = snapshot.data ?? [];

          if (rooms.isEmpty) {
            return const Center(
              child: Text(
                'No communities yet.\nCreate the first KREVZY room.',
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 12, bottom: 100),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(_categoryIcon(room.category)),
                  ),
                  title: Text(
                    room.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${room.category.label} • '
                    '${room.memberCount} members',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => KrevzyRoomScreen(roomId: room.id),
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

  static IconData _categoryIcon(CommunityCategory category) {
    switch (category) {
      case CommunityCategory.study:
        return Icons.school;
      case CommunityCategory.gaming:
        return Icons.sports_esports;
      case CommunityCategory.business:
        return Icons.business_center;
      case CommunityCategory.shareMarket:
        return Icons.show_chart;
      case CommunityCategory.history:
        return Icons.history_edu;
      case CommunityCategory.geography:
        return Icons.public;
      case CommunityCategory.cricket:
        return Icons.sports_cricket;
      case CommunityCategory.hockey:
        return Icons.sports_hockey;
      case CommunityCategory.football:
        return Icons.sports_soccer;
      case CommunityCategory.other:
        return Icons.groups;
    }
  }
}

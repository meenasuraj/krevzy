import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/room_service.dart';
import 'create_room_screen.dart';
import 'room_chat_screen.dart';

class RoomsScreen extends StatelessWidget {
  const RoomsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('KREVZY Rooms'), actions: [IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateRoomScreen())), icon: const Icon(Icons.add_home_work_outlined))]),
    body: StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
      stream: RoomService.watchPublicRooms(),
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text('Rooms unavailable: ${snap.error}')));
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final rooms = [...snap.data!.docs]..sort((a,b) => ((b.data()['memberCount'] as num?)?.toInt() ?? 0).compareTo((a.data()['memberCount'] as num?)?.toInt() ?? 0));
        if (rooms.isEmpty) return _empty(context);
        return ListView.builder(padding: const EdgeInsets.all(16), itemCount: rooms.length, itemBuilder: (context,index) {
          final doc = rooms[index]; final d = doc.data();
          return Card(margin: const EdgeInsets.only(bottom:12), elevation:0, child: ListTile(isThreeLine:true, contentPadding: const EdgeInsets.all(12), leading: CircleAvatar(radius:28, child: Text((d['name']?.toString() ?? 'R').substring(0,1).toUpperCase())), title: Text(d['name']?.toString() ?? 'Room', style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('@${d['username'] ?? ''}\n${d['memberCount'] ?? 0} members • ${d['category'] ?? 'Social'}'), trailing: FilledButton(onPressed: () async { try { await RoomService.joinRoom(doc.id); if (context.mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => RoomChatScreen(roomId: doc.id))); } catch(e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); } }, child: const Text('Join'))));
        });
      },
    ),
    floatingActionButton: FloatingActionButton.extended(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateRoomScreen())), icon: const Icon(Icons.add), label: const Text('Create Room')),
  );

  Widget _empty(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(30), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.meeting_room_outlined, size: 64), const SizedBox(height: 14), const Text('No public rooms yet', style: TextStyle(fontSize:20,fontWeight:FontWeight.w800)), const SizedBox(height:8), const Text('Create the first KREVZY room and start a real conversation.'), const SizedBox(height:20), FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateRoomScreen())), icon: const Icon(Icons.add), label: const Text('Create Room'))])));
}

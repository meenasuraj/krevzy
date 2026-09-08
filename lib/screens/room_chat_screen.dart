import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/room_service.dart';
import '../widgets/krevzy_background.dart';

class RoomChatScreen extends StatefulWidget {
  final String roomId;
  const RoomChatScreen({super.key, required this.roomId});
  @override
  State<RoomChatScreen> createState() => _RoomChatScreenState();
}

class _RoomChatScreenState extends State<RoomChatScreen> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  Future<void> _send() async {
    final text = _controller.text;
    if (text.trim().isEmpty || _sending) return;
    setState(() => _sending = true);
    try { await RoomService.sendMessage(roomId: widget.roomId, text: text); _controller.clear(); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); }
    finally { if (mounted) setState(() => _sending = false); }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<DocumentSnapshot<Map<String,dynamic>>>(
    stream: RoomService.watchRoom(widget.roomId),
    builder: (context, roomSnap) {
      final room = roomSnap.data?.data();
      final name = room?['name']?.toString() ?? 'Room';
      return Scaffold(
        appBar: AppBar(title: Text(name), actions: [IconButton(onPressed: () => _showAbout(room ?? {}), icon: const Icon(Icons.info_outline))]),
        body: Stack(children: [
          const Positioned.fill(child: KrevzyBackground(child: SizedBox.shrink())),
          Column(children: [
            Expanded(child: StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
              stream: RoomService.watchMessages(widget.roomId),
              builder: (context, snap) {
                if (snap.hasError) return Center(child: Text('Room messages unavailable: ${snap.error}'));
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snap.data!.docs;
                return ListView.builder(reverse: true, padding: const EdgeInsets.all(12), itemCount: docs.length, itemBuilder: (_, i) {
                  final data = docs[i].data();
                  final mine = data['senderId'] == FirebaseAuth.instance.currentUser?.uid;
                  return Align(alignment: mine ? Alignment.centerRight : Alignment.centerLeft, child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), constraints: const BoxConstraints(maxWidth: 320), decoration: BoxDecoration(color: mine ? const Color(0xFF6C63FF) : Colors.white.withValues(alpha:.9), borderRadius: BorderRadius.circular(18)), child: Text(data['text']?.toString() ?? '', style: TextStyle(color: mine ? Colors.white : Colors.black87))));
                });
              },
            )),
            SafeArea(top: false, child: Padding(padding: const EdgeInsets.fromLTRB(10,6,10,10), child: Row(children: [Expanded(child: TextField(controller: _controller, minLines: 1, maxLines: 4, decoration: InputDecoration(hintText: 'Message room...', filled: true, fillColor: Colors.white.withValues(alpha:.9), border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none)))), const SizedBox(width: 8), CircleAvatar(child: IconButton(onPressed: _sending ? null : _send, icon: const Icon(Icons.send_rounded))) ]))),
          ]),
        ]),
      );
    },
  );

  void _showAbout(Map<String,dynamic> room) {
    showModalBottomSheet(context: context, showDragHandle: true, builder: (_) => Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(room['name']?.toString() ?? 'Room', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)), const SizedBox(height: 8), Text(room['description']?.toString() ?? 'No description'), const SizedBox(height: 12), Text('${room['memberCount'] ?? 0} members • ${room['category'] ?? 'Social'}'), const SizedBox(height: 20)])));
  }
}

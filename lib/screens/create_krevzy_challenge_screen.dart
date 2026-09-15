import 'package:flutter/material.dart';

import '../services/chat_room_service.dart';

class CreateChatRoomScreen extends StatefulWidget {
  const CreateChatRoomScreen({super.key});

  @override
  State<CreateChatRoomScreen> createState() => _CreateChatRoomScreenState();
}

class _CreateChatRoomScreenState extends State<CreateChatRoomScreen> {
  final _nameController = TextEditingController();

  final _descriptionController = TextEditingController();

  String _category = 'Study';

  bool _publicRoom = true;
  bool _memberChallenges = true;
  bool _memberRules = true;
  bool _loading = false;

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

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      _show('Enter a room name.');
      return;
    }

    setState(() => _loading = true);

    try {
      final roomId = await ChatRoomService.instance.createRoom(
        name: name,
        description: _descriptionController.text,
        category: _category,
        isPublic: _publicRoom,
        allowMemberChallenges: _memberChallenges,
        allowMemberRules: _memberRules,
      );

      if (!mounted) return;

      Navigator.pop(context, roomId);
    } catch (e) {
      _show(e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _show(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Chat Room')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Room name',
              hintText: 'Example: Cricket Discussion',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Tell users what this room is about.',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            items: categories
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _category = value);
              }
            },
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            title: const Text('Public room'),
            subtitle: const Text('Anyone can discover and join.'),
            value: _publicRoom,
            onChanged: (value) {
              setState(() => _publicRoom = value);
            },
          ),
          SwitchListTile(
            title: const Text('Members can create challenges'),
            value: _memberChallenges,
            onChanged: (value) {
              setState(() => _memberChallenges = value);
            },
          ),
          SwitchListTile(
            title: const Text('Members can propose rules'),
            value: _memberRules,
            onChanged: (value) {
              setState(() => _memberRules = value);
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _loading ? null : _createRoom,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.groups),
              label: Text(_loading ? 'Creating...' : 'Create Room'),
            ),
          ),
        ],
      ),
    );
  }
}

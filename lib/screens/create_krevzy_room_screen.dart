import 'package:flutter/material.dart';

import '../models/krevzy_community.dart';
import '../services/krevzy_community_service.dart';
import 'krevzy_room_screen.dart';

class CreateKrevzyRoomScreen extends StatefulWidget {
  const CreateKrevzyRoomScreen({super.key});

  @override
  State<CreateKrevzyRoomScreen> createState() => _CreateKrevzyRoomScreenState();
}

class _CreateKrevzyRoomScreenState extends State<CreateKrevzyRoomScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  CommunityCategory _category = CommunityCategory.study;

  bool _publicRoom = true;
  bool _memberChallenges = true;
  bool _memberRules = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    if (_nameController.text.trim().isEmpty) {
      _show('Enter a room name.');
      return;
    }

    setState(() => _loading = true);

    try {
      final roomId = await KrevzyCommunityService.instance.createRoom(
        name: _nameController.text,
        description: _descriptionController.text,
        category: _category,
        isPublic: _publicRoom,
        allowMemberChallenges: _memberChallenges,
        allowMemberRules: _memberRules,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => KrevzyRoomScreen(roomId: roomId)),
      );
    } catch (e) {
      if (mounted) {
        _show(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Community')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          TextField(
            controller: _nameController,
            textInputAction: TextInputAction.next,
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
              hintText: 'What is this community about?',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<CommunityCategory>(
            initialValue: _category,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            items: CommunityCategory.values
                .map(
                  (category) => DropdownMenuItem<CommunityCategory>(
                    value: category,
                    child: Text(category.label),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _category = value);
              }
            },
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Public room'),
            subtitle: const Text('Anyone can discover and join this room.'),
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

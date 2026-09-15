import 'package:flutter/material.dart';

import '../services/room_service.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});
  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _description = TextEditingController();
  String _category = 'Social';
  bool _public = true;
  bool _approval = false;
  int _maxMembers = 100;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    try {
      final id = await RoomService.createRoom(
        name: _name.text,
        username: _username.text,
        description: _description.text,
        category: _category,
        isPublic: _public,
        requiresApproval: _approval,
        maxMembers: _maxMembers,
      );
      if (!mounted) {
        return;
      }
      Navigator.pop(context, id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not create room: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Create Room')),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Create your KREVZY room',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Room name',
              prefixIcon: Icon(Icons.meeting_room_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (v) => v == null || v.trim().length < 3
                ? 'Enter at least 3 characters'
                : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _username,
            decoration: const InputDecoration(
              labelText: 'Room username',
              prefixText: '@',
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                v == null ||
                    !RegExp(r'^[a-z0-9._-]{3,30}$')
                        .hasMatch(v.trim().toLowerCase())
                ? 'Use 3–30 letters, numbers, . _ or -'
                : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _description,
            maxLines: 3,
            maxLength: 160,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            items: const [
              'Social',
              'Music',
              'Gaming',
              'Travel',
              'Creators',
              'Study',
              'Technology',
              'Sports',
              'Other',
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => _category = v ?? 'Social'),
          ),
          SwitchListTile(
            title: const Text('Public room'),
            subtitle: const Text('Anyone can discover this room'),
            value: _public,
            onChanged: (v) => setState(() => _public = v),
          ),
          SwitchListTile(
            title: const Text('Approval required'),
            subtitle: const Text('New members request access'),
            value: _approval,
            onChanged: (v) => setState(() => _approval = v),
          ),
          ListTile(
            title: const Text('Maximum members'),
            subtitle: Text('$_maxMembers members'),
            trailing: DropdownButton<int>(
              value: _maxMembers,
              items: const [50, 100, 250, 500, 1000]
                  .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
                  .toList(),
              onChanged: (v) => setState(() => _maxMembers = v ?? 100),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _saving ? null : _create,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_home_work_outlined),
            label: Text(_saving ? 'Creating...' : 'Create Room'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
            ),
          ),
        ],
      ),
    ),
  );
}

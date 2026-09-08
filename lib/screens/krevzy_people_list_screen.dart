import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/krevzy_social_settings_service.dart';

class KrevzyPeopleListScreen extends StatefulWidget {
  final String title;
  final String collection;
  final String emptyText;
  final IconData icon;

  const KrevzyPeopleListScreen({
    super.key,
    required this.title,
    required this.collection,
    required this.emptyText,
    this.icon = Icons.person_outline,
  });

  @override
  State<KrevzyPeopleListScreen> createState() => _KrevzyPeopleListScreenState();
}

class _KrevzyPeopleListScreenState extends State<KrevzyPeopleListScreen> {
  final TextEditingController controller = TextEditingController();
  bool adding = false;

  Future<void> add() async {
    final username = controller.text.trim();
    if (username.isEmpty) return;

    setState(() => adding = true);
    try {
      await KrevzySocialSettingsService.addPersonByUsername(
        widget.collection,
        username,
      );
      controller.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => adding = false);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => add(),
                    decoration: const InputDecoration(
                      hintText: 'Enter username',
                      prefixText: '@',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: adding ? null : add,
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: KrevzySocialSettingsService.watchPeople(widget.collection),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Unable to load ${widget.title}.'),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return Center(child: Text(widget.emptyText));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final rawName = data['name']?.toString().trim() ?? '';
                    final name = rawName.isNotEmpty
                        ? rawName
                        : (data['username']?.toString() ?? 'User');
                    final username = data['username']?.toString() ?? '';
                    final photo = data['photoUrl']?.toString() ?? '';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            photo.isNotEmpty ? NetworkImage(photo) : null,
                        child: photo.isEmpty ? Icon(widget.icon) : null,
                      ),
                      title: Text(name),
                      subtitle: username.isEmpty ? null : Text('@$username'),
                      trailing: TextButton(
                        onPressed: () =>
                            KrevzySocialSettingsService.removePerson(
                          widget.collection,
                          doc.id,
                        ),
                        child: const Text('Remove'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

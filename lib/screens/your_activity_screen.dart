import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/krevzy_social_settings_service.dart';

class YourActivityScreen extends StatelessWidget {
  const YourActivityScreen({super.key});
  Future<void> _clear(BuildContext context) async {
    try {
      await KrevzySocialSettingsService.clearActivity();
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Activity cleared.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unable to clear activity: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your activity'),
        actions: [
          IconButton(
            tooltip: 'Clear activity',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () => _clear(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: KrevzySocialSettingsService.watchActivity(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load activity.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('Your activity will appear here.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final timestamp = data['createdAt'];
              final when = timestamp is Timestamp
                  ? timestamp.toDate().toLocal().toString().split('.').first
                  : '';

              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.history)),
                title: Text(data['title']?.toString() ?? 'Activity'),
                subtitle: Text(
                  [
                    data['detail']?.toString() ?? '',
                    when,
                  ].where((value) => value.isNotEmpty).join('\n'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

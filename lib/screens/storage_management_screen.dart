import 'package:flutter/material.dart';

class StorageManagementScreen extends StatefulWidget {
  const StorageManagementScreen({super.key});
  @override
  State<StorageManagementScreen> createState() =>
      _StorageManagementScreenState();
}

class _StorageManagementScreenState extends State<StorageManagementScreen> {
  bool clearing = false;
  Future<void> _clear() async {
    setState(() => clearing = true);
    try {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Temporary image cache cleared.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => clearing = false);
      }
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Storage')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Card(
          child: ListTile(
            leading: Icon(Icons.image_outlined),
            title: Text('Temporary image cache'),
            subtitle: Text(
              'Cached images can be safely cleared. Your posts, messages and account data are not deleted.',
            ),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: clearing ? null : _clear,
          icon: const Icon(Icons.cleaning_services_outlined),
          label: Text(clearing ? 'Clearing...' : 'Clear temporary cache'),
        ),
      ],
    ),
  );
}

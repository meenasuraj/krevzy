import 'package:flutter/material.dart';

import '../services/krevzy_social_settings_service.dart';

class DataMediaQualityScreen extends StatefulWidget {
  const DataMediaQualityScreen({super.key});
  @override
  State<DataMediaQualityScreen> createState() => _DataMediaQualityScreenState();
}

class _DataMediaQualityScreenState extends State<DataMediaQualityScreen> {
  bool dataSaver = false, autoplay = true, uploadHigh = false, loading = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await KrevzySocialSettingsService.getSettings();
      if (!mounted) return;
      setState(() {
        dataSaver = d['data_saver'] as bool? ?? false;
        autoplay = d['autoplay_media'] as bool? ?? true;
        uploadHigh = d['upload_high_quality'] as bool? ?? false;
        loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> save(String k, bool v) async {
    setState(() {
      if (k == 'data_saver') dataSaver = v;
      if (k == 'autoplay_media') autoplay = v;
      if (k == 'upload_high_quality') uploadHigh = v;
    });
    try {
      await KrevzySocialSettingsService.setValue(k, v);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Unable to save: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Data used and media quality')),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            children: [
              SwitchListTile(
                title: const Text('Data saver'),
                subtitle: const Text('Use less mobile data for media'),
                value: dataSaver,
                onChanged: (v) => save('data_saver', v),
              ),
              SwitchListTile(
                title: const Text('Autoplay media'),
                value: autoplay,
                onChanged: (v) => save('autoplay_media', v),
              ),
              SwitchListTile(
                title: const Text('Upload at highest quality'),
                subtitle: const Text('Uses more data and storage'),
                value: uploadHigh,
                onChanged: (v) => save('upload_high_quality', v),
              ),
              const ListTile(
                title: Text('Media quality'),
                subtitle: Text(
                  'Your choices are saved to your KREVZY account and restored when you return.',
                ),
              ),
            ],
          ),
  );
}

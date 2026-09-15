import 'package:flutter/material.dart';

import '../services/account_center_service.dart';

class ConnectedExperienceScreen extends StatefulWidget {
  const ConnectedExperienceScreen({super.key});
  @override
  State<ConnectedExperienceScreen> createState() =>
      _ConnectedExperienceScreenState();
}

class _ConnectedExperienceScreenState extends State<ConnectedExperienceScreen> {
  bool syncContacts = false,
      suggestAccounts = true,
      crossDevice = true,
      personalization = true,
      loading = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s = await AccountCenterService.watchSettings().first;
      final d = s.data() ?? {};
      if (!mounted) return;
      setState(() {
        syncContacts = d['syncContacts'] as bool? ?? false;
        suggestAccounts = d['accountSuggestions'] as bool? ?? true;
        crossDevice = d['crossDevice'] as bool? ?? true;
        personalization = d['personalization'] as bool? ?? true;
        loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _set(String key, bool value) async {
    setState(() {
      if (key == 'syncContacts') syncContacts = value;
      if (key == 'accountSuggestions') suggestAccounts = value;
      if (key == 'crossDevice') crossDevice = value;
      if (key == 'personalization') personalization = value;
    });
    try {
      await AccountCenterService.setValue(key, value);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Unable to save: $e')));
      }
    }
  }

  Widget tile(String t, String s, String k, bool v) => SwitchListTile(
    title: Text(t),
    subtitle: Text(s),
    value: v,
    onChanged: (x) => _set(k, x),
  );
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Connected experience')),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            children: [
              tile(
                'Sync contacts',
                'Use your contacts to help discover people.',
                'syncContacts',
                syncContacts,
              ),
              tile(
                'Account suggestions',
                'Allow KREVZY to suggest relevant accounts.',
                'accountSuggestions',
                suggestAccounts,
              ),
              tile(
                'Cross-device experience',
                'Keep supported preferences consistent across devices.',
                'crossDevice',
                crossDevice,
              ),
              tile(
                'Personalized experience',
                'Use your activity to personalize discovery.',
                'personalization',
                personalization,
              ),
            ],
          ),
  );
}

import 'package:flutter/material.dart';
import '../services/krevzy_social_settings_service.dart';

class AccountPrivacyScreen extends StatefulWidget {
  const AccountPrivacyScreen({super.key});
  @override State<AccountPrivacyScreen> createState() => _AccountPrivacyScreenState();
}
class _AccountPrivacyScreenState extends State<AccountPrivacyScreen> {
  final Map<String, bool> values = {
    'Private account': false,
    'Activity status': true,
    'Read receipts': true,
    'Show profile photo to everyone': true,
  };
  bool loading = true;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try {
      final data = await KrevzySocialSettingsService.getSettings();
      if (!mounted) return;
      setState(() {
        values['Private account'] = data['private_account'] as bool? ?? false;
        values['Activity status'] = data['activity_status'] as bool? ?? true;
        values['Read receipts'] = data['read_receipts'] as bool? ?? true;
        values['Show profile photo to everyone'] = data['show_profile_photo_to_everyone'] as bool? ?? true;
        loading = false;
      });
    } catch (_) { if (mounted) setState(() => loading = false); }
  }
  Future<void> toggle(String key, bool value) async {
    setState(() => values[key] = value);
    try {
      await KrevzySocialSettingsService.setValue(key.replaceAll(' ', '_').toLowerCase(), value);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Privacy setting saved.')));
    } catch (e) {
      if (!mounted) return;
      setState(() => values[key] = !value);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unable to save: $e')));
    }
  }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Account privacy')),
    body: loading ? const Center(child: CircularProgressIndicator()) : ListView(
      padding: const EdgeInsets.symmetric(vertical: 8), children: [
        const ListTile(title: Text('Privacy controls', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), subtitle: Text('Control who can see and interact with you.')),
        ...values.entries.map((e) => SwitchListTile(title: Text(e.key), value: e.value, onChanged: (v) => toggle(e.key, v))),
      ],
    ),
  );
}

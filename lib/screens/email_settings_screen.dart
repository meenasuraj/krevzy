import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/account_center_service.dart';

class EmailSettingsScreen extends StatefulWidget {
  const EmailSettingsScreen({super.key});
  @override State<EmailSettingsScreen> createState() => _EmailSettingsScreenState();
}

class _EmailSettingsScreenState extends State<EmailSettingsScreen> {
  final controller = TextEditingController();
  bool saving = false;
  @override void initState() { super.initState(); controller.text = FirebaseAuth.instance.currentUser?.email ?? ''; }
  @override void dispose() { controller.dispose(); super.dispose(); }
  Future<void> _save() async {
    setState(() => saving = true);
    try { await AccountCenterService.updateEmail(controller.text); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verification email sent. Confirm it to finish changing your email.'))); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unable to update email: $e'))); }
    finally { if (mounted) setState(() => saving = false); }
  }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Email settings')), body: Padding(padding: const EdgeInsets.all(16), child: Column(children: [TextField(controller: controller, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email address', border: OutlineInputBorder())), const SizedBox(height: 16), SizedBox(width: double.infinity, child: FilledButton(onPressed: saving ? null : _save, child: saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Update email')))])));
}

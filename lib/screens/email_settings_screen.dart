import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/account_center_service.dart';

class EmailSettingsScreen extends StatefulWidget {
  const EmailSettingsScreen({super.key});

  @override
  State<EmailSettingsScreen> createState() => _EmailSettingsScreenState();
}

class _EmailSettingsScreenState extends State<EmailSettingsScreen> {
  late final TextEditingController _emailController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(
      text: FirebaseAuth.instance.currentUser?.email ?? '',
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveEmail() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showMessage('Email required', 'Please enter an email address.');
      return;
    }

    final validEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!validEmail) {
      _showMessage('Invalid email', 'Please enter a valid email address.');
      return;
    }

    if (_saving) return;

    setState(() => _saving = true);

    try {
      await AccountCenterService.updateEmail(email);

      if (!mounted) return;
      _showMessage(
        'Verification email sent',
        'Confirm the verification email to finish changing your email.',
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showMessage('Unable to update email', e.message ?? e.code);
    } catch (e) {
      if (!mounted) return;
      _showMessage('Unable to update email', e.toString());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _showMessage(String title, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$title: $message')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Email settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Email address',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Update the email connected to your KREVZY account.'),
          const SizedBox(height: 20),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Email address',
              hintText: 'you@example.com',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email_outlined),
            ),
            onSubmitted: (_) => _saveEmail(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: _saving ? null : _saveEmail,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Update email'),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'active_sessions_screen.dart';
import 'password_change_screen.dart';

class PasswordSecurityScreen extends StatelessWidget {
  const PasswordSecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Password and security')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.password_outlined),
            title: const Text('Change password'),
            subtitle: const Text('Receive a secure password reset link'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PasswordChangeScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.devices_outlined),
            title: const Text('Active sessions'),
            subtitle: const Text('Review sessions registered by KREVZY'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ActiveSessionsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.security_outlined),
            title: const Text('Security Center'),
            subtitle: const Text(
              'App lock, login security and account protection',
            ),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Use Security Center from Settings.'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

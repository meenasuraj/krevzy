import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ManageAccountScreen extends StatelessWidget {
  const ManageAccountScreen({super.key});

  Future<void> _confirm(BuildContext context, bool delete) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(delete ? 'Delete account?' : 'Deactivate account?'),
        content: Text(
          delete
              ? 'This action is permanent. Your account cannot be restored from this screen.'
              : 'Your account will be marked as deactivated. You can reactivate later by signing in again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(delete ? 'Delete' : 'Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      if (delete) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'isDeactivated': true,
          'deletedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        await user.delete();
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'isDeactivated': true,
          'deactivatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        await FirebaseAuth.instance.signOut();
      }

      if (context.mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to complete: ${e.message ?? e.code}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to complete: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage account')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person_off_outlined),
            title: const Text('Deactivate account'),
            subtitle: const Text('Temporarily disable your KREVZY account.'),
            onTap: () => _confirm(context, false),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Delete account'),
            subtitle: const Text('Permanently delete your account.'),
            onTap: () => _confirm(context, true),
          ),
          ListTile(
            leading: const Icon(Icons.logout_outlined),
            title: const Text('Log out of this device'),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.popUntil(context, (route) => route.isFirst);
              }
            },
          ),
        ],
      ),
    );
  }
}

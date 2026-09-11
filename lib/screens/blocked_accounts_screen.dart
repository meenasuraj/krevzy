import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/post_actions_service.dart';

class BlockedAccountsScreen extends StatefulWidget {
  const BlockedAccountsScreen({super.key});
  @override
  State<BlockedAccountsScreen> createState() => _BlockedAccountsScreenState();
}

class _BlockedAccountsScreenState extends State<BlockedAccountsScreen> {
  final search = TextEditingController();
  bool adding = false;
  Future<void> _block() async {
    final username = search.text.trim().replaceFirst('@', '');
    if (username.isEmpty) return;
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;
    setState(() => adding = true);
    try {
      final q = await FirebaseFirestore.instance
          .collection('users')
          .where('usernameLowercase', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();
      if (q.docs.isEmpty) throw Exception('User not found.');
      await PostActionsService.blockUser(
        q.docs.first.id,
        username: q.docs.first.data()['username']?.toString() ?? username,
      );
      search.clear();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Account blocked.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => adding = false);
    }
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Blocked accounts')),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: search,
                  onSubmitted: (_) => _block(),
                  decoration: const InputDecoration(
                    hintText: 'Enter username',
                    prefixText: '@',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: adding ? null : _block,
                child: const Icon(Icons.block),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: PostActionsService.blockedUsers(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Unable to load blocked accounts.\n${snapshot.error}',
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const Center(
                  child: Text('You have not blocked anyone.'),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                separatorBuilder: (_, i) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final d = docs[i].data();
                  final uid = d['userId']?.toString() ?? docs[i].id;
                  final username = d['username']?.toString() ?? '';
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.block)),
                    title: Text(
                      username.isEmpty ? 'Blocked account' : '@$username',
                    ),
                    subtitle: Text(uid),
                    trailing: TextButton(
                      onPressed: () async {
                        try {
                          await PostActionsService.unblockUser(uid);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Account unblocked.'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Unable to unblock: $e')),
                            );
                          }
                        }
                      },
                      child: const Text('Unblock'),
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

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
  final TextEditingController search = TextEditingController();
  bool adding = false;

  Future<void> _block() async {
    final username = search.text.trim().replaceFirst('@', '');
    if (username.isEmpty) return;

    final me = FirebaseAuth.instance.currentUser;
    if (me == null) {
      _showMessage('Please log in first.');
      return;
    }

    setState(() => adding = true);
    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('usernameLowercase', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        throw Exception('User not found.');
      }

      final target = query.docs.first;
      final data = target.data();
      await PostActionsService.blockUser(
        target.id,
        username: data['username']?.toString() ?? username,
      );

      search.clear();
      _showMessage('Account blocked.');
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => adding = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Unable to load blocked accounts.\n${snapshot.error}',
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
                  return const Center(child: Text('You have not blocked anyone.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final document = docs[index];
                    final data = document.data();
                    final uid = data['userId']?.toString() ?? document.id;
                    final username = data['username']?.toString() ?? '';

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
                                const SnackBar(content: Text('Account unblocked.')),
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
}

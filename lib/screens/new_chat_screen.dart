import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/chat_service.dart';
import '../services/user_service.dart';
import 'chat_screen.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final TextEditingController _searchController = TextEditingController();

  Timer? _searchTimer;

  String _searchText = '';

  bool _isCreatingChat = false;

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // SEARCH
  // ============================================================

  void _onSearchChanged(String value) {
    _searchTimer?.cancel();

    _searchTimer = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;

      setState(() {
        _searchText = value.trim().toLowerCase();
      });
    });
  }

  // ============================================================
  // CREATE CHAT
  // ============================================================

  Future<void> _startChat(Map<String, dynamic> userData) async {
    if (_isCreatingChat) {
      return;
    }

    final uid = userData['uid']?.toString();

    if (uid == null || uid.isEmpty) {
      _showError('This user profile is invalid.');
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      _showError('Please login again.');
      return;
    }

    if (uid == currentUser.uid) {
      _showError('You cannot start a chat with yourself.');
      return;
    }

    setState(() {
      _isCreatingChat = true;
    });

    try {
      final chatId = await ChatService.createOrGetChat(otherUserId: uid);

      if (!mounted) return;

      final name = userData['name']?.toString().trim();

      final username = userData['username']?.toString().trim();

      final displayName = name != null && name.isNotEmpty
          ? name
          : username != null && username.isNotEmpty
          ? '@$username'
          : 'Gapshap User';

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: chatId,
            name: displayName,
            initialPinHash: null,
            onPinSet: (_) async {},
            onLockRemoved: () async {},
          ),
        ),
      );
    } catch (e) {
      debugPrint('Create chat error: $e');

      if (!mounted) return;

      setState(() {
        _isCreatingChat = false;
      });

      _showError('Unable to start chat. Please try again.');
    }
  }

  // ============================================================
  // ERROR
  // ============================================================

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // ============================================================
  // USER RESULT
  // ============================================================

  Widget _buildUserTile(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data();

    if (data == null) {
      return const SizedBox.shrink();
    }

    final uid = data['uid']?.toString() ?? '';

    final name = data['name']?.toString().trim() ?? '';

    final username = data['username']?.toString().trim() ?? '';

    final photoUrl = data['photoUrl']?.toString().trim() ?? '';

    final currentUser = FirebaseAuth.instance.currentUser;

    // Never show ourselves.
    if (currentUser != null && uid == currentUser.uid) {
      return const SizedBox.shrink();
    }

    final displayName = name.isNotEmpty
        ? name
        : username.isNotEmpty
        ? '@$username'
        : 'Gapshap User';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: CircleAvatar(
        radius: 26,
        backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
        child: photoUrl.isEmpty ? const Icon(Icons.person, size: 28) : null,
      ),
      title: Text(
        displayName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: username.isNotEmpty ? Text('@$username') : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: _isCreatingChat ? null : () => _startChat(data),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'New Chat',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // ----------------------------------------------------
          // SEARCH FIELD
          // ----------------------------------------------------

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by username',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchText.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();

                          setState(() {
                            _searchText = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          // ----------------------------------------------------
          // SEARCH RESULT
          // ----------------------------------------------------
          Expanded(
            child: _searchText.isEmpty
                ? const _SearchHint()
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: UserService.searchUsers(_searchText),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error_outline, size: 48),
                                const SizedBox(height: 12),
                                const Text(
                                  'Unable to search users.',
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                FilledButton(
                                  onPressed: () {
                                    setState(() {});
                                  },
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final documents = snapshot.data?.docs ?? [];

                      final currentUser = FirebaseAuth.instance.currentUser;

                      final users = documents.where((doc) {
                        final data = doc.data();

                        final uid = data['uid']?.toString();

                        return currentUser == null || uid != currentUser.uid;
                      }).toList();

                      if (users.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.person_search_outlined, size: 60),
                                SizedBox(height: 16),
                                Text(
                                  'No users found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Try searching with another username.',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: users.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1, indent: 84),
                        itemBuilder: (context, index) {
                          return _buildUserTile(users[index]);
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

// ================================================================
// SEARCH HINT
// ================================================================

class _SearchHint extends StatelessWidget {
  const _SearchHint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_search_outlined,
              size: 70,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 18),
            const Text(
              'Find someone on Gapshap',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Search for a username to start a new conversation.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

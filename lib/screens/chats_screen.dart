import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/chat_lock_service.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import 'chat_screen.dart';
import 'new_chat_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  Map<String, String> _chatPinHashes = {};

  bool _isLoadingPins = true;

  @override
  void initState() {
    super.initState();
    _loadChatLocks();
  }

  // ============================================================
  // LOAD CHAT LOCKS
  // ============================================================

  Future<void> _loadChatLocks() async {
    final hashes = await ChatLockService.loadPinHashes();

    if (!mounted) return;

    setState(() {
      _chatPinHashes = hashes;
      _isLoadingPins = false;
    });
  }

  // ============================================================
  // SAVE CHAT LOCK
  // ============================================================

  Future<void> _saveChatLock(String chatId, String pinHash) async {
    final updated = Map<String, String>.from(_chatPinHashes);

    updated[chatId] = pinHash;

    await ChatLockService.savePinHashes(updated);

    if (!mounted) return;

    setState(() {
      _chatPinHashes = updated;
    });
  }

  // ============================================================
  // REMOVE CHAT LOCK
  // ============================================================

  Future<void> _removeChatLock(String chatId) async {
    final updated = Map<String, String>.from(_chatPinHashes);

    updated.remove(chatId);

    await ChatLockService.savePinHashes(updated);

    if (!mounted) return;

    setState(() {
      _chatPinHashes = updated;
    });
  }

  // ============================================================
  // GET OTHER USER ID
  // ============================================================

  String? _getOtherUserId(Map<String, dynamic> data) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return null;
    }

    final participants = List<String>.from(data['participants'] ?? []);

    for (final uid in participants) {
      if (uid != currentUser.uid) {
        return uid;
      }
    }

    return null;
  }

  // ============================================================
  // OPEN CHAT
  // ============================================================

  Future<void> _openChat(String chatId, String otherUserId) async {
    final userDoc = await UserService.getUserById(otherUserId);

    if (!mounted) return;

    final data = userDoc.data();

    final name = data?['name']?.toString().trim();

    final username = data?['username']?.toString().trim();

    final displayName = name != null && name.isNotEmpty
        ? name
        : username != null && username.isNotEmpty
        ? '@$username'
        : 'Gapshap User';

    final savedPinHash = _chatPinHashes[chatId];

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatId: chatId,
          name: displayName,
          initialPinHash: savedPinHash,
          onPinSet: (pinHash) async {
            await _saveChatLock(chatId, pinHash);
          },
          onLockRemoved: () async {
            await _removeChatLock(chatId);
          },
        ),
      ),
    );

    // Reload lock state after returning.
    await _loadChatLocks();
  }

  // ============================================================
  // NEW CHAT
  // ============================================================

  Future<void> _newChat() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NewChatScreen()),
    );

    // Refresh after creating a chat.
    if (!mounted) return;

    setState(() {});
  }

  // ============================================================
  // CHAT TILE
  // ============================================================

  Widget _buildChatTile(DocumentSnapshot<Map<String, dynamic>> document) {
    final chatId = document.id;

    final data = document.data();

    if (data == null) {
      return const SizedBox.shrink();
    }

    final otherUserId = _getOtherUserId(data);

    if (otherUserId == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: UserService.getUserById(otherUserId),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text('Loading...'),
          );
        }

        final userData = userSnapshot.data?.data();

        final name = userData?['name']?.toString().trim() ?? '';

        final username = userData?['username']?.toString().trim() ?? '';

        final photoUrl = userData?['photoUrl']?.toString().trim() ?? '';

        final displayName = name.isNotEmpty
            ? name
            : username.isNotEmpty
            ? '@$username'
            : 'Gapshap User';

        final lastMessage = data['lastMessage']?.toString() ?? '';

        final locked = _chatPinHashes.containsKey(chatId);

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 5,
          ),
          leading: CircleAvatar(
            radius: 27,
            backgroundImage: photoUrl.isNotEmpty
                ? NetworkImage(photoUrl)
                : null,
            child: photoUrl.isEmpty ? const Icon(Icons.person, size: 28) : null,
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              if (locked)
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(Icons.lock, size: 16),
                ),
            ],
          ),
          subtitle: Text(
            lastMessage.isEmpty ? 'Start a conversation' : lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _openChat(chatId, otherUserId);
          },
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPins) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chats',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'New Chat',
            onPressed: _newChat,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: ChatService.getMyChats(),
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
                    const Icon(Icons.error_outline, size: 50),
                    const SizedBox(height: 12),
                    const Text(
                      'Unable to load chats.',
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

          final chats = snapshot.data?.docs ?? [];

          if (chats.isEmpty) {
            return _EmptyChats(onNewChat: _newChat);
          }

          return ListView.separated(
            itemCount: chats.length,
            separatorBuilder: (_, _) => const Divider(height: 1, indent: 86),
            itemBuilder: (context, index) {
              return _buildChatTile(chats[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _newChat,
        tooltip: 'New Chat',
        child: const Icon(Icons.chat_outlined),
      ),
    );
  }
}

// ================================================================
// EMPTY CHATS
// ================================================================

class _EmptyChats extends StatelessWidget {
  final VoidCallback onNewChat;

  const _EmptyChats({required this.onNewChat});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 75,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 18),
            const Text(
              'No chats yet',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Find someone on Gapshap and start your first conversation.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onNewChat,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('New Chat'),
            ),
          ],
        ),
      ),
    );
  }
}

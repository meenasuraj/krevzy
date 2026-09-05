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

  // Cache user profiles so every rebuild of the chat list does not
  // start a new Firestore read for every tile.
  final Map<String, Map<String, dynamic>> _userCache = {};
  final Map<String, Future<DocumentSnapshot<Map<String, dynamic>>>>
      _userRequests = {};

  bool _isLoadingPins = true;

  // Used to recreate the Firestore stream when Retry is pressed.
  int _streamVersion = 0;

  @override
  void initState() {
    super.initState();
    _loadChatLocks();
  }

  // ===========================================================================
  // CHAT LOCKS
  // ===========================================================================

  Future<void> _loadChatLocks() async {
    try {
      final hashes = await ChatLockService.loadPinHashes();

      if (!mounted) return;

      setState(() {
        _chatPinHashes = hashes;
        _isLoadingPins = false;
      });
    } catch (e) {
      debugPrint('CHAT LOCK LOAD ERROR: $e');

      if (!mounted) return;

      setState(() {
        _chatPinHashes = {};
        _isLoadingPins = false;
      });
    }
  }

  Future<void> _saveChatLock(
    String chatId,
    String pinHash,
  ) async {
    final updated = Map<String, String>.from(_chatPinHashes);

    updated[chatId] = pinHash;

    await ChatLockService.savePinHashes(updated);

    if (!mounted) return;

    setState(() {
      _chatPinHashes = updated;
    });
  }

  Future<void> _removeChatLock(
    String chatId,
  ) async {
    final updated = Map<String, String>.from(_chatPinHashes);

    updated.remove(chatId);

    await ChatLockService.savePinHashes(updated);

    if (!mounted) return;

    setState(() {
      _chatPinHashes = updated;
    });
  }

  // ===========================================================================
  // OTHER USER
  // ===========================================================================

  String? _getOtherUserId(
    Map<String, dynamic> data,
  ) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return null;
    }

    final rawParticipants = data['participants'];

    if (rawParticipants is! List) {
      return null;
    }

    final participants = rawParticipants
        .whereType<String>()
        .toList();

    for (final uid in participants) {
      if (uid != currentUser.uid) {
        return uid;
      }
    }

    return null;
  }

  // ===========================================================================
  // USER CACHE
  // ===========================================================================

  Future<DocumentSnapshot<Map<String, dynamic>>> _loadUserCached(
    String userId,
  ) {
    final existingRequest = _userRequests[userId];

    if (existingRequest != null) {
      return existingRequest;
    }

    final request = UserService.getUserById(userId);

    _userRequests[userId] = request;

    request.then(
      (document) {
        final data = document.data();

        if (data != null) {
          _userCache[userId] = data;
        }

        _userRequests.remove(userId);

        if (mounted) {
          setState(() {});
        }
      },
      onError: (_) {
        _userRequests.remove(userId);

        if (mounted) {
          setState(() {});
        }
      },
    );

    return request;
  }

  // ===========================================================================
  // OPEN CHAT
  // ===========================================================================

  Future<void> _openChat(
    String chatId,
    String otherUserId,
  ) async {
    try {
      final cachedData = _userCache[otherUserId];

      final data = cachedData ??
          (await UserService.getUserById(
            otherUserId,
          ))
              .data();

      if (data != null) {
        _userCache[otherUserId] = data;
      }

      if (!mounted) return;

      final name = data?['name']
          ?.toString()
          .trim();

      final username = data?['username']
          ?.toString()
          .trim();

      final displayName =
          name != null && name.isNotEmpty
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
              await _saveChatLock(
                chatId,
                pinHash,
              );
            },
            onLockRemoved: () async {
              await _removeChatLock(chatId);
            },
          ),
        ),
      );

      if (!mounted) return;

      await _loadChatLocks();
    } catch (e) {
      debugPrint('OPEN CHAT ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to open chat: $e',
          ),
        ),
      );
    }
  }

  // ===========================================================================
  // NEW CHAT
  // ===========================================================================

  Future<void> _newChat() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NewChatScreen(),
      ),
    );

    if (!mounted) return;

    setState(() {
      _streamVersion++;
    });
  }

  // ===========================================================================
  // RETRY
  // ===========================================================================

  void _retryChats() {
    if (!mounted) return;

    setState(() {
      _streamVersion++;
    });
  }

  // ===========================================================================
  // UNREAD BADGE
  // ===========================================================================

  Widget _buildUnreadBadge(
    int unreadCount,
  ) {
    if (unreadCount <= 0) {
      return const SizedBox.shrink();
    }

    final text = unreadCount > 99
        ? '99+'
        : unreadCount.toString();

    return Container(
      constraints: const BoxConstraints(
        minWidth: 22,
        minHeight: 22,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .primary,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ===========================================================================
  // CHAT TILE
  // ===========================================================================

  Widget _buildChatTile(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final chatId = document.id;
    final data = document.data();

    if (data == null) {
      return const SizedBox.shrink();
    }

    final otherUserId = _getOtherUserId(data);

    if (otherUserId == null) {
      return const SizedBox.shrink();
    }

    final unreadCount =
        ChatService.getUnreadCount(data);

    final cachedUserData =
        _userCache[otherUserId];

    if (cachedUserData == null) {
      return FutureBuilder<
          DocumentSnapshot<Map<String, dynamic>>>(
        future: _loadUserCached(otherUserId),
        builder: (
          context,
          userSnapshot,
        ) {
          if (userSnapshot.connectionState ==
              ConnectionState.waiting) {
            return const ListTile(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 5,
              ),
              leading: CircleAvatar(
                radius: 27,
                child: Icon(
                  Icons.person,
                  size: 28,
                ),
              ),
              title: Text('Loading...'),
            );
          }

          if (userSnapshot.hasError) {
            return _buildChatTileContent(
              chatId: chatId,
              otherUserId: otherUserId,
              data: data,
              userData: const {},
              unreadCount: unreadCount,
            );
          }

          final userData =
              userSnapshot.data?.data() ?? {};

          return _buildChatTileContent(
            chatId: chatId,
            otherUserId: otherUserId,
            data: data,
            userData: userData,
            unreadCount: unreadCount,
          );
        },
      );
    }

    return _buildChatTileContent(
      chatId: chatId,
      otherUserId: otherUserId,
      data: data,
      userData: cachedUserData,
      unreadCount: unreadCount,
    );
  }

  Widget _buildChatTileContent({
    required String chatId,
    required String otherUserId,
    required Map<String, dynamic> data,
    required Map<String, dynamic> userData,
    required int unreadCount,
  }) {
    final name =
        userData['name']?.toString().trim() ?? '';

    final username =
        userData['username']?.toString().trim() ?? '';

    final photoUrl =
        userData['photoUrl']?.toString().trim() ?? '';

    final displayName = name.isNotEmpty
        ? name
        : username.isNotEmpty
            ? '@$username'
            : 'Gapshap User';

    final lastMessage =
        data['lastMessage']?.toString() ?? '';

    final lastMessageSenderId =
        data['lastMessageSenderId']?.toString() ?? '';

    final currentUser =
        FirebaseAuth.instance.currentUser;

    final isLastMessageMine =
        currentUser != null &&
            lastMessageSenderId ==
                currentUser.uid;

    final locked =
        _chatPinHashes.containsKey(chatId);

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 5,
      ),
      leading: CircleAvatar(
        radius: 27,
        backgroundImage:
            photoUrl.isNotEmpty
                ? NetworkImage(photoUrl)
                : null,
        child: photoUrl.isEmpty
            ? const Icon(
                Icons.person,
                size: 28,
              )
            : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              displayName,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight:
                    unreadCount > 0
                        ? FontWeight.bold
                        : FontWeight.w600,
              ),
            ),
          ),
          if (locked)
            const Padding(
              padding:
                  EdgeInsets.only(left: 6),
              child: Icon(
                Icons.lock,
                size: 16,
              ),
            ),
        ],
      ),
      subtitle: Text(
        lastMessage.isEmpty
            ? 'Start a conversation'
            : isLastMessageMine
                ? 'You: $lastMessage'
                : lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight:
              unreadCount > 0
                  ? FontWeight.w600
                  : FontWeight.normal,
        ),
      ),
      trailing: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          _buildUnreadBadge(
            unreadCount,
          ),
          if (unreadCount > 0)
            const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right,
          ),
        ],
      ),
      onTap: () {
        _openChat(
          chatId,
          otherUserId,
        );
      },
    );
  }

  // ===========================================================================
  // FIRESTORE ERROR UI
  // ===========================================================================

  Widget _buildFirestoreError(
    Object? error,
  ) {
    final errorText = error?.toString() ??
        'Unknown Firestore error';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .error,
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load chats',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              errorText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _retryChats,
              icon: const Icon(
                Icons.refresh,
              ),
              label: const Text(
                'Retry',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPins) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final currentUser =
        FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Please login to view your chats.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chats',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'New Chat',
            onPressed: _newChat,
            icon: const Icon(
              Icons.edit_outlined,
            ),
          ),
        ],
      ),
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        key: ValueKey(_streamVersion),
        stream: ChatService.getMyChats(),
        builder: (
          context,
          snapshot,
        ) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return _buildFirestoreError(
              snapshot.error,
            );
          }

          final chats =
              snapshot.data?.docs ?? [];

          if (chats.isEmpty) {
            return _EmptyChats(
              onNewChat: _newChat,
            );
          }

          // Sort chats by lastMessageTime on the client.
          // This avoids requiring an additional Firestore
          // composite index.
          final sortedChats =
              List<DocumentSnapshot<
                  Map<String, dynamic>>>.from(
            chats,
          );

          sortedChats.sort(
            (a, b) {
              final aData = a.data();
              final bData = b.data();

              final aTime =
                  aData?['lastMessageTime'];

              final bTime =
                  bData?['lastMessageTime'];

              if (aTime is Timestamp &&
                  bTime is Timestamp) {
                return bTime.compareTo(aTime);
              }

              if (aTime is Timestamp) {
                return -1;
              }

              if (bTime is Timestamp) {
                return 1;
              }

              return 0;
            },
          );

          return RefreshIndicator(
            onRefresh: () async {
              _retryChats();

              await Future<void>.delayed(
                const Duration(
                  milliseconds: 300,
                ),
              );
            },
            child: ListView.separated(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              itemCount: sortedChats.length,
              separatorBuilder: (_, _) =>
                  const Divider(
                height: 1,
                indent: 86,
              ),
              itemBuilder: (
                context,
                index,
              ) {
                return _buildChatTile(
                  sortedChats[index],
                );
              },
            ),
          );
        },
      ),
      floatingActionButton:
          FloatingActionButton(
        onPressed: _newChat,
        tooltip: 'New Chat',
        child: const Icon(
          Icons.chat_outlined,
        ),
      ),
    );
  }
}

// =============================================================================
// EMPTY CHATS
// =============================================================================

class _EmptyChats extends StatelessWidget {
  final VoidCallback onNewChat;

  const _EmptyChats({
    required this.onNewChat,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 75,
              color: Theme.of(context)
                  .colorScheme
                  .primary,
            ),
            const SizedBox(
              height: 18,
            ),
            const Text(
              'No chats yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            const Text(
              'Find someone on Gapshap and start your first conversation.',
              textAlign:
                  TextAlign.center,
            ),
            const SizedBox(
              height: 20,
            ),
            FilledButton.icon(
              onPressed: onNewChat,
              icon: const Icon(
                Icons.edit_outlined,
              ),
              label:
                  const Text('New Chat'),
            ),
          ],
        ),
      ),
    );
  }
}
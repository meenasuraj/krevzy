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

  final Map<String, Map<String, dynamic>> _userCache = {};
  final Map<String, Future<DocumentSnapshot<Map<String, dynamic>>>>
      _userRequests = {};

  bool _isLoadingPins = true;

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

  Future<void> _removeChatLock(String chatId) async {
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

  String? _getOtherUserId(Map<String, dynamic> data) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return null;
    }

    final rawParticipants = data['participants'];

    if (rawParticipants is! List) {
      return null;
    }

    final participants = rawParticipants.whereType<String>().toList();

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
          (await UserService.getUserById(otherUserId)).data();

      if (data != null) {
        _userCache[otherUserId] = data;
      }

      if (!mounted) return;

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

      if (!mounted) return;

      await _loadChatLocks();
    } catch (e) {
      debugPrint('OPEN CHAT ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Unable to open chat: $e'),
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

  Widget _buildUnreadBadge(int unreadCount) {
    if (unreadCount <= 0) {
      return const SizedBox.shrink();
    }

    final text = unreadCount > 99 ? '99+' : unreadCount.toString();

    return Container(
      constraints: const BoxConstraints(
        minWidth: 24,
        minHeight: 24,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ===========================================================================
  // CHAT AVATAR
  // ===========================================================================

  Widget _buildAvatar({
    required String photoUrl,
    required bool locked,
    required bool unread,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 58,
          height: 58,
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: unread
                ? LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.secondary,
                    ],
                  )
                : null,
            color: unread ? null : colorScheme.surfaceContainerHighest,
          ),
          child: CircleAvatar(
            backgroundColor: colorScheme.surfaceContainerHighest,
            backgroundImage:
                photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
            child: photoUrl.isEmpty
                ? Icon(
                    Icons.person_rounded,
                    size: 28,
                    color: colorScheme.onSurfaceVariant,
                  )
                : null,
          ),
        ),
        if (locked)
          Positioned(
            right: -2,
            bottom: -1,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 5,
                    color: Colors.black.withValues(alpha: 0.12),
                  ),
                ],
              ),
              child: Icon(
                Icons.lock_rounded,
                size: 13,
                color: colorScheme.primary,
              ),
            ),
          ),
      ],
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

    final unreadCount = ChatService.getUnreadCount(data);

    final cachedUserData = _userCache[otherUserId];

    if (cachedUserData == null) {
      return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _loadUserCached(otherUserId),
        builder: (
          context,
          userSnapshot,
        ) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingTile();
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

          final userData = userSnapshot.data?.data() ?? {};

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

  Widget _buildLoadingTile() {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 10,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 29,
            backgroundColor: colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.person_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: 130,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 9),
                Container(
                  height: 11,
                  width: 190,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTileContent({
    required String chatId,
    required String otherUserId,
    required Map<String, dynamic> data,
    required Map<String, dynamic> userData,
    required int unreadCount,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    final name = userData['name']?.toString().trim() ?? '';
    final username = userData['username']?.toString().trim() ?? '';
    final photoUrl = userData['photoUrl']?.toString().trim() ?? '';

    final displayName = name.isNotEmpty
        ? name
        : username.isNotEmpty
            ? '@$username'
            : 'Gapshap User';

    final lastMessage = data['lastMessage']?.toString() ?? '';

    final lastMessageSenderId =
        data['lastMessageSenderId']?.toString() ?? '';

    final currentUser = FirebaseAuth.instance.currentUser;

    final isLastMessageMine =
        currentUser != null && lastMessageSenderId == currentUser.uid;

    final locked = _chatPinHashes.containsKey(chatId);
    final unread = unreadCount > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _openChat(chatId, otherUserId);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 11,
          ),
          child: Row(
            children: [
              _buildAvatar(
                photoUrl: photoUrl,
                locked: locked,
                unread: unread,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  unread ? FontWeight.w800 : FontWeight.w700,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ),
                        if (locked)
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Icon(
                              Icons.lock_rounded,
                              size: 15,
                              color: colorScheme.primary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lastMessage.isEmpty
                                ? 'Start a conversation'
                                : isLastMessageMine
                                    ? 'You: $lastMessage'
                                    : lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.2,
                              fontWeight:
                                  unread ? FontWeight.w600 : FontWeight.w400,
                              color: unread
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        if (unread) ...[
                          const SizedBox(width: 10),
                          _buildUnreadBadge(unreadCount),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 21,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // FIRESTORE ERROR UI
  // ===========================================================================

  Widget _buildFirestoreError(Object? error) {
    final colorScheme = Theme.of(context).colorScheme;

    final errorText = error?.toString() ?? 'Unknown Firestore error';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                size: 42,
                color: colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Unable to load chats',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              errorText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _retryChats,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // HEADER
  // ===========================================================================

  Widget _buildHeader() {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Messages',
                  style: TextStyle(
                    fontSize: 29,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Your conversations on Gapshap',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _newChat,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  Icons.edit_rounded,
                  color: colorScheme.onPrimaryContainer,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
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

    final currentUser = FirebaseAuth.instance.currentUser;

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

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                key: ValueKey(_streamVersion),
                stream: ChatService.getMyChats(),
                builder: (
                  context,
                  snapshot,
                ) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return _buildFirestoreError(snapshot.error);
                  }

                  final chats = snapshot.data?.docs ?? [];

                  if (chats.isEmpty) {
                    return _EmptyChats(
                      onNewChat: _newChat,
                    );
                  }

                  // Sort by lastMessageTime on the client.
                  // This avoids requiring another Firestore composite index.
                  final sortedChats =
                      List<DocumentSnapshot<Map<String, dynamic>>>.from(
                    chats,
                  );

                  sortedChats.sort(
                    (a, b) {
                      final aData = a.data();
                      final bData = b.data();

                      final aTime = aData?['lastMessageTime'];
                      final bTime = bData?['lastMessageTime'];

                      if (aTime is Timestamp && bTime is Timestamp) {
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
                    color: colorScheme.primary,
                    onRefresh: () async {
                      _retryChats();

                      await Future<void>.delayed(
                        const Duration(milliseconds: 300),
                      );
                    },
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(
                        top: 4,
                        bottom: 100,
                      ),
                      itemCount: sortedChats.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        thickness: 0.7,
                        indent: 90,
                        endIndent: 18,
                        color: colorScheme.outlineVariant
                            .withValues(alpha: 0.45),
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
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newChat,
        tooltip: 'New Chat',
        icon: const Icon(Icons.chat_rounded),
        label: const Text(
          'New Chat',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 30, 28, 120),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.secondaryContainer,
                  ],
                ),
              ),
              child: Icon(
                Icons.forum_rounded,
                size: 52,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              'No conversations yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              'Find someone on Gapshap and start your first conversation.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 25),
            FilledButton.icon(
              onPressed: onNewChat,
              icon: const Icon(Icons.edit_rounded),
              label: const Text(
                'Start a New Chat',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
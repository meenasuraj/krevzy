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

  void _clearSearch() {
    _searchTimer?.cancel();
    _searchController.clear();

    setState(() {
      _searchText = '';
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // USER RESULT
  // ============================================================

  Widget _buildUserTile(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    if (data == null) {
      return const SizedBox.shrink();
    }

    final uid = data['uid']?.toString() ?? '';
    final name = data['name']?.toString().trim() ?? '';
    final username = data['username']?.toString().trim() ?? '';
    final photoUrl = data['photoUrl']?.toString().trim() ?? '';

    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null && uid == currentUser.uid) {
      return const SizedBox.shrink();
    }

    final displayName = name.isNotEmpty
        ? name
        : username.isNotEmpty
        ? '@$username'
        : 'Gapshap User';

    return _UserResultCard(
      displayName: displayName,
      username: username,
      photoUrl: photoUrl,
      isLoading: _isCreatingChat,
      onTap: () => _startChat(data),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.surface,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        titleSpacing: 4,
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.chat_bubble_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New Chat',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Start a conversation',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ----------------------------------------------------
          // SEARCH HEADER
          // ----------------------------------------------------

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.secondaryContainer,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.person_add_alt_1_rounded,
                        color: colorScheme.onPrimaryContainer,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Find someone',
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Search by username and start chatting instantly.',
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer.withValues(
                        alpha: 0.75,
                      ),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _searchController,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search username...',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        size: 22,
                      ),
                      suffixIcon: _searchText.isNotEmpty
                          ? IconButton(
                              tooltip: 'Clear',
                              onPressed: _clearSearch,
                              icon: const Icon(
                                Icons.close_rounded,
                              ),
                            )
                          : null,
                      filled: true,
                      fillColor: colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 15,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(
                          color: colorScheme.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ----------------------------------------------------
          // SEARCH RESULTS
          // ----------------------------------------------------

          Expanded(
            child: _searchText.isEmpty
                ? const _SearchHint()
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: UserService.searchUsers(_searchText),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const _SearchingState();
                      }

                      if (snapshot.hasError) {
                        return _SearchError(
                          onRetry: () {
                            setState(() {});
                          },
                        );
                      }

                      final documents = snapshot.data?.docs ?? [];

                      final currentUser = FirebaseAuth.instance.currentUser;

                      final users = documents.where((doc) {
                        final data = doc.data();
                        final uid = data['uid']?.toString();

                        return currentUser == null ||
                            uid != currentUser.uid;
                      }).toList();

                      if (users.isEmpty) {
                        return const _NoUsersFound();
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: users.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 10),
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
// USER RESULT CARD
// ================================================================

class _UserResultCard extends StatelessWidget {
  final String displayName;
  final String username;
  final String photoUrl;
  final bool isLoading;
  final VoidCallback onTap;

  const _UserResultCard({
    required this.displayName,
    required this.username,
    required this.photoUrl,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              _UserAvatar(
                photoUrl: photoUrl,
                displayName: displayName,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (username.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        '@$username',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: isLoading
                    ? const SizedBox(
                        key: ValueKey('loading'),
                        width: 38,
                        height: 38,
                        child: Padding(
                          padding: EdgeInsets.all(9),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                          ),
                        ),
                      )
                    : Container(
                        key: const ValueKey('arrow'),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: colorScheme.onPrimaryContainer,
                          size: 21,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// USER AVATAR
// ================================================================

class _UserAvatar extends StatelessWidget {
  final String photoUrl;
  final String displayName;

  const _UserAvatar({
    required this.photoUrl,
    required this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final initial = displayName.isNotEmpty
        ? displayName.replaceFirst('@', '')[0].toUpperCase()
        : 'G';

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(2),
      child: ClipOval(
        child: photoUrl.isNotEmpty
            ? Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) {
                  return _InitialAvatar(initial: initial);
                },
              )
            : _InitialAvatar(initial: initial),
      ),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  final String initial;

  const _InitialAvatar({
    required this.initial,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surface,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: colorScheme.primary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.secondaryContainer,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_search_rounded,
                size: 48,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Find someone on Gapshap',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Search for a username to start a new conversation.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 15,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Private conversations',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// SEARCHING STATE
// ================================================================

class _SearchingState extends StatelessWidget {
  const _SearchingState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            strokeWidth: 3,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Finding people...',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// NO USERS
// ================================================================

class _NoUsersFound extends StatelessWidget {
  const _NoUsersFound();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 58,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            const Text(
              'No users found',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Try searching with another username.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// SEARCH ERROR
// ================================================================

class _SearchError extends StatelessWidget {
  final VoidCallback onRetry;

  const _SearchError({
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                size: 36,
                color: colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Unable to search users',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Something went wrong while searching. Please try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
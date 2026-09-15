import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/chat_room_service.dart';
import 'add_room_rule_screen.dart';
import 'room_rules_screen.dart';

class ChatRoomScreen extends StatefulWidget {
  final String roomId;

  const ChatRoomScreen({super.key, required this.roomId});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final ChatRoomService _service = ChatRoomService.instance;

  final TextEditingController _messageController = TextEditingController();

  final FocusNode _messageFocusNode = FocusNode();

  bool _isMember = false;
  bool _checkingMembership = true;
  bool _joining = false;
  bool _leaving = false;
  bool _sending = false;

  String? _role;

  @override
  void initState() {
    super.initState();
    _checkMembership();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  // ============================================================
  // MEMBERSHIP
  // ============================================================

  Future<void> _checkMembership() async {
    try {
      final member = await _service.isMember(widget.roomId);

      String? role;

      if (member) {
        role = await _service.getMemberRole(widget.roomId);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isMember = member;
        _role = role;
        _checkingMembership = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _checkingMembership = false;
      });

      _showError('Unable to check room membership: ${_cleanError(error)}');
    }
  }

  Future<void> _joinRoom() async {
    if (_joining) {
      return;
    }

    setState(() {
      _joining = true;
    });

    try {
      await _service.joinRoom(widget.roomId);

      if (!mounted) {
        return;
      }

      setState(() {
        _isMember = true;
        _role = 'member';
      });

      _showMessage('You joined the room.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showError('Could not join room: ${_cleanError(error)}');
    } finally {
      if (mounted) {
        setState(() {
          _joining = false;
        });
      }
    }
  }

  Future<void> _leaveRoom() async {
    if (_leaving) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Leave room?'),
          content: const Text(
            'You will need to join again to participate in this room.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Leave'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _leaving = true;
    });

    try {
      await _service.leaveRoom(widget.roomId);

      if (!mounted) {
        return;
      }

      setState(() {
        _isMember = false;
        _role = null;
      });

      _showMessage('You left the room.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showError('Could not leave room: ${_cleanError(error)}');
    } finally {
      if (mounted) {
        setState(() {
          _leaving = false;
        });
      }
    }
  }

  // ============================================================
  // MESSAGES
  // ============================================================

  Future<void> _sendMessage() async {
    if (_sending) {
      return;
    }

    final text = _messageController.text.trim();

    if (text.isEmpty) {
      return;
    }

    if (!_isMember) {
      _showError('Join this room to send messages.');
      return;
    }

    setState(() {
      _sending = true;
    });

    try {
      await _service.sendMessage(roomId: widget.roomId, text: text);

      _messageController.clear();

      if (mounted) {
        _messageFocusNode.requestFocus();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showError('Message could not be sent: ${_cleanError(error)}');
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  // ============================================================
  // RULES
  // ============================================================

  Future<void> _openRules(String roomName) async {
    String? role;

    try {
      role = await _service.getMemberRole(widget.roomId);
    } catch (_) {
      role = _role;
    }

    if (!mounted) {
      return;
    }

    final canManageRules = role == 'owner' || role == 'moderator';

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoomRulesScreen(
          roomId: widget.roomId,
          roomName: roomName,
          canManageRules: canManageRules,
        ),
      ),
    );
  }

  Future<void> _addRule(String roomName) async {
    if (!_canManageRules) {
      _showError('Only the room owner or moderator can add active rules.');
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddRoomRuleScreen(
          roomId: widget.roomId,
          roomName: roomName,
          isSuggestion: false,
        ),
      ),
    );
  }

  Future<void> _suggestRule(String roomName) async {
    if (!_isMember) {
      _showError('Join the room before suggesting a rule.');
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddRoomRuleScreen(
          roomId: widget.roomId,
          roomName: roomName,
          isSuggestion: true,
        ),
      ),
    );
  }

  bool get _canManageRules {
    return _role == 'owner' || _role == 'moderator';
  }

  // ============================================================
  // CHALLENGES
  // ============================================================

  void _openChallenges(String roomName) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.78,
          child: _ChallengesSheet(
            roomId: widget.roomId,
            roomName: roomName,
            service: _service,
            isMember: _isMember,
          ),
        );
      },
    );
  }

  // ============================================================
  // ROOM INFORMATION
  // ============================================================

  void _showRoomInfo({
    required String roomName,
    required String category,
    required String description,
    required int memberCount,
    required bool isPublic,
  }) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      child: Icon(Icons.forum_rounded, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        roomName,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _InfoRow(
                  icon: Icons.category_outlined,
                  title: 'Category',
                  value: category,
                ),
                _InfoRow(
                  icon: Icons.people_outline,
                  title: 'Members',
                  value: '$memberCount',
                ),
                _InfoRow(
                  icon: isPublic ? Icons.public : Icons.lock_outline,
                  title: 'Visibility',
                  value: isPublic ? 'Public' : 'Private',
                ),
                if (_role != null)
                  _InfoRow(
                    icon: Icons.badge_outlined,
                    title: 'Your role',
                    value: _role!,
                  ),
                const SizedBox(height: 12),
                const Text(
                  'About this room',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 7),
                Text(
                  description.isEmpty
                      ? 'No description available.'
                      : description,
                  style: TextStyle(
                    height: 1.45,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // MORE MENU
  // ============================================================

  void _showMoreMenu({
    required String roomName,
    required String category,
    required String description,
    required int memberCount,
    required bool isPublic,
  }) {
    final canManageRules = _canManageRules;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // -----------------------------
              // RULES
              // -----------------------------

              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.rule_rounded)),
                title: const Text(
                  'Room Rules',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('View active community rules'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  _openRules(roomName);
                },
              ),

              // -----------------------------
              // MEMBER SUGGESTION
              // -----------------------------
              if (_isMember && !canManageRules)
                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.lightbulb_outline),
                  ),
                  title: const Text(
                    'Suggest a Rule',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Suggest a new room rule'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    _suggestRule(roomName);
                  },
                ),

              // -----------------------------
              // OWNER / MODERATOR ADD RULE
              // -----------------------------
              if (canManageRules)
                ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.add_rounded)),
                  title: const Text(
                    'Add Rule',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Publish a new active rule'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    _addRule(roomName);
                  },
                ),

              // -----------------------------
              // CHALLENGES
              // -----------------------------
              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.emoji_events_outlined),
                ),
                title: const Text(
                  'Challenges',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('View room challenges'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  _openChallenges(roomName);
                },
              ),

              // -----------------------------
              // ROOM INFORMATION
              // -----------------------------
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.info_outline)),
                title: const Text(
                  'Room Information',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('View room details'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);

                  _showRoomInfo(
                    roomName: roomName,
                    category: category,
                    description: description,
                    memberCount: memberCount,
                    isPublic: isPublic,
                  );
                },
              ),

              // -----------------------------
              // LEAVE ROOM
              // -----------------------------
              if (_isMember && _role != 'owner')
                ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.logout)),
                  title: const Text(
                    'Leave Room',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Leave this community'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    _leaveRoom();
                  },
                ),

              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // ERROR / MESSAGE HELPERS
  // ============================================================

  String _cleanError(Object error) {
    final text = error.toString();

    if (text.startsWith('Exception: ')) {
      return text.substring(11);
    }

    if (text.startsWith('Bad state: ')) {
      return text.substring(11);
    }

    return text;
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _service.watchRoom(widget.roomId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('KREVZY Room')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load room.\n\n'
                  '${_cleanError(snapshot.error!)}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        final document = snapshot.data;

        if (document == null || !document.exists) {
          return const Scaffold(body: Center(child: Text('Room not found.')));
        }

        final room = document.data() ?? <String, dynamic>{};

        final roomName = room['name']?.toString() ?? 'KREVZY Room';

        final category = room['category']?.toString() ?? 'Other';

        final description = room['description']?.toString() ?? '';

        final memberCount = _readInt(room['memberCount']);

        final isPublic = room['isPublic'] == true;

        return Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  roomName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$memberCount members • $category',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            actions: [
              // RULES

              IconButton(
                tooltip: 'Rules',
                icon: const Icon(Icons.rule_rounded),
                onPressed: () {
                  _openRules(roomName);
                },
              ),

              // CHALLENGES
              IconButton(
                tooltip: 'Challenges',
                icon: const Icon(Icons.emoji_events_outlined),
                onPressed: () {
                  _openChallenges(roomName);
                },
              ),

              // MORE
              IconButton(
                tooltip: 'More',
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  _showMoreMenu(
                    roomName: roomName,
                    category: category,
                    description: description,
                    memberCount: memberCount,
                    isPublic: isPublic,
                  );
                },
              ),
            ],
          ),

          body: SafeArea(
            child: Column(
              children: [
                // ==================================================
                // JOIN / MEMBER STATUS
                // ==================================================

                if (_checkingMembership)
                  const LinearProgressIndicator(minHeight: 2),

                if (!_checkingMembership && !_isMember)
                  _JoinRoomBanner(joining: _joining, onJoin: _joinRoom),

                if (!_checkingMembership && _isMember)
                  _MemberStatusBanner(
                    role: _role ?? 'member',
                    leaving: _leaving,
                    onLeave: _role == 'owner' ? null : _leaveRoom,
                  ),

                // ==================================================
                // CONTENT
                // ==================================================
                Expanded(
                  child: _isMember
                      ? _buildMemberContent(roomName)
                      : _buildGuestContent(roomName),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMemberContent(String roomName) {
    return Column(
      children: [
        // Quick actions

        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: _MemberActions(
            role: _role ?? 'member',
            onRules: () {
              _openRules(roomName);
            },
            onChallenges: () {
              _openChallenges(roomName);
            },
          ),
        ),

        // Messages
        Expanded(child: _buildMessages()),

        // Composer
        _buildComposer(),
      ],
    );
  }

  Widget _buildGuestContent(String roomName) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 40),
      children: [
        Icon(
          Icons.forum_outlined,
          size: 72,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 18),
        Text(
          'Join $roomName',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Join this room to participate in the '
          'conversation, view challenges and '
          'suggest community rules.',
          textAlign: TextAlign.center,
          style: TextStyle(
            height: 1.5,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () {
            _openRules(roomName);
          },
          icon: const Icon(Icons.rule_rounded),
          label: const Text('View Rules'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () {
            _openChallenges(roomName);
          },
          icon: const Icon(Icons.emoji_events_outlined),
          label: const Text('View Challenges'),
        ),
      ],
    );
  }

  // ============================================================
  // MESSAGES LIST
  // ============================================================

  Widget _buildMessages() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _service.watchMessages(widget.roomId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Unable to load messages.\n\n'
                '${_cleanError(snapshot.error!)}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final messages = snapshot.data?.docs ?? [];

        if (messages.isEmpty) {
          return const _EmptyMessages();
        }

        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final document = messages[index];

            final data = document.data();

            final senderId = data['senderId']?.toString() ?? '';

            final text = data['text']?.toString() ?? '';

            final createdAt = data['createdAt'];

            return _MessageBubble(
              senderId: senderId,
              text: text,
              createdAt: createdAt,
            );
          },
        );
      },
    );
  }

  // ============================================================
  // COMPOSER
  // ============================================================

  Widget _buildComposer() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 7, 10, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                focusNode: _messageFocusNode,
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Write a message...',
                  filled: true,
                  prefixIcon: const Icon(Icons.chat_bubble_outline),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) {
                  if (!_sending) {
                    _sendMessage();
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 50,
              height: 50,
              child: FilledButton(
                onPressed: _sending ? null : _sendMessage,
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: const CircleBorder(),
                ),
                child: _sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  int _readInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

// ================================================================
// JOIN ROOM BANNER
// ================================================================

class _JoinRoomBanner extends StatelessWidget {
  final bool joining;
  final VoidCallback onJoin;

  const _JoinRoomBanner({required this.joining, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      child: Row(
        children: [
          CircleAvatar(
            child: Icon(
              Icons.group_add_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You are not a member',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 3),
                Text(
                  'Join this room to participate.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: joining ? null : onJoin,
            child: joining
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Join'),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// MEMBER STATUS
// ================================================================

class _MemberStatusBanner extends StatelessWidget {
  final String role;
  final bool leaving;
  final VoidCallback? onLeave;

  const _MemberStatusBanner({
    required this.role,
    required this.leaving,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    final isOwner = role == 'owner';
    final isModerator = role == 'moderator';

    final label = isOwner
        ? 'Room owner'
        : isModerator
        ? 'Moderator'
        : 'Member';

    final icon = isOwner
        ? Icons.workspace_premium_outlined
        : isModerator
        ? Icons.admin_panel_settings_outlined
        : Icons.check_circle_outline;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Row(
        children: [
          Icon(icon, size: 19),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (onLeave != null)
            TextButton(
              onPressed: leaving ? null : onLeave,
              child: leaving
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Leave'),
            ),
        ],
      ),
    );
  }
}

// ================================================================
// MEMBER ACTIONS
// ================================================================

class _MemberActions extends StatelessWidget {
  final String role;
  final VoidCallback onRules;
  final VoidCallback onChallenges;

  const _MemberActions({
    required this.role,
    required this.onRules,
    required this.onChallenges,
  });

  @override
  Widget build(BuildContext context) {
    final isManager = role == 'owner' || role == 'moderator';

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onRules,
            icon: const Icon(Icons.rule_rounded, size: 19),
            label: const Text('Rules'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onChallenges,
            icon: const Icon(Icons.emoji_events_outlined, size: 19),
            label: const Text('Challenges'),
          ),
        ),
        if (isManager) ...[
          const SizedBox(width: 10),
          Tooltip(
            message: 'Manage Rules',
            child: IconButton.filled(
              onPressed: onRules,
              icon: const Icon(Icons.admin_panel_settings_outlined),
            ),
          ),
        ],
      ],
    );
  }
}

// ================================================================
// EMPTY MESSAGES
// ================================================================

class _EmptyMessages extends StatelessWidget {
  const _EmptyMessages();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.forum_outlined,
              size: 62,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 14),
            const Text(
              'No messages yet',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 7),
            Text(
              'Start the conversation.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// MESSAGE BUBBLE
// ================================================================

class _MessageBubble extends StatelessWidget {
  final String senderId;
  final String text;
  final dynamic createdAt;

  const _MessageBubble({
    required this.senderId,
    required this.text,
    required this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    final isMine =
        senderId.isNotEmpty && currentUid != null && senderId == currentUid;

    final time = _formatTime(createdAt);

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMine ? 18 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 18),
          ),
          color: isMine
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: Column(
          crossAxisAlignment: isMine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(text, style: const TextStyle(fontSize: 15, height: 1.35)),
            if (time.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                time,
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(dynamic value) {
    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    }

    if (date == null) {
      return '';
    }

    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;

    final minute = date.minute.toString().padLeft(2, '0');

    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }
}

// ================================================================
// INFO ROW
// ================================================================

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 21),
          const SizedBox(width: 12),
          Text('$title: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

// ================================================================
// CHALLENGES SHEET
// ================================================================

class _ChallengesSheet extends StatelessWidget {
  final String roomId;
  final String roomName;
  final ChatRoomService service;
  final bool isMember;

  const _ChallengesSheet({
    required this.roomId,
    required this.roomName,
    required this.service,
    required this.isMember,
  });

  int _readInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatDeadline(dynamic value) {
    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    }

    if (date == null) {
      return '';
    }

    final day = date.day.toString().padLeft(2, '0');

    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
          child: Row(
            children: [
              const CircleAvatar(child: Icon(Icons.emoji_events)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Room Challenges',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      roomName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: service.watchChallenges(roomId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Unable to load challenges.\n\n'
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final challenges = snapshot.data?.docs ?? [];

              if (challenges.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.emoji_events_outlined, size: 55),
                        SizedBox(height: 14),
                        Text(
                          'No challenges yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Challenges created for this room '
                          'will appear here.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: challenges.length,
                itemBuilder: (context, index) {
                  final document = challenges[index];

                  final data = document.data();

                  final title = data['title']?.toString() ?? 'Challenge';

                  final description = data['description']?.toString() ?? '';

                  final rewardXp = _readInt(data['rewardXp']);

                  final deadline = _formatDeadline(data['deadline']);

                  final status = data['status']?.toString() ?? 'active';

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                child: Icon(Icons.emoji_events_outlined),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              description,
                              style: const TextStyle(height: 1.4),
                            ),
                          ],

                          const SizedBox(height: 12),

                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Chip(
                                avatar: const Icon(Icons.bolt, size: 17),
                                label: Text('$rewardXp XP'),
                              ),
                              if (deadline.isNotEmpty)
                                Chip(
                                  avatar: const Icon(
                                    Icons.calendar_today_outlined,
                                    size: 16,
                                  ),
                                  label: Text(deadline),
                                ),
                              Chip(label: Text(status.toUpperCase())),
                            ],
                          ),

                          if (isMember) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  _showEvidenceInfo(context, document.id);
                                },
                                icon: const Icon(Icons.upload_file_outlined),
                                label: const Text('Submit Evidence'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showEvidenceInfo(BuildContext context, String challengeId) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Challenge Evidence'),
          content: const Text(
            'Evidence upload can be connected to '
            'Firebase Storage here. Submissions should '
            'remain pending until they are reviewed.',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/chat_room_service.dart';
import 'add_room_rule_screen.dart';
import 'room_rules_screen.dart';

class KrevzyRoomScreen extends StatefulWidget {
  final String roomId;

  const KrevzyRoomScreen({super.key, required this.roomId});

  @override
  State<KrevzyRoomScreen> createState() => _KrevzyRoomScreenState();
}

class _KrevzyRoomScreenState extends State<KrevzyRoomScreen> {
  final ChatRoomService _service = ChatRoomService.instance;
  final TextEditingController _messageController = TextEditingController();

  bool _isMember = false;
  bool _checkingMember = true;
  bool _joining = false;
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
    super.dispose();
  }

  // ============================================================
  // MEMBERSHIP
  // ============================================================

  Future<void> _checkMembership() async {
    try {
      final member = await _service.isMember(widget.roomId);
      final role = await _service.getMemberRole(widget.roomId);

      if (!mounted) return;

      setState(() {
        _isMember = member;
        _role = role;
        _checkingMember = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isMember = false;
        _role = null;
        _checkingMember = false;
      });
    }
  }

  Future<void> _joinRoom() async {
    if (_joining) return;

    setState(() {
      _joining = true;
    });

    try {
      await _service.joinRoom(widget.roomId);
      await _checkMembership();

      if (!mounted) return;

      _showMessage('You joined the room.');
    } catch (e) {
      if (!mounted) return;
      _showMessage(_cleanError(e));
    } finally {
      if (mounted) {
        setState(() {
          _joining = false;
        });
      }
    }
  }

  Future<void> _leaveRoom() async {
    if (!_isMember || _role == 'owner') return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Leave Room?'),
          content: const Text('You can join this public room again later.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Leave'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _service.leaveRoom(widget.roomId);
      await _checkMembership();

      if (!mounted) return;

      _showMessage('You left the room.');
    } catch (e) {
      if (!mounted) return;
      _showMessage(_cleanError(e));
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty || _sending || !_isMember) return;

    setState(() {
      _sending = true;
    });

    try {
      await _service.sendMessage(roomId: widget.roomId, text: text);

      if (mounted) {
        _messageController.clear();
      }
    } catch (e) {
      if (mounted) {
        _showMessage(_cleanError(e));
      }
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
      role = null;
    }

    if (!mounted) return;

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
      _showMessage('Join the room before suggesting a rule.');
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

  // ============================================================
  // CHALLENGES
  // ============================================================

  void _openChallenges({
    required String roomName,
    required bool allowMemberChallenges,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.88,
          child: _ChallengesSheet(
            roomId: widget.roomId,
            roomName: roomName,
            service: _service,
            isMember: _isMember,
            role: _role,
            allowMemberChallenges: allowMemberChallenges,
            onCreateChallenge: () {
              Navigator.pop(sheetContext);
              _openCreateChallenge(roomName: roomName);
            },
          ),
        );
      },
    );
  }

  Future<void> _openCreateChallenge({required String roomName}) async {
    if (!_isMember) {
      _showMessage('Join the room first.');
      return;
    }

    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final rewardController = TextEditingController(text: '100');

    DateTime? deadline;

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (sheetContext) {
          bool saving = false;

          return StatefulBuilder(
            builder: (context, setSheetState) {
              Future<void> saveChallenge() async {
                if (saving) return;

                final title = titleController.text.trim();
                final description = descriptionController.text.trim();

                final reward = int.tryParse(rewardController.text.trim()) ?? 0;

                if (title.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enter a challenge title.')),
                  );
                  return;
                }

                if (description.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Enter a challenge description.'),
                    ),
                  );
                  return;
                }

                if (reward <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reward XP must be greater than 0.'),
                    ),
                  );
                  return;
                }

                setSheetState(() {
                  saving = true;
                });

                try {
                  await _service.createChallenge(
                    roomId: widget.roomId,
                    title: title,
                    description: description,
                    rewardXp: reward,
                    deadline: deadline,
                  );

                  if (!sheetContext.mounted) return;

                  Navigator.pop(sheetContext);

                  if (mounted) {
                    _showMessage('Challenge created successfully.');
                  }
                } catch (e) {
                  if (!sheetContext.mounted) return;

                  setSheetState(() {
                    saving = false;
                  });

                  ScaffoldMessenger.of(sheetContext)
                      .showSnackBar(SnackBar(content: Text(_cleanError(e))));
                }
              }

              Future<void> chooseDeadline() async {
                final now = DateTime.now();

                final pickedDate = await showDatePicker(
                  context: sheetContext,
                  firstDate: now,
                  lastDate: DateTime(now.year + 5),
                  initialDate: now,
                );

                if (pickedDate == null || !sheetContext.mounted) {
                  return;
                }

                final pickedTime = await showTimePicker(
                  context: sheetContext,
                  initialTime: TimeOfDay.now(),
                );

                if (pickedTime == null) return;

                setSheetState(() {
                  deadline = DateTime(
                    pickedDate.year,
                    pickedDate.month,
                    pickedDate.day,
                    pickedTime.hour,
                    pickedTime.minute,
                  );
                });
              }

              return SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 8,
                    bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              child: Icon(
                                Icons.emoji_events_rounded,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Create Challenge',
                                    style: TextStyle(
                                      fontSize: 21,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    roomName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),

                        TextField(
                          controller: titleController,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Challenge title',
                            hintText: 'Example: Complete Level 10',
                            prefixIcon: const Icon(Icons.flag_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        TextField(
                          controller: descriptionController,
                          minLines: 3,
                          maxLines: 6,
                          decoration: InputDecoration(
                            labelText: 'Challenge description',
                            hintText: 'Explain what users need to complete.',
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(bottom: 52),
                              child: Icon(Icons.description_outlined),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        TextField(
                          controller: rewardController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Reward XP',
                            hintText: '100',
                            prefixIcon: const Icon(Icons.stars_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        InkWell(
                          onTap: saving ? null : chooseDeadline,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Deadline',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        deadline == null
                                            ? 'No deadline'
                                            : _formatDateTime(deadline!),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .secondaryContainer
                                .withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline, size: 20),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Challenge submissions should be reviewed before XP or rewards are granted. The room screen does not directly award XP.',
                                  style: TextStyle(fontSize: 12, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: saving ? null : saveChallenge,
                            icon: saving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.add_task_rounded),
                            label: Text(
                              saving ? 'Creating...' : 'Create Challenge',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    } finally {
      titleController.dispose();
      descriptionController.dispose();
      rewardController.dispose();
    }
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
    required bool allowMemberChallenges,
    required bool allowMemberRules,
  }) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        child: Icon(_categoryIcon(category), size: 28),
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
                  _InfoRow(
                    icon: Icons.emoji_events_outlined,
                    title: 'Member challenges',
                    value: allowMemberChallenges
                        ? 'Allowed'
                        : 'Owner / moderator only',
                  ),
                  _InfoRow(
                    icon: Icons.rule_outlined,
                    title: 'Member rules',
                    value: allowMemberRules
                        ? 'Allowed'
                        : 'Owner / moderator only',
                  ),

                  if (_role != null)
                    _InfoRow(
                      icon: Icons.badge_outlined,
                      title: 'Your role',
                      value: _role!,
                    ),

                  const SizedBox(height: 14),

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
    required bool allowMemberChallenges,
    required bool allowMemberRules,
  }) {
    final canManageRules = _role == 'owner' || _role == 'moderator';

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.rule_rounded)),
                title: const Text(
                  'Room Rules',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('View active community rules'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openRules(roomName);
                },
              ),

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
                    Navigator.pop(sheetContext);
                    _suggestRule(roomName);
                  },
                ),

              if (canManageRules)
                ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.add)),
                  title: const Text(
                    'Add Rule',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Publish a new active rule'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _addRule(roomName);
                  },
                ),

              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.emoji_events_outlined),
                ),
                title: const Text(
                  'Challenges',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Create and view room challenges'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openChallenges(
                    roomName: roomName,
                    allowMemberChallenges: allowMemberChallenges,
                  );
                },
              ),

              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.info_outline)),
                title: const Text(
                  'Room Information',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('View room details'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(sheetContext);

                  _showRoomInfo(
                    roomName: roomName,
                    category: category,
                    description: description,
                    memberCount: memberCount,
                    isPublic: isPublic,
                    allowMemberChallenges: allowMemberChallenges,
                    allowMemberRules: allowMemberRules,
                  );
                },
              ),

              if (_isMember && _role != 'owner')
                ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.logout)),
                  title: const Text(
                    'Leave Room',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(sheetContext);
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
                  '${snapshot.error}',
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

        final room = document.data() ?? {};

        final roomName = room['name']?.toString() ?? 'KREVZY Room';

        final category = room['category']?.toString() ?? 'Other';

        final description = room['description']?.toString() ?? '';

        final memberCount = _readInt(room['memberCount']);

        final isPublic = room['isPublic'] == true;

        final allowMemberChallenges = room['allowMemberChallenges'] == true;

        final allowMemberRules = room['allowMemberRules'] == true;

        final canCreateChallenge =
            _isMember &&
            (_role == 'owner' || _role == 'moderator' || allowMemberChallenges);

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
              IconButton(
                tooltip: 'Rules',
                icon: const Icon(Icons.rule_rounded),
                onPressed: () {
                  _openRules(roomName);
                },
              ),
              IconButton(
                tooltip: 'Challenges',
                icon: const Icon(Icons.emoji_events_outlined),
                onPressed: () {
                  _openChallenges(
                    roomName: roomName,
                    allowMemberChallenges: allowMemberChallenges,
                  );
                },
              ),
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
                    allowMemberChallenges: allowMemberChallenges,
                    allowMemberRules: allowMemberRules,
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              _RoomHeader(
                roomName: roomName,
                category: category,
                description: description,
                memberCount: memberCount,
              ),

              if (!_isMember && !_checkingMember)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: _joining ? null : _joinRoom,
                      icon: _joining
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.group_add),
                      label: Text(_joining ? 'Joining...' : 'Join Room'),
                    ),
                  ),
                ),

              if (_isMember)
                _MemberActions(
                  role: _role ?? 'member',
                  onRules: () {
                    _openRules(roomName);
                  },
                  onChallenges: () {
                    _openChallenges(
                      roomName: roomName,
                      allowMemberChallenges: allowMemberChallenges,
                    );
                  },
                  canCreateChallenge: canCreateChallenge,
                  onCreateChallenge: () {
                    _openCreateChallenge(roomName: roomName);
                  },
                ),

              Expanded(child: _buildMessages()),

              if (_isMember) _buildComposer(),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // MESSAGES
  // ============================================================

  Widget _buildMessages() {
    if (!_isMember) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.forum_outlined, size: 56),
              SizedBox(height: 14),
              Text(
                'Join this room to participate '
                'in the discussion.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _service.watchMessages(widget.roomId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Chat error:\n${snapshot.error}',
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
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 54),
                  SizedBox(height: 14),
                  Text(
                    'No messages yet.',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 5),
                  Text('Start the discussion!'),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 18),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final data = messages[index].data();

            final username =
                data['username']?.toString() ??
                data['displayName']?.toString() ??
                'KREVZY User';

            final text = data['text']?.toString() ?? '';

            final time = _formatTime(data['createdAt']);

            return _MessageBubble(username: username, text: text, time: time);
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
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Discuss in room...',
                  filled: true,
                  fillColor: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
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
              width: 48,
              height: 48,
              child: FilledButton(
                onPressed: _sending ? null : _sendMessage,
                style: FilledButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: EdgeInsets.zero,
                ),
                child: _sending
                    ? const SizedBox(
                        width: 19,
                        height: 19,
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
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(behavior: SnackBarBehavior.floating, content: Text(message)),
    );
  }

  int _readInt(dynamic value) {
    if (value is int) return value;

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
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

  String _formatDateTime(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');

    final month = date.month.toString().padLeft(2, '0');

    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;

    final minute = date.minute.toString().padLeft(2, '0');

    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$day/$month/${date.year} '
        '$hour:$minute $period';
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Study':
        return Icons.school;
      case 'Gaming':
        return Icons.sports_esports;
      case 'Business':
        return Icons.business_center;
      case 'Share Market':
        return Icons.show_chart;
      case 'History':
        return Icons.history_edu;
      case 'Geography':
        return Icons.public;
      case 'Cricket':
        return Icons.sports_cricket;
      case 'Hockey':
        return Icons.sports_hockey;
      case 'Football':
        return Icons.sports_soccer;
      default:
        return Icons.groups;
    }
  }
}

// ================================================================
// ROOM HEADER
// ================================================================

class _RoomHeader extends StatelessWidget {
  final String roomName;
  final String category;
  final String description;
  final int memberCount;

  const _RoomHeader({
    required this.roomName,
    required this.category,
    required this.description,
    required this.memberCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 25,
            child: Icon(_categoryIcon(category), size: 25),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  roomName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$category • $memberCount members',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, height: 1.3),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Study':
        return Icons.school;
      case 'Gaming':
        return Icons.sports_esports;
      case 'Business':
        return Icons.business_center;
      case 'Share Market':
        return Icons.show_chart;
      case 'History':
        return Icons.history_edu;
      case 'Geography':
        return Icons.public;
      case 'Cricket':
        return Icons.sports_cricket;
      case 'Hockey':
        return Icons.sports_hockey;
      case 'Football':
        return Icons.sports_soccer;
      default:
        return Icons.groups;
    }
  }
}

// ================================================================
// MEMBER ACTIONS
// ================================================================

class _MemberActions extends StatelessWidget {
  final String role;
  final VoidCallback onRules;
  final VoidCallback onChallenges;
  final bool canCreateChallenge;
  final VoidCallback onCreateChallenge;

  const _MemberActions({
    required this.role,
    required this.onRules,
    required this.onChallenges,
    required this.canCreateChallenge,
    required this.onCreateChallenge,
  });

  @override
  Widget build(BuildContext context) {
    final roleLabel = role == 'owner'
        ? 'Room Owner'
        : role == 'moderator'
        ? 'Moderator'
        : 'Member';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 7),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user_outlined, size: 18),
                      const SizedBox(width: 7),
                      Text(
                        roleLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: onRules,
                icon: const Icon(Icons.rule_outlined, size: 17),
                label: const Text('Rules'),
              ),
              const SizedBox(width: 6),
              OutlinedButton.icon(
                onPressed: onChallenges,
                icon: const Icon(Icons.emoji_events_outlined, size: 17),
                label: const Text('Challenges'),
              ),
            ],
          ),
          if (canCreateChallenge) ...[
            const SizedBox(height: 7),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: FilledButton.icon(
                onPressed: onCreateChallenge,
                icon: const Icon(Icons.add_task_rounded, size: 18),
                label: const Text('Create Challenge'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ================================================================
// MESSAGE BUBBLE
// ================================================================

class _MessageBubble extends StatelessWidget {
  final String username;
  final String text;
  final String time;

  const _MessageBubble({
    required this.username,
    required this.text,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 19,
            child: Text(
              username.isNotEmpty ? username[0].toUpperCase() : '?',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          username,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (time.isNotEmpty)
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    text,
                    style: const TextStyle(fontSize: 14, height: 1.35),
                  ),
                ],
              ),
            ),
          ),
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
  final String? role;
  final bool allowMemberChallenges;
  final VoidCallback onCreateChallenge;

  const _ChallengesSheet({
    required this.roomId,
    required this.roomName,
    required this.service,
    required this.isMember,
    required this.role,
    required this.allowMemberChallenges,
    required this.onCreateChallenge,
  });

  int _readInt(dynamic value) {
    if (value is int) return value;

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatDeadline(dynamic value) {
    if (value is! Timestamp) {
      return '';
    }

    final date = value.toDate();

    final day = date.day.toString().padLeft(2, '0');

    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  bool get canCreateChallenge {
    return isMember &&
        (role == 'owner' || role == 'moderator' || allowMemberChallenges);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
          child: Row(
            children: [
              CircleAvatar(child: const Icon(Icons.emoji_events)),
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
              if (canCreateChallenge)
                IconButton(
                  tooltip: 'Create Challenge',
                  onPressed: onCreateChallenge,
                  icon: const Icon(Icons.add_circle_outline),
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
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.emoji_events_outlined, size: 55),
                        const SizedBox(height: 14),
                        const Text(
                          'No challenges yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Create a challenge for this room.',
                          textAlign: TextAlign.center,
                        ),
                        if (canCreateChallenge) ...[
                          const SizedBox(height: 18),
                          FilledButton.icon(
                            onPressed: onCreateChallenge,
                            icon: const Icon(Icons.add_task),
                            label: const Text('Create Challenge'),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: challenges.length,
                itemBuilder: (context, index) {
                  final data = challenges[index].data();

                  final challengeId = challenges[index].id;

                  final title = data['title']?.toString() ?? 'Challenge';

                  final description = data['description']?.toString() ?? '';

                  final reward = _readInt(data['rewardXp']);

                  final status = data['status']?.toString() ?? 'active';

                  final deadline = _formatDeadline(data['deadline']);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.emoji_events_rounded, size: 25),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (reward > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondaryContainer,
                                  ),
                                  child: Text(
                                    '+$reward XP',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              description,
                              style: const TextStyle(fontSize: 13, height: 1.4),
                            ),
                          ],

                          const SizedBox(height: 10),

                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              Chip(
                                avatar: const Icon(Icons.circle, size: 10),
                                label: Text(status),
                              ),
                              if (deadline.isNotEmpty)
                                Chip(
                                  avatar: const Icon(
                                    Icons.calendar_today,
                                    size: 15,
                                  ),
                                  label: Text(deadline),
                                ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          if (isMember)
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  _showSubmissionInfo(
                                    context,
                                    challengeId,
                                    title,
                                  );
                                },
                                icon: const Icon(Icons.upload_file_outlined),
                                label: const Text('Submit Evidence'),
                              ),
                            ),
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

  void _showSubmissionInfo(
    BuildContext context,
    String challengeId,
    String title,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Submit Challenge Evidence'),
          content: Text(
            'Challenge: $title\n\n'
            'Evidence upload should provide a screenshot or other proof of completion. '
            'The current ChatRoomService accepts an evidence URL through submitChallenge().',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text('$title: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

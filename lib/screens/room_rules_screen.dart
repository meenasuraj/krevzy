import 'package:flutter/material.dart';

import '../models/chat_room_rule.dart';
import '../services/chat_room_service.dart';
import 'add_room_rule_screen.dart';

class RoomRulesScreen extends StatefulWidget {
  final String roomId;
  final String roomName;
  final bool canManageRules;

  const RoomRulesScreen({
    super.key,
    required this.roomId,
    required this.roomName,
    required this.canManageRules,
  });

  @override
  State<RoomRulesScreen> createState() => _RoomRulesScreenState();
}

class _RoomRulesScreenState extends State<RoomRulesScreen> {
  final ChatRoomService _service = ChatRoomService.instance;

  Future<void> _openAddRule() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddRoomRuleScreen(
          roomId: widget.roomId,
          roomName: widget.roomName,
          isSuggestion: false,
        ),
      ),
    );
  }

  Future<void> _openSuggestion() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddRoomRuleScreen(
          roomId: widget.roomId,
          roomName: widget.roomName,
          isSuggestion: true,
        ),
      ),
    );
  }

  Future<void> _approve(ChatRoomRule rule) async {
    try {
      await _service.approveRule(roomId: widget.roomId, ruleId: rule.id);

      if (!mounted) {
        return;
      }

      _show('Rule approved and published.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _show('Could not approve rule: ${_cleanError(error)}');
    }
  }

  Future<void> _reject(ChatRoomRule rule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reject suggestion?'),
          content: Text('Reject "${rule.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _service.rejectRule(roomId: widget.roomId, ruleId: rule.id);

      if (!mounted) {
        return;
      }

      _show('Rule suggestion rejected.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _show('Could not reject rule: ${_cleanError(error)}');
    }
  }

  Future<void> _deactivate(ChatRoomRule rule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Deactivate rule?'),
          content: Text('"${rule.title}" will no longer be active.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Deactivate'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _service.deactivateRule(roomId: widget.roomId, ruleId: rule.id);

      if (!mounted) {
        return;
      }

      _show('Rule deactivated.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _show('Could not deactivate rule: ${_cleanError(error)}');
    }
  }

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

  void _show(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Room Rules'),
        actions: [
          if (widget.canManageRules)
            IconButton(
              tooltip: 'Add Rule',
              onPressed: _openAddRule,
              icon: const Icon(Icons.add_rounded),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _RulesHeader(roomName: widget.roomName),

          const SizedBox(height: 18),

          if (widget.canManageRules) ...[
            _ManagementCard(onAddRule: _openAddRule),
            const SizedBox(height: 22),
            _SectionTitle(
              icon: Icons.pending_actions_rounded,
              title: 'Pending Suggestions',
            ),
            const SizedBox(height: 10),
            _PendingRules(
              roomId: widget.roomId,
              service: _service,
              onApprove: _approve,
              onReject: _reject,
            ),
            const SizedBox(height: 24),
          ] else ...[
            _SuggestionCard(onSuggest: _openSuggestion),
            const SizedBox(height: 22),
          ],

          _SectionTitle(icon: Icons.rule_rounded, title: 'Active Rules'),

          const SizedBox(height: 10),

          StreamBuilder<List<ChatRoomRule>>(
            stream: _service.watchActiveRules(widget.roomId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _ErrorCard(message: _cleanError(snapshot.error!));
              }

              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final rules = snapshot.data ?? [];

              if (rules.isEmpty) {
                return _EmptyRules(
                  canManageRules: widget.canManageRules,
                  onAddRule: _openAddRule,
                  onSuggestRule: _openSuggestion,
                );
              }

              return Column(
                children: List.generate(rules.length, (index) {
                  return _ActiveRuleCard(
                    number: index + 1,
                    rule: rules[index],
                    canManage: widget.canManageRules,
                    onDeactivate: () => _deactivate(rules[index]),
                  );
                }),
              );
            },
          ),
        ],
      ),
      floatingActionButton: widget.canManageRules
          ? FloatingActionButton.extended(
              onPressed: _openAddRule,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Rule'),
            )
          : FloatingActionButton.extended(
              onPressed: _openSuggestion,
              icon: const Icon(Icons.lightbulb_outline),
              label: const Text('Suggest Rule'),
            ),
    );
  }
}

class _RulesHeader extends StatelessWidget {
  final String roomName;

  const _RulesHeader({required this.roomName});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [colors.primaryContainer, colors.secondaryContainer],
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 29,
            child: Icon(Icons.rule_rounded, size: 30, color: colors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Community Rules',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  roomName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ManagementCard extends StatelessWidget {
  final VoidCallback onAddRule;

  const _ManagementCard({required this.onAddRule});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(child: Icon(Icons.admin_panel_settings_outlined)),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manage room rules',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text('Create and publish rules for this community.'),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(onPressed: onAddRule, child: const Text('Add')),
          ],
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final VoidCallback onSuggest;

  const _SuggestionCard({required this.onSuggest});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: const CircleAvatar(child: Icon(Icons.lightbulb_outline)),
        title: const Text(
          'Have an idea for a rule?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('Suggest a rule to the room owner or moderator.'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onSuggest,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 21),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _PendingRules extends StatelessWidget {
  final String roomId;
  final ChatRoomService service;
  final Future<void> Function(ChatRoomRule) onApprove;
  final Future<void> Function(ChatRoomRule) onReject;

  const _PendingRules({
    required this.roomId,
    required this.service,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ChatRoomRule>>(
      stream: service.watchAllRules(roomId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ErrorCard(message: snapshot.error.toString());
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Card(
            elevation: 0,
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final allRules = snapshot.data ?? [];

        final pending = allRules.where((rule) => rule.isPending).toList();

        if (pending.isEmpty) {
          return Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(child: Text('No pending rule suggestions.')),
                ],
              ),
            ),
          );
        }

        return Column(
          children: pending.map((rule) {
            return _PendingRuleCard(
              rule: rule,
              onApprove: () => onApprove(rule),
              onReject: () => onReject(rule),
            );
          }).toList(),
        );
      },
    );
  }
}

class _PendingRuleCard extends StatelessWidget {
  final ChatRoomRule rule;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PendingRuleCard({
    required this.rule,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.lightbulb_outline)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    rule.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Theme.of(context).colorScheme.secondaryContainer,
                  ),
                  child: const Text(
                    'PENDING',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(rule.description, style: const TextStyle(height: 1.4)),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveRuleCard extends StatelessWidget {
  final int number;
  final ChatRoomRule rule;
  final bool canManage;
  final VoidCallback onDeactivate;

  const _ActiveRuleCard({
    required this.number,
    required this.rule,
    required this.canManage,
    required this.onDeactivate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              child: Text(
                '$number',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rule.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    rule.description,
                    style: TextStyle(
                      height: 1.4,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            if (canManage)
              PopupMenuButton<String>(
                tooltip: 'Rule options',
                onSelected: (value) {
                  if (value == 'deactivate') {
                    onDeactivate();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'deactivate',
                    child: Row(
                      children: [
                        Icon(Icons.visibility_off_outlined),
                        SizedBox(width: 10),
                        Text('Deactivate'),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyRules extends StatelessWidget {
  final bool canManageRules;
  final VoidCallback onAddRule;
  final VoidCallback onSuggestRule;

  const _EmptyRules({
    required this.canManageRules,
    required this.onAddRule,
    required this.onSuggestRule,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(
              Icons.rule_rounded,
              size: 58,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 14),
            const Text(
              'No active rules yet',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 7),
            const Text(
              'This room has not published any rules yet.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: canManageRules ? onAddRule : onSuggestRule,
              icon: Icon(canManageRules ? Icons.add : Icons.lightbulb_outline),
              label: Text(canManageRules ? 'Add First Rule' : 'Suggest a Rule'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(height: 1.4))),
          ],
        ),
      ),
    );
  }
}

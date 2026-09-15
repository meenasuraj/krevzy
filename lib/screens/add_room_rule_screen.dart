import 'package:flutter/material.dart';

import '../services/chat_room_service.dart';

class AddRoomRuleScreen extends StatefulWidget {
  final String roomId;
  final String roomName;
  final bool isSuggestion;

  const AddRoomRuleScreen({
    super.key,
    required this.roomId,
    required this.roomName,
    required this.isSuggestion,
  });

  @override
  State<AddRoomRuleScreen> createState() => _AddRoomRuleScreenState();
}

class _AddRoomRuleScreenState extends State<AddRoomRuleScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveRule() async {
    if (_saving) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _saving = true;
    });

    try {
      final service = ChatRoomService.instance;

      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();

      if (widget.isSuggestion) {
        await service.suggestRule(
          roomId: widget.roomId,
          title: title,
          description: description,
        );
      } else {
        await service.addRule(
          roomId: widget.roomId,
          title: title,
          description: description,
        );
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isSuggestion
                ? 'Rule suggestion submitted for review.'
                : 'Rule published successfully.',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save rule: ${_cleanError(error)}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  String _cleanError(Object error) {
    final value = error.toString();

    if (value.startsWith('Exception: ')) {
      return value.substring(11);
    }

    if (value.startsWith('Bad state: ')) {
      return value.substring(11);
    }

    return value;
  }

  @override
  Widget build(BuildContext context) {
    final isSuggestion = widget.isSuggestion;

    return Scaffold(
      appBar: AppBar(title: Text(isSuggestion ? 'Suggest Rule' : 'Add Rule')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      child: Icon(
                        isSuggestion
                            ? Icons.lightbulb_outline
                            : Icons.rule_rounded,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.roomName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isSuggestion
                                ? 'Suggest a rule for this community'
                                : 'Create an active rule for this room',
                            style: TextStyle(
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
              ),

              const SizedBox(height: 24),

              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 80,
                decoration: InputDecoration(
                  labelText: 'Rule title',
                  hintText: 'Example: Stay on topic',
                  prefixIcon: const Icon(Icons.rule_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';

                  if (text.isEmpty) {
                    return 'Enter a rule title.';
                  }

                  if (text.length < 3) {
                    return 'Rule title must be at least 3 characters.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _descriptionController,
                textCapitalization: TextCapitalization.sentences,
                minLines: 5,
                maxLines: 8,
                maxLength: 500,
                decoration: InputDecoration(
                  labelText: 'Rule description',
                  hintText: 'Explain what members should follow...',
                  alignLabelWithHint: true,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 70),
                    child: Icon(Icons.description_outlined),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';

                  if (text.isEmpty) {
                    return 'Enter a rule description.';
                  }

                  if (text.length < 5) {
                    return 'Description must be at least 5 characters.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: isSuggestion
                      ? Theme.of(context).colorScheme.secondaryContainer
                      : Theme.of(context).colorScheme.primaryContainer,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isSuggestion
                          ? Icons.info_outline
                          : Icons.verified_outlined,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isSuggestion
                            ? 'Your suggestion will stay pending until '
                                  'the room owner or moderator reviews it.'
                            : 'This rule will become active immediately '
                                  'after publishing.',
                        style: const TextStyle(height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _saveRule,
                  icon: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          isSuggestion
                              ? Icons.send_rounded
                              : Icons.publish_rounded,
                        ),
                  label: Text(
                    _saving
                        ? 'Saving...'
                        : isSuggestion
                        ? 'Submit Suggestion'
                        : 'Publish Rule',
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

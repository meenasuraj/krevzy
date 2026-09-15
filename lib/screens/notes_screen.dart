import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/notes_service.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final TextEditingController _searchController =
      TextEditingController();

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      if (!mounted) return;

      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openNoteEditor({
    DocumentSnapshot<Map<String, dynamic>>? note,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (sheetContext) {
        return _NoteEditorSheet(
          note: note,
        );
      },
    );

    if (!mounted || result != true) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          note == null ? 'Note created' : 'Note updated',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _deleteNote(
    DocumentSnapshot<Map<String, dynamic>> note,
  ) async {
    final data = note.data() ?? {};
    final title = (data['title'] ?? '').toString().trim();

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete note?'),
          content: Text(
            title.isEmpty
                ? 'This note will be permanently deleted.'
                : '“$title” will be permanently deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      await NotesService.deleteNote(note.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note deleted'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not delete note: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatDate(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();

      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'Just now';
      }

      if (difference.inHours < 1) {
        return '${difference.inMinutes} min ago';
      }

      if (difference.inDays == 0) {
        return '${difference.inHours} hr ago';
      }

      if (difference.inDays == 1) {
        return 'Yesterday';
      }

      if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      }

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const Text(
          'Notes',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Search',
            onPressed: () {
              FocusScope.of(context).requestFocus(
                FocusNode(),
              );
            },
            icon: const Icon(Icons.search_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: StreamBuilder<
                QuerySnapshot<Map<String, dynamic>>>(
              stream: NotesService.getNotes(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildError(snapshot.error);
                }

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final allNotes = snapshot.data?.docs ?? [];

                final filteredNotes = NotesService.filterNotes(
                  allNotes,
                  _searchQuery,
                );

                if (filteredNotes.isEmpty) {
                  return _buildEmptyState(
                    hasSearch: _searchQuery.trim().isNotEmpty,
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    return _buildNotesGrid(
                      filteredNotes,
                      constraints.maxWidth,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Create note',
        onPressed: () {
          _openNoteEditor();
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        4,
        16,
        12,
      ),
      child: Material(
        elevation: 0,
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest,
        child: TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search your notes',
            prefixIcon: const Icon(
              Icons.search_rounded,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      _searchController.clear();
                    },
                    icon: const Icon(
                      Icons.close_rounded,
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotesGrid(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> notes,
    double width,
  ) {
    int crossAxisCount;

    if (width >= 1200) {
      crossAxisCount = 4;
    } else if (width >= 850) {
      crossAxisCount = 3;
    } else if (width >= 550) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = 2;
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        12,
        4,
        12,
        100,
      ),
      keyboardDismissBehavior:
          ScrollViewKeyboardDismissBehavior.onDrag,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: _getCardAspectRatio(
          width,
          crossAxisCount,
        ),
      ),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];

        return _NoteCard(
          note: note,
          index: index,
          formattedDate: _formatDate(
            note.data()['updatedAt'],
          ),
          onTap: () {
            _openNoteEditor(note: note);
          },
          onEdit: () {
            _openNoteEditor(note: note);
          },
          onDelete: () {
            _deleteNote(note);
          },
        );
      },
    );
  }

  double _getCardAspectRatio(
    double width,
    int crossAxisCount,
  ) {
    if (width < 550) {
      return 0.95;
    }

    if (crossAxisCount == 2) {
      return 1.15;
    }

    if (crossAxisCount == 3) {
      return 1.05;
    }

    return 1.0;
  }

  Widget _buildEmptyState({
    required bool hasSearch,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
              ),
              child: Icon(
                hasSearch
                    ? Icons.search_off_rounded
                    : Icons.lightbulb_outline_rounded,
                size: 42,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasSearch
                  ? 'No notes found'
                  : 'No notes yet',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              hasSearch
                  ? 'Try a different search.'
                  : 'Tap + to create your first note.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant,
                  ),
            ),
            if (!hasSearch) ...[
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: () {
                  _openNoteEditor();
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create note'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildError(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Could not load notes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final DocumentSnapshot<Map<String, dynamic>> note;
  final int index;
  final String formattedDate;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _NoteCard({
    required this.note,
    required this.index,
    required this.formattedDate,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  Color _cardColor(BuildContext context) {
    final colors = [
      Theme.of(context).colorScheme.surfaceContainerHighest,
      Theme.of(context).colorScheme.primaryContainer,
      Theme.of(context).colorScheme.secondaryContainer,
      Theme.of(context).colorScheme.tertiaryContainer,
      Theme.of(context).colorScheme.surfaceContainer,
    ];

    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final data = note.data() ?? {};

    final title = (data['title'] ?? '').toString().trim();
    final content = (data['content'] ?? '').toString().trim();

    return Material(
      color: _cardColor(context),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            15,
            13,
            9,
            11,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: title.isEmpty
                        ? const SizedBox.shrink()
                        : Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Note options',
                    padding: EdgeInsets.zero,
                    iconSize: 20,
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit();
                      } else if (value == 'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined),
                            SizedBox(width: 12),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline),
                            SizedBox(width: 12),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (title.isNotEmpty)
                const SizedBox(height: 8),
              Expanded(
                child: content.isEmpty
                    ? const SizedBox.shrink()
                    : Text(
                        content,
                        maxLines: 7,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              height: 1.4,
                            ),
                      ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 14,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Private',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Spacer(),
                  if (formattedDate.isNotEmpty)
                    Flexible(
                      child: Text(
                        formattedDate,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteEditorSheet extends StatefulWidget {
  final DocumentSnapshot<Map<String, dynamic>>? note;

  const _NoteEditorSheet({
    this.note,
  });

  @override
  State<_NoteEditorSheet> createState() =>
      _NoteEditorSheetState();
}

class _NoteEditorSheetState
    extends State<_NoteEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;

  bool _saving = false;

  bool get _isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();

    final data = widget.note?.data() ?? {};

    _titleController = TextEditingController(
      text: (data['title'] ?? '').toString(),
    );

    _contentController = TextEditingController(
      text: (data['content'] ?? '').toString(),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) {
      return;
    }

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      _showError('Note cannot be empty.');
      return;
    }

    if (title.length > 200) {
      _showError(
        'Note title cannot exceed 200 characters.',
      );
      return;
    }

    if (content.length > 10000) {
      _showError(
        'Note content cannot exceed 10000 characters.',
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      if (_isEditing) {
        await NotesService.updateNote(
          noteId: widget.note!.id,
          title: title,
          content: content,
        );
      } else {
        await NotesService.createNote(
          title: title,
          content: content,
        );
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
      });

      _showError('$e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: mediaQuery.viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        keyboardDismissBehavior:
            ScrollViewKeyboardDismissBehavior.onDrag,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            20,
            8,
            20,
            24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _isEditing
                          ? 'Edit note'
                          : 'New note',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: _saving
                        ? null
                        : () {
                            Navigator.of(context).pop();
                          },
                    icon: const Icon(
                      Icons.close_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                enabled: !_saving,
                maxLength: 200,
                textCapitalization:
                    TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Title',
                  border: InputBorder.none,
                  counterText: '',
                ),
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _contentController,
                enabled: !_saving,
                maxLength: 10000,
                minLines: 7,
                maxLines: 16,
                keyboardType: TextInputType.multiline,
                textCapitalization:
                    TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Write a note...',
                  border: InputBorder.none,
                  alignLabelWithHint: true,
                ),
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 18,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'Private note',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.check_rounded,
                          ),
                    label: Text(
                      _isEditing ? 'Update' : 'Save',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
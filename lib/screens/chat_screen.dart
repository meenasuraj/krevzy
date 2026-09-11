import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/chat_lock_service.dart';
import '../services/chat_service.dart';
import '../services/krevzy_background_service.dart';
import '../widgets/krevzy_background.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String name;
  final String? initialPinHash;

  final Future<void> Function(String pinHash) onPinSet;
  final Future<void> Function() onLockRemoved;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.name,
    required this.initialPinHash,
    required this.onPinSet,
    required this.onLockRemoved,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController =
      TextEditingController();

  final FocusNode _messageFocusNode = FocusNode();

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _messagesStream;

  late final Stream<Map<String, String>> _typingStream;

  Timer? _thinkingTimer;
  Timer? _typingDebounceTimer;

  String? _chatLockPinHash;
  String? _chatBackgroundUrl;

  bool _isChatLocked = false;
  bool _isUnlocked = false;
  bool _isSending = false;
  bool _isMarkingRead = false;

  String _myTypingState = 'none';

  @override
  void initState() {
    super.initState();

    _chatLockPinHash = widget.initialPinHash;

    _isChatLocked = _chatLockPinHash != null;
    _isUnlocked = !_isChatLocked;

    _messagesStream = ChatService.getMessages(widget.chatId);

    _loadChatBackground();

    _typingStream = ChatService.getTypingUsers(widget.chatId);

    _messageController.addListener(_handleTypingChanged);

    _messageFocusNode.addListener(_handleFocusChanged);

    if (_isUnlocked) {
      _markChatAsRead();
    }
  }

  @override
  void dispose() {
    _typingDebounceTimer?.cancel();
    _thinkingTimer?.cancel();

    _messageController.removeListener(_handleTypingChanged);
    _messageFocusNode.removeListener(_handleFocusChanged);

    _clearTypingState();

    _messageController.dispose();
    _messageFocusNode.dispose();

    super.dispose();
  }

  Future<void> _loadChatBackground() async {
    try {
      final url = await KrevzyBackgroundService.getChatBackgroundUrl(widget.chatId);
      if (!mounted) return;
      setState(() => _chatBackgroundUrl = url);
    } catch (e) {
      debugPrint('Chat background load failed: $e');
    }
  }

  Future<void> _pickChatBackground() async {
    Navigator.pop(context);
    try {
      final url = await KrevzyBackgroundService.pickAndUploadChatBackground(chatId: widget.chatId);
      if (!mounted) return;
      setState(() => _chatBackgroundUrl = url);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chat background updated.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chat background failed: $e')));
    }
  }

  Future<void> _setChatPreset(String preset) async {
    Navigator.pop(context);
    try {
      await KrevzyBackgroundService.setChatPreset(widget.chatId, preset);
      if (!mounted) return;
      setState(() => _chatBackgroundUrl = null);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chat theme updated.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chat theme failed: $e')));
    }
  }

  // ===========================================================================
  // TYPING + THINKING
  // ===========================================================================

  void _handleTypingChanged() {
    if (!_isUnlocked) {
      return;
    }

    final text = _messageController.text.trim();
    final hasText = text.isNotEmpty;

    _typingDebounceTimer?.cancel();

    if (hasText) {
      _thinkingTimer?.cancel();

      _setMyTypingState('typing');

      _typingDebounceTimer = Timer(
        const Duration(milliseconds: 350),
        () {},
      );

      return;
    }

    if (_messageFocusNode.hasFocus) {
      _startThinking();
    } else {
      _clearTypingState();
    }
  }

  void _handleFocusChanged() {
    if (!_isUnlocked) {
      return;
    }

    if (_messageFocusNode.hasFocus) {
      final hasText = _messageController.text.trim().isNotEmpty;

      if (!hasText) {
        _startThinking();
      }
    } else {
      _clearTypingState();
    }
  }

  void _startThinking() {
    if (!_isUnlocked) {
      return;
    }

    _thinkingTimer?.cancel();

    _setMyTypingState('thinking');

    _thinkingTimer = Timer(
      const Duration(seconds: 60),
      () {
        _thinkingTimer = null;

        if (!mounted) {
          return;
        }

        _clearTypingState();
      },
    );
  }

  Future<void> _setMyTypingState(String state) async {
    if (!_isUnlocked) {
      return;
    }

    if (state != 'typing' &&
        state != 'thinking' &&
        state != 'none') {
      return;
    }

    if (_myTypingState == state) {
      return;
    }

    _myTypingState = state;

    try {
      await ChatService.setTypingState(
        chatId: widget.chatId,
        state: state,
      );
    } catch (e) {
      debugPrint('Typing state update failed: $e');
    }
  }

  Future<void> _clearTypingState() async {
    _thinkingTimer?.cancel();
    _thinkingTimer = null;

    _typingDebounceTimer?.cancel();
    _typingDebounceTimer = null;

    if (_myTypingState == 'none') {
      return;
    }

    _myTypingState = 'none';

    try {
      await ChatService.setTypingState(
        chatId: widget.chatId,
        state: 'none',
      );
    } catch (e) {
      debugPrint('Clear typing state failed: $e');
    }
  }

  // ===========================================================================
  // MARK CHAT AS READ
  // ===========================================================================

  Future<void> _markChatAsRead() async {
    if (_isMarkingRead) {
      return;
    }

    _isMarkingRead = true;

    try {
      await ChatService.markChatAsRead(widget.chatId);
    } catch (e) {
      debugPrint('Mark chat as read failed: $e');
    } finally {
      _isMarkingRead = false;
    }
  }

  // ===========================================================================
  // SEND MESSAGE
  // ===========================================================================

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty || _isSending || !_isUnlocked) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    await _clearTypingState();

    try {
      await ChatService.sendMessage(
        chatId: widget.chatId,
        text: text,
      );

      if (mounted) {
        _messageController.clear();
        _messageFocusNode.requestFocus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Message send failed: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  // ===========================================================================
  // SET CHAT LOCK
  // ===========================================================================

  Future<void> _setChatLock() async {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final colorScheme = Theme.of(dialogContext).colorScheme;

        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.lock_rounded,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 10),
              const Text('Set Chat Lock'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Create a PIN to protect this conversation.',
              ),
              const SizedBox(height: 18),
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'Enter PIN',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: confirmController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'Confirm PIN',
                  prefixIcon:
                      const Icon(Icons.verified_user_outlined),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final pin = pinController.text.trim();
                final confirm = confirmController.text.trim();

                if (pin.length < 4) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'PIN must be at least 4 digits.',
                      ),
                    ),
                  );
                  return;
                }

                if (pin != confirm) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('PINs do not match.'),
                    ),
                  );
                  return;
                }

                Navigator.pop(dialogContext, true);
              },
              child: const Text('Set Lock'),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      pinController.dispose();
      confirmController.dispose();
      return;
    }

    if (result == true) {
      final pin = pinController.text.trim();
      final pinHash = ChatLockService.hashPin(pin);

      await widget.onPinSet(pinHash);

      if (!mounted) {
        pinController.dispose();
        confirmController.dispose();
        return;
      }

      await _clearTypingState();

      if (!mounted) {
        pinController.dispose();
        confirmController.dispose();
        return;
      }

      setState(() {
        _chatLockPinHash = pinHash;
        _isChatLocked = true;
        _isUnlocked = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Chat Lock enabled 🔒'),
        ),
      );
    }

    pinController.dispose();
    confirmController.dispose();
  }

  // ===========================================================================
  // UNLOCK CHAT
  // ===========================================================================

  Future<void> _unlockChat() async {
    final pinController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final colorScheme = Theme.of(dialogContext).colorScheme;

        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.lock_rounded,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 10),
              const Text('Chat Locked'),
            ],
          ),
          content: TextField(
            controller: pinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Enter Chat PIN',
              prefixIcon: const Icon(Icons.key_rounded),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onSubmitted: (_) {
              final enteredPin = pinController.text.trim();

              if (_verifyPin(enteredPin)) {
                Navigator.pop(dialogContext, true);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final enteredPin = pinController.text.trim();

                if (_verifyPin(enteredPin)) {
                  Navigator.pop(dialogContext, true);
                } else {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Wrong Chat PIN ❌'),
                    ),
                  );
                }
              },
              child: const Text('Unlock'),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      pinController.dispose();
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      pinController.dispose();
    });

    if (result == true) {
      setState(() {
        _isUnlocked = true;
      });

      await _markChatAsRead();
    }
  }

  bool _verifyPin(String pin) {
    if (_chatLockPinHash == null) {
      return false;
    }

    final enteredHash = ChatLockService.hashPin(pin);

    return enteredHash == _chatLockPinHash;
  }

  // ===========================================================================
  // REMOVE CHAT LOCK
  // ===========================================================================

  Future<void> _removeChatLock() async {
    final pinController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remove Chat Lock'),
          content: TextField(
            controller: pinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
            decoration: InputDecoration(
              labelText: 'Enter Chat PIN',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final pin = pinController.text.trim();

                if (!_verifyPin(pin)) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Wrong Chat PIN ❌'),
                    ),
                  );
                  return;
                }

                Navigator.pop(dialogContext, true);
              },
              child: const Text('Remove Lock'),
            ),
          ],
        );
      },
    );

    pinController.dispose();

    if (!mounted) {
      return;
    }

    if (result == true) {
      await widget.onLockRemoved();

      if (!mounted) {
        return;
      }

      setState(() {
        _chatLockPinHash = null;
        _isChatLocked = false;
        _isUnlocked = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Chat Lock removed 🔓'),
        ),
      );
    }
  }

  // ===========================================================================
  // CHAT MENU
  // ===========================================================================

  void _showChatMenu() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final colorScheme = Theme.of(sheetContext).colorScheme;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      _isChatLocked
                          ? Icons.lock_open_rounded
                          : Icons.lock_rounded,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  title: Text(
                    _isChatLocked
                        ? 'Remove Chat Lock'
                        : 'Chat Lock',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    _isChatLocked
                        ? 'Disable PIN protection'
                        : 'Protect this conversation',
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);

                    if (_isChatLocked) {
                      _removeChatLock();
                    } else {
                      _setChatLock();
                    }
                  },
                ),
                ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  leading: Container(width: 42, height: 42, decoration: BoxDecoration(color: colorScheme.primaryContainer, borderRadius: BorderRadius.circular(13)), child: Icon(Icons.wallpaper_rounded, color: colorScheme.onPrimaryContainer)),
                  title: const Text('Chat Background', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Use a KREVZY theme or your own photo'),
                  onTap: () => _showChatBackgroundPicker(sheetContext),
                ),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.info_outline_rounded,
                    ),
                  ),
                  title: const Text(
                    'Chat Info',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: const Text('Conversation details'),
                  onTap: () {
                    Navigator.pop(sheetContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        behavior: SnackBarBehavior.floating,
                        content: Text('Chat Info coming soon'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showChatBackgroundPicker(BuildContext sheetContext) {
    showModalBottomSheet(
      context: sheetContext,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.auto_awesome), title: const Text('KREVZY default'), onTap: () => _setChatPreset('krevzy')),
          ListTile(leading: const Icon(Icons.brightness_5_outlined), title: const Text('Sunset Glow'), onTap: () => _setChatPreset('sunset')),
          ListTile(leading: const Icon(Icons.photo_library_outlined), title: const Text('My photo'), onTap: _pickChatBackground),
        ]),
      ),
    );
  }

  // ===========================================================================
  // FORMAT TIME
  // ===========================================================================

  String _formatTime(dynamic value) {
    if (value is Timestamp) {
      final dateTime = value.toDate();

      final hour = dateTime.hour > 12
          ? dateTime.hour - 12
          : dateTime.hour == 0
              ? 12
              : dateTime.hour;

      final minute = dateTime.minute.toString().padLeft(2, '0');

      final period = dateTime.hour >= 12 ? 'PM' : 'AM';

      return '$hour:$minute $period';
    }

    return '';
  }

  // ===========================================================================
  // TYPING / THINKING INDICATOR
  // ===========================================================================

  Widget _buildTypingIndicator() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<Map<String, String>>(
      stream: _typingStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final states = snapshot.data ?? {};

        String otherState = 'none';

        for (final entry in states.entries) {
          if (entry.key != currentUserId) {
            if (entry.value == 'typing' ||
                entry.value == 'thinking') {
              otherState = entry.value;
              break;
            }
          }
        }

        if (otherState == 'none') {
          return const SizedBox.shrink();
        }

        final isTyping = otherState == 'typing';
        final colorScheme = Theme.of(context).colorScheme;

        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 7),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isTyping
                        ? Icons.edit_rounded
                        : Icons.psychology_rounded,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    isTyping
                        ? '${widget.name} is typing...'
                        : '${widget.name} is thinking...',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12.5,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 7),
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: colorScheme.primary,
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

  // ===========================================================================
  // LOCKED VIEW
  // ===========================================================================

  Widget _buildLockedView() {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 112,
              height: 112,
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
                Icons.lock_rounded,
                size: 54,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              'Chat Locked',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'This conversation is protected by a separate Chat PIN.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 27),
            FilledButton.icon(
              onPressed: _unlockChat,
              icon: const Icon(Icons.lock_open_rounded),
              label: const Text(
                'Unlock Chat',
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

  // ===========================================================================
  // MESSAGE BUBBLE
  // ===========================================================================

  Widget _buildMessageBubble({
    required Map<String, dynamic> message,
    required bool isMe,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    final text = message['text']?.toString() ?? '';

    final time = _formatTime(message['timestamp']);

    final isRead = message['isRead'] == true;

    return Align(
      alignment: isMe
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 330,
        ),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(
          15,
          11,
          12,
          8,
        ),
        decoration: BoxDecoration(
          color: isMe
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 5),
            bottomRight: Radius.circular(isMe ? 5 : 20),
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 7,
              offset: const Offset(0, 2),
              color: Colors.black.withValues(alpha: 0.045),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isMe ? Colors.white : colorScheme.onSurface,
                fontSize: 15.5,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (time.isNotEmpty)
                  Text(
                    time,
                    style: TextStyle(
                      color: isMe
                          ? Colors.white.withValues(alpha: 0.72)
                          : colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.75),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (isMe) ...[
                  if (time.isNotEmpty)
                    const SizedBox(width: 4),
                  Icon(
                    isRead
                        ? Icons.done_all_rounded
                        : Icons.done_rounded,
                    size: 15,
                    color: isRead
                        ? Colors.lightBlueAccent
                        : Colors.white.withValues(alpha: 0.72),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // MESSAGES
  // ===========================================================================

  Widget _buildMessages() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _messagesStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Unable to load messages.\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final messages = snapshot.data?.docs ?? [];

        if (_isUnlocked && currentUserId != null) {
          final hasUnreadIncoming = messages.any(
            (doc) {
              final data = doc.data();

              final senderId =
                  data['senderId']?.toString() ?? '';

              return senderId != currentUserId &&
                  data['isRead'] != true;
            },
          );

          if (hasUnreadIncoming && !_isMarkingRead) {
            _markChatAsRead();
          }
        }

        if (messages.isEmpty) {
          return _buildEmptyConversation();
        }

        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.fromLTRB(
            16,
            20,
            16,
            14,
          ),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[messages.length - 1 - index].data();

            final senderId =
                message['senderId']?.toString() ?? '';

            final isMe = senderId == currentUserId;

            return _buildMessageBubble(
              message: message,
              isMe: isMe,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyConversation() {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.waving_hand_rounded,
                size: 42,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Say hello 👋',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start your conversation with ${widget.name}.',
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

  // ===========================================================================
  // MESSAGE INPUT
  // ===========================================================================

  Widget _buildMessageInput() {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          12,
          6,
          12,
          10,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: colorScheme.outlineVariant
                        .withValues(alpha: 0.5),
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _messageFocusNode,
                  textInputAction: TextInputAction.send,
                  minLines: 1,
                  maxLines: 5,
                  enabled: _isUnlocked && !_isSending,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) {
                    _sendMessage();
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary,
                    colorScheme.secondary,
                  ],
                ),
              ),
              child: IconButton(
                tooltip: 'Send',
                onPressed: _isSending || !_isUnlocked
                    ? null
                    : _sendMessage,
                color: Colors.white,
                icon: _isSending
                    ? const SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                      ),
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
    final showLocked = _isChatLocked && !_isUnlocked;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 43,
              height: 43,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.secondary,
                  ],
                ),
              ),
              child: CircleAvatar(
                backgroundColor: colorScheme.surface,
                child: Text(
                  widget.name.isNotEmpty
                      ? widget.name[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (_isChatLocked)
                    Row(
                      children: [
                        Icon(
                          Icons.lock_rounded,
                          size: 11,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Locked chat',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Chat options',
            onPressed: _showChatMenu,
            icon: const Icon(
              Icons.more_vert_rounded,
            ),
          ),
        ],
      ),
      body: showLocked
          ? _buildLockedView()
          : Stack(
              children: [
                Positioned.fill(
                  child: KrevzyBackground(
                    photoUrl: _chatBackgroundUrl,
                    overlayOpacity: .18,
                    child: const SizedBox.shrink(),
                  ),
                ),
                Column(
                  children: [
                    Expanded(child: _buildMessages()),
                    _buildTypingIndicator(),
                    _buildMessageInput(),
                  ],
                ),
              ],
            ),
    );
  }
}
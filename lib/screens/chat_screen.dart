import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/chat_lock_service.dart';
import '../services/chat_service.dart';

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
  State<ChatScreen> createState() =>
      _ChatScreenState();
}

class _ChatScreenState
    extends State<ChatScreen> {
  final TextEditingController
      _messageController =
      TextEditingController();

  final FocusNode _messageFocusNode =
      FocusNode();

  late final Stream<
      QuerySnapshot<Map<String, dynamic>>>
      _messagesStream;

  late final Stream<Map<String, String>>
      _typingStream;

  Timer? _thinkingTimer;

  Timer? _typingDebounceTimer;

  String? _chatLockPinHash;

  bool _isChatLocked = false;
  bool _isUnlocked = false;
  bool _isSending = false;
  bool _isMarkingRead = false;
  // bool _isTyping = false;

  String _myTypingState = 'none';

  @override
  void initState() {
    super.initState();

    _chatLockPinHash =
        widget.initialPinHash;

    _isChatLocked =
        _chatLockPinHash != null;

    _isUnlocked =
        !_isChatLocked;

    _messagesStream =
        ChatService.getMessages(
      widget.chatId,
    );

    _typingStream =
        ChatService.getTypingUsers(
      widget.chatId,
    );

    _messageController.addListener(
      _handleTypingChanged,
    );

    _messageFocusNode.addListener(
      _handleFocusChanged,
    );

    // Opening an unlocked chat marks
    // existing unread messages as read.
    if (_isUnlocked) {
      _markChatAsRead();
    }
  }

  @override
  void dispose() {
    _typingDebounceTimer?.cancel();
    _thinkingTimer?.cancel();

    _messageController.removeListener(
      _handleTypingChanged,
    );

    _messageFocusNode.removeListener(
      _handleFocusChanged,
    );

    // Clear our status when leaving.
    _clearTypingState();

    _messageController.dispose();
    _messageFocusNode.dispose();

    super.dispose();
  }

  // ===========================================================================
  // TYPING + THINKING
  // ===========================================================================

  void _handleTypingChanged() {
    if (!_isUnlocked) {
      return;
    }

    final text =
        _messageController.text.trim();

    final hasText = text.isNotEmpty;

    _typingDebounceTimer?.cancel();

    if (hasText) {
      // User is actively typing.
      _thinkingTimer?.cancel();

      _setMyTypingState(
        'typing',
      );

      // Small debounce so rapid keyboard
      // changes don't cause unnecessary writes.
      _typingDebounceTimer =
          Timer(
        const Duration(
          milliseconds: 350,
        ),
        () {},
      );

      return;
    }

    // Text is empty.
    //
    // If the input still has focus, the user
    // can be considered to be thinking.
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
      final hasText =
          _messageController.text
              .trim()
              .isNotEmpty;

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

    _setMyTypingState(
      'thinking',
    );

    // Thinking lasts exactly 60 seconds.
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

  Future<void> _setMyTypingState(
    String state,
  ) async {
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

    // if (state == 'typing') {
    //   _isTyping = true;
    // } else {
    //   _isTyping = false;
    // }

    try {
      await ChatService.setTypingState(
        chatId: widget.chatId,
        state: state,
      );
    } catch (e) {
      debugPrint(
        'Typing state update failed: $e',
      );
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
    // _isTyping = false;

    try {
      await ChatService.setTypingState(
        chatId: widget.chatId,
        state: 'none',
      );
    } catch (e) {
      debugPrint(
        'Clear typing state failed: $e',
      );
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
      await ChatService.markChatAsRead(
        widget.chatId,
      );
    } catch (e) {
      debugPrint(
        'Mark chat as read failed: $e',
      );
    } finally {
      _isMarkingRead = false;
    }
  }

  // ===========================================================================
  // SEND MESSAGE
  // ===========================================================================

  Future<void> _sendMessage() async {
    final text =
        _messageController.text.trim();

    if (text.isEmpty ||
        _isSending ||
        !_isUnlocked) {
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
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'Message send failed: $e',
            ),
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
    final pinController =
        TextEditingController();

    final confirmController =
        TextEditingController();

    final result =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Set Chat Lock 🔒',
          ),
          content: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const Text(
                'Create a PIN for this chat.',
              ),
              const SizedBox(
                height: 15,
              ),
              TextField(
                controller:
                    pinController,
                keyboardType:
                    TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration:
                    const InputDecoration(
                  labelText: 'Enter PIN',
                  prefixIcon:
                      Icon(Icons.lock),
                  border:
                      OutlineInputBorder(),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              TextField(
                controller:
                    confirmController,
                keyboardType:
                    TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Confirm PIN',
                  prefixIcon:
                      Icon(
                    Icons.lock_outline,
                  ),
                  border:
                      OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child:
                  const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final pin =
                    pinController.text
                        .trim();

                final confirm =
                    confirmController
                        .text
                        .trim();

                if (pin.length < 4) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'PIN must be at least 4 digits.',
                      ),
                    ),
                  );
                  return;
                }

                if (pin != confirm) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'PINs do not match.',
                      ),
                    ),
                  );
                  return;
                }

                Navigator.pop(
                  context,
                  true,
                );
              },
              child:
                  const Text('Set Lock'),
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
      final pin =
          pinController.text.trim();

      final pinHash =
          ChatLockService.hashPin(pin);

      await widget.onPinSet(
        pinHash,
      );

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
        _chatLockPinHash =
            pinHash;
        _isChatLocked = true;
        _isUnlocked = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Chat Lock enabled 🔒',
          ),
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
    final pinController =
        TextEditingController();

    final result =
        await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title:
              const Text(
            'Chat Locked 🔒',
          ),
          content: TextField(
            controller:
                pinController,
            keyboardType:
                TextInputType.number,
            obscureText: true,
            maxLength: 6,
            autofocus: true,
            decoration:
                const InputDecoration(
              labelText:
                  'Enter Chat PIN',
              prefixIcon:
                  Icon(Icons.lock),
              border:
                  OutlineInputBorder(),
            ),
            onSubmitted: (_) {
              final enteredPin =
                  pinController
                      .text
                      .trim();

              if (_verifyPin(
                enteredPin,
              )) {
                Navigator.pop(
                  context,
                  true,
                );
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child:
                  const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final enteredPin =
                    pinController
                        .text
                        .trim();

                if (_verifyPin(
                  enteredPin,
                )) {
                  Navigator.pop(
                    context,
                    true,
                  );
                } else {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Wrong Chat PIN ❌',
                      ),
                    ),
                  );
                }
              },
              child:
                  const Text('Unlock'),
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

    final enteredHash =
        ChatLockService.hashPin(pin);

    return enteredHash ==
        _chatLockPinHash;
  }

  // ===========================================================================
  // REMOVE CHAT LOCK
  // ===========================================================================

  Future<void> _removeChatLock() async {
    final pinController =
        TextEditingController();

    final result =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Remove Chat Lock',
          ),
          content: TextField(
            controller:
                pinController,
            keyboardType:
                TextInputType.number,
            obscureText: true,
            maxLength: 6,
            decoration:
                const InputDecoration(
              labelText:
                  'Enter Chat PIN',
              prefixIcon:
                  Icon(Icons.lock),
              border:
                  OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child:
                  const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final pin =
                    pinController
                        .text
                        .trim();

                if (!_verifyPin(pin)) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Wrong Chat PIN ❌',
                      ),
                    ),
                  );
                  return;
                }

                Navigator.pop(
                  context,
                  true,
                );
              },
              child:
                  const Text(
                'Remove Lock',
              ),
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

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Chat Lock removed 🔓',
          ),
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
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  _isChatLocked
                      ? Icons.lock_open
                      : Icons.lock,
                ),
                title: Text(
                  _isChatLocked
                      ? 'Remove Chat Lock'
                      : 'Chat Lock',
                ),
                onTap: () {
                  Navigator.pop(
                    context,
                  );

                  if (_isChatLocked) {
                    _removeChatLock();
                  } else {
                    _setChatLock();
                  }
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.info_outline,
                ),
                title:
                    const Text(
                  'Chat Info',
                ),
                onTap: () {
                  Navigator.pop(
                    context,
                  );

                  ScaffoldMessenger.of(
                    this.context,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Chat Info coming soon',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // FORMAT TIME
  // ===========================================================================

  String _formatTime(dynamic value) {
    if (value is Timestamp) {
      final dateTime =
          value.toDate();

      final hour =
          dateTime.hour > 12
              ? dateTime.hour - 12
              : dateTime.hour == 0
                  ? 12
                  : dateTime.hour;

      final minute =
          dateTime.minute
              .toString()
              .padLeft(
                2,
                '0',
              );

      final period =
          dateTime.hour >= 12
              ? 'PM'
              : 'AM';

      return '$hour:$minute $period';
    }

    return '';
  }

  // ===========================================================================
  // TYPING / THINKING INDICATOR
  // ===========================================================================

  Widget _buildTypingIndicator() {
    final currentUserId =
        FirebaseAuth
            .instance
            .currentUser
            ?.uid;

    if (currentUserId == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<
        Map<String, String>>(
      stream: _typingStream,
      builder:
          (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final states =
            snapshot.data ?? {};

        String otherState =
            'none';

        for (final entry
            in states.entries) {
          if (entry.key !=
              currentUserId) {
            if (entry.value ==
                    'typing' ||
                entry.value ==
                    'thinking') {
              otherState =
                  entry.value;
              break;
            }
          }
        }

        if (otherState ==
            'none') {
          return const SizedBox.shrink();
        }

        final isTyping =
            otherState ==
                'typing';

        return Padding(
          padding:
              const EdgeInsets.fromLTRB(
            18,
            0,
            18,
            6,
          ),
          child: Align(
            alignment:
                Alignment.centerLeft,
            child: Row(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Icon(
                  isTyping
                      ? Icons.edit
                      : Icons.psychology,
                  size: 17,
                ),
                const SizedBox(
                  width: 7,
                ),
                Text(
                  isTyping
                      ? '${widget.name} is typing...'
                      : '${widget.name} is thinking...',
                  style:
                      TextStyle(
                    color:
                        Theme.of(
                      context,
                    )
                            .colorScheme
                            .onSurfaceVariant,
                    fontSize: 13,
                    fontStyle:
                        FontStyle.italic,
                  ),
                ),
                const SizedBox(
                  width: 6,
                ),
                SizedBox(
                  width: 12,
                  height: 12,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 1.5,
                  ),
                ),
              ],
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
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock,
              size: 80,
            ),
            const SizedBox(
              height: 20,
            ),
            const Text(
              'Chat Locked',
              style: TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            const Text(
              'This conversation is protected by a separate Chat PIN.',
              textAlign:
                  TextAlign.center,
            ),
            const SizedBox(
              height: 25,
            ),
            ElevatedButton.icon(
              onPressed:
                  _unlockChat,
              icon: const Icon(
                Icons.lock_open,
              ),
              label:
                  const Text(
                'Unlock Chat',
              ),
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
    final currentUserId =
        FirebaseAuth
            .instance
            .currentUser
            ?.uid;

    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: _messagesStream,
      builder:
          (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Unable to load messages.\n${snapshot.error}',
              textAlign:
                  TextAlign.center,
            ),
          );
        }

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child:
                CircularProgressIndicator(),
          );
        }

        final messages =
            snapshot.data?.docs ?? [];

        // If the chat is open and a new
        // incoming message arrives, mark
        // it as read immediately.
        if (_isUnlocked &&
            currentUserId != null) {
          final hasUnreadIncoming =
              messages.any(
            (doc) {
              final data =
                  doc.data();

              final senderId =
                  data['senderId']
                          ?.toString() ??
                      '';

              return senderId !=
                      currentUserId &&
                  data['isRead'] !=
                      true;
            },
          );

          if (hasUnreadIncoming &&
              !_isMarkingRead) {
            _markChatAsRead();
          }
        }

        if (messages.isEmpty) {
          return const Center(
            child: Text(
              'No messages yet.\nSay hello 👋',
              textAlign:
                  TextAlign.center,
            ),
          );
        }

        return ListView.builder(
          padding:
              const EdgeInsets.all(
            16,
          ),
          itemCount:
              messages.length,
          itemBuilder:
              (context, index) {
            final message =
                messages[index]
                    .data();

            final senderId =
                message['senderId']
                        ?.toString() ??
                    '';

            final text =
                message['text']
                        ?.toString() ??
                    '';

            final isMe =
                senderId ==
                    currentUserId;

            final time =
                _formatTime(
              message['timestamp'],
            );

            final isRead =
                message['isRead'] ==
                    true;

            return Align(
              alignment: isMe
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Container(
                constraints:
                    const BoxConstraints(
                  maxWidth: 300,
                ),
                margin:
                    const EdgeInsets.only(
                  bottom: 10,
                ),
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 10,
                ),
                decoration:
                    BoxDecoration(
                  color: isMe
                      ? Theme.of(
                          context,
                        )
                          .colorScheme
                          .primary
                      : Theme.of(
                          context,
                        )
                          .colorScheme
                          .surfaceContainerHighest,
                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      isMe
                          ? CrossAxisAlignment
                              .end
                          : CrossAxisAlignment
                              .start,
                  children: [
                    Text(
                      text,
                      style: TextStyle(
                        color: isMe
                            ? Colors.white
                            : null,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Row(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        if (time.isNotEmpty)
                          Text(
                            time,
                            style:
                                TextStyle(
                              color: isMe
                                  ? Colors
                                      .white70
                                  : Colors
                                      .grey,
                              fontSize: 11,
                            ),
                          ),
                        if (isMe) ...[
                          if (time.isNotEmpty)
                            const SizedBox(
                              width: 4,
                            ),
                          Icon(
                            isRead
                                ? Icons
                                    .done_all
                                : Icons.done,
                            size: 15,
                            color: isRead
                                ? Colors
                                    .lightBlueAccent
                                : Colors
                                    .white70,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // MESSAGE INPUT
  // ===========================================================================

  Widget _buildMessageInput() {
    return SafeArea(
      child: Padding(
        padding:
            const EdgeInsets.fromLTRB(
          10,
          6,
          10,
          10,
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller:
                    _messageController,
                focusNode:
                    _messageFocusNode,
                textInputAction:
                    TextInputAction.send,
                minLines: 1,
                maxLines: 5,
                enabled:
                    _isUnlocked &&
                    !_isSending,
                decoration:
                    InputDecoration(
                  hintText:
                      'Type a message...',
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      25,
                    ),
                  ),
                  contentPadding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) {
                  _sendMessage();
                },
              ),
            ),
            const SizedBox(
              width: 8,
            ),
            FloatingActionButton.small(
              onPressed:
                  _isSending ||
                          !_isUnlocked
                      ? null
                      : _sendMessage,
              child: _isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.send,
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
  Widget build(
    BuildContext context,
  ) {
    final showLocked =
        _isChatLocked &&
            !_isUnlocked;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              child: Text(
                widget.name.isNotEmpty
                    ? widget.name[0]
                        .toUpperCase()
                    : '?',
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              child: Text(
                widget.name,
                overflow:
                    TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          if (_isChatLocked)
            const Padding(
              padding:
                  EdgeInsets.only(
                right: 4,
              ),
              child: Icon(
                Icons.lock,
                size: 19,
              ),
            ),
          IconButton(
            icon: const Icon(
              Icons.more_vert,
            ),
            onPressed:
                _showChatMenu,
          ),
        ],
      ),
      body: showLocked
          ? _buildLockedView()
          : Column(
              children: [
                Expanded(
                  child:
                      _buildMessages(),
                ),
                _buildTypingIndicator(),
                _buildMessageInput(),
              ],
            ),
    );
  }
}
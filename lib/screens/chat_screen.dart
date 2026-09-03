import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  final String name;

  // Parent screen se existing PIN receive hoga.
  final String? initialPin;

  // Jab PIN set hoga parent ko inform karega.
  final ValueChanged<String> onPinSet;

  // Jab lock remove hoga parent ko inform karega.
  final VoidCallback onLockRemoved;

  const ChatScreen({
    super.key,
    required this.name,
    this.initialPin,
    required this.onPinSet,
    required this.onLockRemoved,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String? _chatPin;

  bool _isChatLocked = false;

  bool _isUnlocked = true;

  final TextEditingController _messageController = TextEditingController();

  final List<Map<String, dynamic>> _messages = [
    {'text': 'Hello 👋', 'isMe': false, 'time': '10:30 AM'},
    {'text': 'Hello! Kaise ho?', 'isMe': true, 'time': '10:31 AM'},
  ];

  @override
  void initState() {
    super.initState();

    // Parent se PIN receive karo.
    _chatPin = widget.initialPin;

    // PIN hai to chat locked hai.
    _isChatLocked = widget.initialPin != null;

    // New chat unlocked.
    // Existing locked chat locked.
    _isUnlocked = widget.initialPin == null;

    // Agar chat already locked hai,
    // open hote hi PIN dialog show karo.
    if (_isChatLocked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showUnlockDialog();
        }
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              child: Text(
                widget.name.substring(0, 1),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Text(
                widget.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            if (_isChatLocked) const Icon(Icons.lock, size: 19),
          ],
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {
              _showComingSoon('Video call');
            },
          ),

          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {
              _showComingSoon('Voice call');
            },
          ),

          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'lock') {
                if (_isChatLocked) {
                  _showLockAlreadyEnabled();
                } else {
                  _showSetPinDialog();
                }
              }

              if (value == 'unlock') {
                _showRemoveLockDialog();
              }
            },

            itemBuilder: (context) {
              return [
                PopupMenuItem<String>(
                  value: 'lock',
                  child: Row(
                    children: [
                      Icon(_isChatLocked ? Icons.lock : Icons.lock_outline),
                      const SizedBox(width: 12),
                      Text(_isChatLocked ? 'Chat Locked' : 'Chat Lock'),
                    ],
                  ),
                ),

                if (_isChatLocked)
                  const PopupMenuItem<String>(
                    value: 'unlock',
                    child: Row(
                      children: [
                        Icon(Icons.lock_open),
                        SizedBox(width: 12),
                        Text('Remove Chat Lock'),
                      ],
                    ),
                  ),
              ];
            },
          ),
        ],
      ),

      body: _isChatLocked && !_isUnlocked
          ? _buildLockedView()
          : _buildChatView(),
    );
  }

  // ------------------------------------------------------------
  // LOCKED VIEW
  // ------------------------------------------------------------

  Widget _buildLockedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 80),

            const SizedBox(height: 20),

            const Text(
              'This chat is locked',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Text(
              'Enter your chat PIN to open ${widget.name} chat.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),

            const SizedBox(height: 25),

            ElevatedButton.icon(
              onPressed: _showUnlockDialog,
              icon: const Icon(Icons.lock_open),
              label: const Text('Unlock Chat'),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // CHAT VIEW
  // ------------------------------------------------------------

  Widget _buildChatView() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];

              final bool isMe = message['isMe'] as bool;

              return Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 10,
                  ),
                  constraints: const BoxConstraints(maxWidth: 280),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: isMe
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  child: Column(
                    crossAxisAlignment: isMe
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Text(
                        message['text'].toString(),
                        style: const TextStyle(fontSize: 16),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        message['time'].toString(),
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        _buildMessageInput(),
      ],
    );
  }

  // ------------------------------------------------------------
  // MESSAGE INPUT
  // ------------------------------------------------------------

  Widget _buildMessageInput() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 5, 10, 8),
        child: Row(
          children: [
            IconButton(
              onPressed: () {
                _showComingSoon('Attachment');
              },
              icon: const Icon(Icons.add),
            ),

            Expanded(
              child: TextField(
                controller: _messageController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 5),

            CircleAvatar(
              child: IconButton(
                icon: const Icon(Icons.send),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // SEND MESSAGE
  // ------------------------------------------------------------

  void _sendMessage() {
    final text = _messageController.text.trim();

    if (text.isEmpty) {
      return;
    }

    setState(() {
      _messages.add({'text': text, 'isMe': true, 'time': _currentTime()});
    });

    _messageController.clear();
  }

  String _currentTime() {
    final now = TimeOfDay.now();

    return now.format(context);
  }

  // ------------------------------------------------------------
  // SET PIN
  // ------------------------------------------------------------

  void _showSetPinDialog() {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        String? errorText;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.lock),
                  SizedBox(width: 10),
                  Text('Set Chat PIN'),
                ],
              ),

              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Create a separate PIN for this chat.'),

                  const SizedBox(height: 20),

                  TextField(
                    controller: pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'Enter PIN',
                      hintText: '4-6 digits',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: confirmController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'Confirm PIN',
                      hintText: 'Enter PIN again',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  if (errorText != null) ...[
                    const SizedBox(height: 10),

                    Text(
                      errorText!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),

                ElevatedButton(
                  onPressed: () {
                    final pin = pinController.text.trim();

                    final confirmPin = confirmController.text.trim();

                    if (pin.length < 4 || pin.length > 6) {
                      setDialogState(() {
                        errorText = 'PIN must be 4-6 digits.';
                      });
                      return;
                    }

                    if (!RegExp(r'^\d+$').hasMatch(pin)) {
                      setDialogState(() {
                        errorText = 'PIN can contain digits only.';
                      });
                      return;
                    }

                    if (pin != confirmPin) {
                      setDialogState(() {
                        errorText = 'PINs do not match.';
                      });
                      return;
                    }

                    // Save locally in this ChatScreen.
                    setState(() {
                      _chatPin = pin;
                      _isChatLocked = true;
                      _isUnlocked = false;
                    });

                    // Parent ChatsScreen ko bhi PIN save karao.
                    widget.onPinSet(pin);

                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Chat locked successfully 🔒'),
                      ),
                    );
                  },
                  child: const Text('Set PIN'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ------------------------------------------------------------
  // UNLOCK CHAT
  // ------------------------------------------------------------

  void _showUnlockDialog() {
    final pinController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        String? errorText;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.lock),
                  SizedBox(width: 10),
                  Text('Chat Locked'),
                ],
              ),

              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Enter PIN to open ${widget.name} chat.'),

                  const SizedBox(height: 20),

                  TextField(
                    controller: pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 6,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Chat PIN',
                      border: const OutlineInputBorder(),
                      errorText: errorText,
                    ),
                  ),
                ],
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),

                ElevatedButton(
                  onPressed: () {
                    final enteredPin = pinController.text.trim();

                    if (enteredPin == _chatPin) {
                      setState(() {
                        _isUnlocked = true;
                      });

                      Navigator.pop(dialogContext);
                    } else {
                      setDialogState(() {
                        errorText = 'Wrong PIN';
                      });
                    }
                  },
                  child: const Text('Unlock'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ------------------------------------------------------------
  // REMOVE LOCK
  // ------------------------------------------------------------

  void _showRemoveLockDialog() {
    final pinController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        String? errorText;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Remove Chat Lock'),

              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Enter your current PIN to remove the lock.'),

                  const SizedBox(height: 20),

                  TextField(
                    controller: pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 6,
                    decoration: InputDecoration(
                      labelText: 'Current PIN',
                      border: const OutlineInputBorder(),
                      errorText: errorText,
                    ),
                  ),
                ],
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),

                ElevatedButton(
                  onPressed: () {
                    if (pinController.text.trim() == _chatPin) {
                      setState(() {
                        _chatPin = null;
                        _isChatLocked = false;
                        _isUnlocked = true;
                      });

                      // Parent se bhi PIN remove karo.
                      widget.onLockRemoved();

                      Navigator.pop(dialogContext);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Chat lock removed')),
                      );
                    } else {
                      setDialogState(() {
                        errorText = 'Wrong PIN';
                      });
                    }
                  },
                  child: const Text('Remove Lock'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ------------------------------------------------------------
  // ALREADY LOCKED
  // ------------------------------------------------------------

  void _showLockAlreadyEnabled() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Chat Already Locked 🔒'),
          content: const Text('This chat already has a PIN.'),
          actions: [
            TextButton(
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

  // ------------------------------------------------------------
  // COMING SOON
  // ------------------------------------------------------------

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$feature coming soon')));
  }
}

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/chat_lock_service.dart';
import '../services/chat_service.dart';
import '../services/call_service.dart';
import 'audio_call_screen.dart';
import 'video_call_screen.dart';
import '../models/krevzy_payment.dart';
import '../services/krevzy_mock_payment_service.dart';
import '../services/krevzy_background_service.dart';
import '../services/krevzy_keyboard_chat_settings.dart';
import 'keyboard_chat_settings_screen.dart';
import '../widgets/krevzy_background.dart';

class _KrevzyPaymentTestSheet extends StatefulWidget {
  final String chatId;
  final String senderId;
  final String receiverId;
  final String receiverName;

  const _KrevzyPaymentTestSheet({
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<_KrevzyPaymentTestSheet> createState() =>
      _KrevzyPaymentTestSheetState();
}

class _KrevzyPaymentTestSheetState extends State<_KrevzyPaymentTestSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  KrevzyPaymentStatus _outcome = KrevzyPaymentStatus.success;
  bool _busy = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _runTestPayment() async {
    if (_busy) return;

    final amount = double.tryParse(_amountController.text.trim());

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid test amount.')),
      );
      return;
    }

    setState(() => _busy = true);

    try {
      final payment = await KrevzyMockPaymentService.instance.create(
        chatId: widget.chatId,
        senderId: widget.senderId,
        receiverId: widget.receiverId,
        receiverName: widget.receiverName,
        amount: amount,
        note: _noteController.text.trim(),
        outcome: _outcome,
      );

      if (!mounted) return;

      Navigator.pop(context, payment);
    } catch (e) {
      if (!mounted) return;

      setState(() => _busy = false);

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Test payment failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 10, 20, 20 + bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Krevzy Pay',
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Sandbox / test payment',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'To ${widget.receiverName}',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _amountController,
                enabled: !_busy,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  labelText: 'Test amount',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                enabled: !_busy,
                maxLength: 120,
                decoration: InputDecoration(
                  labelText: 'Payment note',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              DropdownButtonFormField<KrevzyPaymentStatus>(
                initialValue: _outcome,
                decoration: InputDecoration(
                  labelText: 'Simulate result',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: KrevzyPaymentStatus.success,
                    child: Text('Success'),
                  ),
                  DropdownMenuItem(
                    value: KrevzyPaymentStatus.pending,
                    child: Text('Pending'),
                  ),
                  DropdownMenuItem(
                    value: KrevzyPaymentStatus.failed,
                    child: Text('Failed'),
                  ),
                  DropdownMenuItem(
                    value: KrevzyPaymentStatus.cancelled,
                    child: Text('Cancelled'),
                  ),
                ],
                onChanged: _busy
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _outcome = value);
                        }
                      },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _busy ? null : _runTestPayment,
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.payments_outlined),
                  label: Text(
                    _busy ? 'Processing test...' : 'Send test payment',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Sandbox only. No real money is moved, charged, '
                'or verified.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
  final TextEditingController _messageController = TextEditingController();

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
  bool _isStartingCall = false;
  bool _isIncomingCallDialogOpen = false;
  String? _otherUserId;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _incomingCallsSubscription;

  String _myTypingState = 'none';
  String _tickMode = 'read'; // single, read, off
  String _chatFont = 'Default';
  double _chatFontSize = 16.0;
  Map<String, Object> _keyboardChatSettings = {};
  late final VoidCallback _keyboardSettingsListener;
  static const _fontOptions = <String>[
    'Default',
    'Serif',
    'Mono',
    'Rounded',
    'Elegant',
    'Typewriter',
    'Playful',
  ];
  static const _stickerOptions = <String>[
    '❤️',
    '😂',
    '😍',
    '🥹',
    '🔥',
    '👍',
    '🎉',
    '✨',
    '😎',
    '🤗',
    '🙌',
    '💜',
    '😘',
    '🤣',
    '😴',
    '🤔',
    '😱',
    '👏',
    '💯',
    '🌸',
    '🫶',
    '🚀',
    '☕',
    '🎯',
  ];

  @override
  void initState() {
    super.initState();

    _chatLockPinHash = widget.initialPinHash;

    _isChatLocked = _chatLockPinHash != null;
    _isUnlocked = !_isChatLocked;

    _messagesStream = ChatService.getMessages(widget.chatId);

    _loadChatBackground();
    _loadChatPreferences();
    _keyboardSettingsListener = () {
      _loadChatPreferences();
    };
    KrevzyKeyboardChatSettings.changed.addListener(_keyboardSettingsListener);

    _typingStream = ChatService.getTypingUsers(widget.chatId);

    _loadChatParticipant();
    _listenForIncomingCalls();

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
    _incomingCallsSubscription?.cancel();
    KrevzyKeyboardChatSettings.changed.removeListener(
      _keyboardSettingsListener,
    );

    _messageController.removeListener(_handleTypingChanged);
    _messageFocusNode.removeListener(_handleFocusChanged);

    _clearTypingState();

    _messageController.dispose();
    _messageFocusNode.dispose();

    super.dispose();
  }

  Future<void> _loadChatBackground() async {
    try {
      final url = await KrevzyBackgroundService.getChatBackgroundUrl(
        widget.chatId,
      );
      if (!mounted) return;
      setState(() => _chatBackgroundUrl = url);
    } catch (e) {
      debugPrint('Chat background load failed: $e');
    }
  }

  Future<void> _pickChatBackground() async {
    Navigator.pop(context);
    try {
      final url = await KrevzyBackgroundService.pickAndUploadChatBackground(
        chatId: widget.chatId,
      );
      if (!mounted) return;
      if (url != null && url.isNotEmpty) {
        setState(() => _chatBackgroundUrl = url);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat background updated.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Chat background failed: $e')));
      }
    }
  }

  Future<void> _setChatPreset(String preset) async {
    Navigator.pop(context);
    try {
      await KrevzyBackgroundService.setChatPreset(widget.chatId, preset);
      if (!mounted) return;
      setState(() => _chatBackgroundUrl = null);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Chat theme updated.')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Chat theme failed: $e')));
      }
    }
  }

  Future<void> _loadChatPreferences() async {
    try {
      final values = await KrevzyKeyboardChatSettings.load();
      if (!mounted) return;
      setState(() {
        _keyboardChatSettings = values;
        _tickMode = values[KrevzyKeyboardChatSettings.tickMode] as String;
        _chatFont = values[KrevzyKeyboardChatSettings.font] as String;
        _chatFontSize = (values[KrevzyKeyboardChatSettings.fontSize] as double);
      });
    } catch (e) {
      debugPrint('Chat preferences load failed: $e');
    }
  }

  Future<void> _saveTickMode(String value) async {
    await KrevzyKeyboardChatSettings.setString(
      KrevzyKeyboardChatSettings.tickMode,
      value,
    );
  }

  Future<void> _saveChatFont(String value) async {
    await KrevzyKeyboardChatSettings.setString(
      KrevzyKeyboardChatSettings.font,
      value,
    );
  }

  bool _settingBool(String key) =>
      (_keyboardChatSettings[key] as bool?) ?? true;

  void _insertComposerText(String value) {
    if (value.isEmpty || !_isUnlocked || _isSending) return;
    final text = _messageController.text;
    final selection = _messageController.selection;
    final start = selection.isValid
        ? selection.start.clamp(0, text.length)
        : text.length;
    final end = selection.isValid
        ? selection.end.clamp(0, text.length)
        : text.length;
    final updated = text.replaceRange(start, end, value);
    _messageController.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: start + value.length),
    );
    _messageFocusNode.requestFocus();
  }

  Future<void> _pasteFromClipboard() async {
    if (!_settingBool(KrevzyKeyboardChatSettings.clipboard)) return;
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final value = data?.text ?? '';
      if (value.isEmpty) return;
      _insertComposerText(value);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read clipboard.')),
        );
      }
    }
  }

  Future<void> _showEmojiPicker() async {
    if (!_settingBool(KrevzyKeyboardChatSettings.emoji) ||
        !_isUnlocked ||
        _isSending) {
      return;
    }
    const emojis = <String>[
      '😀',
      '😃',
      '😄',
      '😁',
      '😆',
      '😅',
      '😂',
      '🤣',
      '😊',
      '😇',
      '🙂',
      '🙃',
      '😉',
      '😌',
      '😍',
      '🥰',
      '😘',
      '😗',
      '😙',
      '😚',
      '😋',
      '😛',
      '😝',
      '😜',
      '🤪',
      '🤨',
      '🧐',
      '🤓',
      '😎',
      '🤩',
      '🥳',
      '😏',
      '😒',
      '😞',
      '😔',
      '😟',
      '😕',
      '🙁',
      '☹️',
      '😣',
      '😖',
      '😫',
      '😩',
      '🥺',
      '😢',
      '😭',
      '😤',
      '😠',
      '😡',
      '🤬',
      '🤯',
      '😳',
      '🥵',
      '🥶',
      '😱',
      '😨',
      '😰',
      '😥',
      '😓',
      '🤗',
      '🤔',
      '🫣',
      '🤭',
      '🫢',
      '🫡',
      '🤫',
      '🫠',
      '🤥',
      '😶',
      '🫥',
      '😐',
      '😑',
      '😬',
      '🙄',
      '😯',
      '😦',
      '😧',
      '😮',
      '😲',
      '🥱',
      '😴',
      '🤤',
      '😪',
      '😵',
      '🤐',
      '🥴',
      '🤢',
      '🤮',
      '🤧',
      '😷',
      '🤒',
      '🤕',
      '👍',
      '👎',
      '👏',
      '🙌',
      '🙏',
      '💪',
      '🤝',
      '❤️',
      '🧡',
      '💛',
      '💚',
      '💙',
      '💜',
      '🖤',
      '🤍',
      '🤎',
      '💯',
      '🔥',
      '✨',
      '🎉',
      '🎊',
      '💫',
      '⭐',
      '🌸',
      '🌹',
      '🚀',
      '☕',
      '🎯',
    ];
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(sheetContext).height * .42,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: GridView.builder(
                itemCount: emojis.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemBuilder: (_, index) => InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    _insertComposerText(emojis[index]);
                    Navigator.pop(sheetContext);
                  },
                  child: Center(
                    child: Text(
                      emojis[index],
                      style: const TextStyle(fontSize: 27),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  TextStyle _messageTextStyle({required bool isMe, bool sticker = false}) {
    final base = TextStyle(
      color: isMe ? Colors.white : Theme.of(context).colorScheme.onSurface,
      fontSize: sticker ? 42 : _chatFontSize,
      height: sticker ? 1.0 : 1.35,
    );
    switch (_chatFont) {
      case 'Serif':
      case 'Elegant':
        return base.copyWith(
          fontFamily: 'serif',
          fontStyle: _chatFont == 'Elegant' ? FontStyle.italic : null,
        );
      case 'Mono':
      case 'Typewriter':
        return base.copyWith(fontFamily: 'monospace');
      case 'Rounded':
        return base.copyWith(letterSpacing: .25, fontWeight: FontWeight.w500);
      case 'Playful':
        return base.copyWith(letterSpacing: .6, fontWeight: FontWeight.w700);
      default:
        return base;
    }
  }

  bool _isSticker(String text) => _stickerOptions.contains(text.trim());

  // ===========================================================================
  // CHAT STYLE / TICK SETTINGS
  // ===========================================================================

  Future<void> _showChatStyleSheet() async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.82;
        return SafeArea(
          child: SizedBox(
            height: maxHeight,
            child: StatefulBuilder(
              builder: (context, setSheetState) {
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    18,
                    8,
                    18,
                    24 + MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chat style',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 18),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.keyboard_alt_outlined),
                        title: const Text('Keyboard & Chat Settings'),
                        subtitle: const Text(
                          'Open all composer and typing preferences',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const KeyboardChatSettingsScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Message font',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _fontOptions.map((font) {
                          return ChoiceChip(
                            label: Text(
                              font,
                              style: TextStyle(
                                fontFamily:
                                    (font == 'Serif' || font == 'Elegant')
                                    ? 'serif'
                                    : (font == 'Mono' || font == 'Typewriter')
                                    ? 'monospace'
                                    : null,
                              ),
                            ),
                            selected: _chatFont == font,
                            onSelected: (_) async {
                              await _saveChatFont(font);
                              setSheetState(() {});
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Message ticks',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      RadioGroup<String>(
                        groupValue: _tickMode,
                        onChanged: (v) async {
                          if (v != null) {
                            await _saveTickMode(v);
                            setSheetState(() {});
                          }
                        },
                        child: Column(
                          children: [
                            RadioListTile<String>(
                              value: 'single',
                              title: const Text('Single tick only'),
                              subtitle: const Text('Show ✓ after sending'),
                            ),
                            RadioListTile<String>(
                              value: 'read',
                              title: const Text('Single + double tick'),
                              subtitle: const Text('✓ sent, ✓✓ when read'),
                            ),
                            RadioListTile<String>(
                              value: 'off',
                              title: const Text('Hide ticks'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showStickerPicker() {
    if (!_isUnlocked ||
        _isSending ||
        !_settingBool(KrevzyKeyboardChatSettings.stickers)) {
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final cs = Theme.of(sheetContext).colorScheme;
        final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.70;
        return SafeArea(
          child: SizedBox(
            height: maxHeight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Stickers',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.only(bottom: 8),
                      itemCount: _stickerOptions.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 6,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                          ),
                      itemBuilder: (_, index) => InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () async {
                          Navigator.pop(sheetContext);
                          await _sendSticker(_stickerOptions[index]);
                        },
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _stickerOptions[index],
                            style: const TextStyle(
                              fontSize: 29,
                              fontFamily: 'Segoe UI Emoji',
                            ),
                          ),
                        ),
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
  }

  Future<void> _sendSticker(String sticker) async {
    if (_isSending || !_isUnlocked) return;
    setState(() => _isSending = true);
    await _clearTypingState();
    try {
      await ChatService.sendMessage(chatId: widget.chatId, text: sticker);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Sticker send failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // ===========================================================================
  // CALLING
  // ===========================================================================

  Future<void> _loadChatParticipant() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .get();
      final participants = snapshot.data()?['participants'];
      final myUid = FirebaseAuth.instance.currentUser?.uid;
      if (!mounted || participants is! List || myUid == null) return;
      final other = participants.whereType<String>().firstWhere(
        (id) => id != myUid,
        orElse: () => '',
      );
      if (other.isNotEmpty) {
        setState(() => _otherUserId = other);
      }
    } catch (e) {
      debugPrint('Chat participant load failed: $e');
    }
  }

  void _listenForIncomingCalls() {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;

    _incomingCallsSubscription = FirebaseFirestore.instance
        .collection('calls')
        .where('calleeId', isEqualTo: myUid)
        .snapshots()
        .listen(
          (snapshot) {
            for (final change in snapshot.docChanges) {
              if (change.type != DocumentChangeType.added) {
                continue;
              }
              final data = change.doc.data();
              if (data == null ||
                  data['callerId'] == myUid ||
                  data['status'] != 'ringing') {
                continue;
              }
              _showIncomingCall(change.doc.id, data);
            }
          },
          onError: (Object error) {
            debugPrint('Incoming call listener failed: $error');
          },
        );
  }

  Future<void> _showIncomingCall(
    String callId,
    Map<String, dynamic> data,
  ) async {
    if (!mounted || _isIncomingCallDialogOpen) return;
    _isIncomingCallDialogOpen = true;

    final isVideo = data['type'] == 'video';
    final callerName = (data['callerName'] ?? widget.name).toString();

    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(isVideo ? 'Incoming video call' : 'Incoming audio call'),
        content: Text('$callerName is calling you.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Decline'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: Icon(isVideo ? Icons.videocam_rounded : Icons.call_rounded),
            label: const Text('Answer'),
          ),
        ],
      ),
    );

    _isIncomingCallDialogOpen = false;
    if (!mounted) return;

    try {
      if (accepted == true) {
        await CallService.instance.acceptCall(callId);
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => isVideo
                ? VideoCallScreen(
                    callId: callId,
                    peerName: callerName,
                    isCaller: false,
                  )
                : AudioCallScreen(
                    callId: callId,
                    peerName: callerName,
                    isCaller: false,
                  ),
          ),
        );
      } else {
        await CallService.instance.endCall(callId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Call action failed: $e')));
      }
    }
  }

  Future<void> _startCall({required bool video}) async {
    if (_isStartingCall) return;

    final messenger = ScaffoldMessenger.of(context);
    var peerId = _otherUserId;

    if (peerId == null || peerId.isEmpty) {
      await _loadChatParticipant();

      if (!mounted) return;

      peerId = _otherUserId;
      if (peerId == null || peerId.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Unable to find the other chat participant.'),
          ),
        );
        return;
      }
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Please sign in again to make a call.')),
        );
      }
      return;
    }

    final displayName = currentUser.displayName?.trim();
    final callerName = displayName != null && displayName.isNotEmpty
        ? displayName
        : 'KREVZY user';

    setState(() => _isStartingCall = true);

    try {
      final callId = await CallService.instance.createCall(
        calleeId: peerId,
        type: video ? 'video' : 'audio',
        callerName: callerName,
      );

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => video
              ? VideoCallScreen(
                  callId: callId,
                  peerName: widget.name,
                  isCaller: true,
                )
              : AudioCallScreen(
                  callId: callId,
                  peerName: widget.name,
                  isCaller: true,
                ),
        ),
      );
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Could not start call: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isStartingCall = false);
      }
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

      _typingDebounceTimer = Timer(const Duration(milliseconds: 350), () {});

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

    _thinkingTimer = Timer(const Duration(seconds: 60), () {
      _thinkingTimer = null;

      if (!mounted) {
        return;
      }

      _clearTypingState();
    });
  }

  Future<void> _setMyTypingState(String state) async {
    if (!_isUnlocked) {
      return;
    }

    if (state != 'typing' && state != 'thinking' && state != 'none') {
      return;
    }

    if (_myTypingState == state) {
      return;
    }

    _myTypingState = state;

    try {
      await ChatService.setTypingState(chatId: widget.chatId, state: state);
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
      await ChatService.setTypingState(chatId: widget.chatId, state: 'none');
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
      await ChatService.sendMessage(chatId: widget.chatId, text: text);

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
  // PAYMENT
  // ===========================================================================

  Future<void> _openPaymentSheet() async {
    if (!_isUnlocked || _isSending) return;

    var peerId = _otherUserId;

    if (peerId == null || peerId.isEmpty) {
      await _loadChatParticipant();
      if (!mounted) return;
      peerId = _otherUserId;
    }

    if (peerId == null || peerId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to find this user.')),
        );
      }
      return;
    }

    final result = await showModalBottomSheet<KrevzyPayment>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return _KrevzyPaymentTestSheet(
          chatId: widget.chatId,
          senderId: FirebaseAuth.instance.currentUser?.uid ?? '',
          receiverId: peerId!,
          receiverName: widget.name,
        );
      },
    );

    if (!mounted || result == null) return;

    try {
      await ChatService.sendPaymentMessage(
        chatId: widget.chatId,
        receiverId: result.receiverId,
        receiverName: result.receiverName,
        amount: result.amount,
        currency: result.currency,
        note: result.note,
        paymentId: result.id,
        status: result.status.name,
        transactionRef: result.transactionRef,
        createdAt: result.createdAt,
      );

      if (!mounted) return;

      final statusLabel = result.status.name.toUpperCase();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Test payment message sent • ${result.currency} '
            '${result.amount.toStringAsFixed(2)} • $statusLabel',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Payment message failed: $e'),
          ),
        );
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
              Icon(Icons.lock_rounded, color: colorScheme.primary),
              const SizedBox(width: 10),
              const Text('Set Chat Lock'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Create a PIN to protect this conversation.'),
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
                  prefixIcon: const Icon(Icons.verified_user_outlined),
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
                      content: Text('PIN must be at least 4 digits.'),
                    ),
                  );
                  return;
                }

                if (pin != confirm) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('PINs do not match.')),
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
              Icon(Icons.lock_rounded, color: colorScheme.primary),
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
                    const SnackBar(content: Text('Wrong Chat PIN ❌')),
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
                    const SnackBar(content: Text('Wrong Chat PIN ❌')),
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

        final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.72;
        return SafeArea(
          child: SizedBox(
            height: maxHeight,
            child: SingleChildScrollView(
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
                      _isChatLocked ? 'Remove Chat Lock' : 'Chat Lock',
                      style: const TextStyle(fontWeight: FontWeight.w700),
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
                        Icons.wallpaper_rounded,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    title: const Text(
                      'Chat Background',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text(
                      'Use a KREVZY theme or your own photo',
                    ),
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
                      child: const Icon(Icons.info_outline_rounded),
                    ),
                    title: const Text(
                      'Chat Info',
                      style: TextStyle(fontWeight: FontWeight.w700),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.auto_awesome),
              title: const Text('KREVZY default'),
              onTap: () => _setChatPreset('krevzy'),
            ),
            ListTile(
              leading: const Icon(Icons.brightness_5_outlined),
              title: const Text('Sunset Glow'),
              onTap: () => _setChatPreset('sunset'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('My photo'),
              onTap: _pickChatBackground,
            ),
          ],
        ),
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
            if (entry.value == 'typing' || entry.value == 'thinking') {
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isTyping ? Icons.edit_rounded : Icons.psychology_rounded,
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
                style: TextStyle(fontWeight: FontWeight.w700),
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
    if (message['type'] == 'payment') {
      return _buildPaymentMessageBubble(message: message, isMe: isMe);
    }

    final colorScheme = Theme.of(context).colorScheme;
    final text = message['text']?.toString() ?? '';
    final time = _formatTime(message['timestamp']);
    final isRead = message['isRead'] == true;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 330),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(15, 11, 12, 8),
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
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: _messageTextStyle(isMe: isMe, sticker: _isSticker(text)),
              textAlign: _isSticker(text) ? TextAlign.center : TextAlign.start,
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
                          : colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.75,
                            ),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (isMe && _tickMode != 'off') ...[
                  if (time.isNotEmpty) const SizedBox(width: 4),
                  Icon(
                    _tickMode == 'read' && isRead
                        ? Icons.done_all_rounded
                        : Icons.done_rounded,
                    size: 15,
                    color: _tickMode == 'read' && isRead
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

  Widget _buildPaymentMessageBubble({
    required Map<String, dynamic> message,
    required bool isMe,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    final amount = message['amount'] is num
        ? (message['amount'] as num).toDouble()
        : double.tryParse('${message['amount']}') ?? 0;

    final currency = message['currency']?.toString() ?? 'INR';
    final status = message['status']?.toString() ?? 'pending';
    final note = message['note']?.toString() ?? '';
    final transactionRef = message['transactionRef']?.toString() ?? '';
    final time = _formatTime(message['timestamp']);
    final isRead = message['isRead'] == true;

    final statusIcon = switch (status) {
      'success' => Icons.check_circle_rounded,
      'failed' => Icons.error_rounded,
      'cancelled' => Icons.cancel_rounded,
      'processing' => Icons.sync_rounded,
      _ => Icons.schedule_rounded,
    };

    final statusText = status.isEmpty ? 'PENDING' : status.toUpperCase();

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isMe
                ? [colorScheme.primary, colorScheme.secondary]
                : [colorScheme.surfaceContainerHighest, colorScheme.surface],
          ),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 5),
            bottomRight: Radius.circular(isMe ? 5 : 20),
          ),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.45),
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 8,
              offset: const Offset(0, 2),
              color: Colors.black.withValues(alpha: 0.05),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 19,
                  color: isMe ? Colors.white : colorScheme.primary,
                ),
                const SizedBox(width: 7),
                Text(
                  'Krevzy Pay',
                  style: TextStyle(
                    color: isMe ? Colors.white : colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              '$currency ${amount.toStringAsFixed(2)}',
              style: TextStyle(
                color: isMe ? Colors.white : colorScheme.onSurface,
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  statusIcon,
                  size: 15,
                  color: isMe
                      ? Colors.white.withValues(alpha: 0.9)
                      : colorScheme.primary,
                ),
                const SizedBox(width: 5),
                Text(
                  statusText,
                  style: TextStyle(
                    color: isMe
                        ? Colors.white.withValues(alpha: 0.9)
                        : colorScheme.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            if (note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                note,
                style: TextStyle(
                  color: isMe
                      ? Colors.white.withValues(alpha: 0.86)
                      : colorScheme.onSurfaceVariant,
                  fontSize: 12.5,
                ),
              ),
            ],
            if (transactionRef.isNotEmpty) ...[
              const SizedBox(height: 7),
              Text(
                transactionRef,
                style: TextStyle(
                  color: isMe
                      ? Colors.white.withValues(alpha: 0.62)
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.72),
                  fontSize: 9.5,
                ),
              ),
            ],
            const SizedBox(height: 7),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (time.isNotEmpty)
                  Text(
                    time,
                    style: TextStyle(
                      color: isMe
                          ? Colors.white.withValues(alpha: 0.68)
                          : colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.72,
                            ),
                      fontSize: 10,
                    ),
                  ),
                if (isMe && _tickMode != 'off') ...[
                  if (time.isNotEmpty) const SizedBox(width: 4),
                  Icon(
                    _tickMode == 'read' && isRead
                        ? Icons.done_all_rounded
                        : Icons.done_rounded,
                    size: 14,
                    color: _tickMode == 'read' && isRead
                        ? Colors.lightBlueAccent
                        : Colors.white.withValues(alpha: 0.7),
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
          return const Center(child: CircularProgressIndicator());
        }

        final messages = snapshot.data?.docs ?? [];

        if (_isUnlocked && currentUserId != null) {
          final hasUnreadIncoming = messages.any((doc) {
            final data = doc.data();

            final senderId = data['senderId']?.toString() ?? '';

            return senderId != currentUserId && data['isRead'] != true;
          });

          if (hasUnreadIncoming && !_isMarkingRead) {
            _markChatAsRead();
          }
        }

        if (messages.isEmpty) {
          return _buildEmptyConversation();
        }

        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[messages.length - 1 - index].data();

            final senderId = message['senderId']?.toString() ?? '';

            final isMe = senderId == currentUserId;

            return _buildMessageBubble(message: message, isMe: isMe);
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
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'Start your conversation with ${widget.name}.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
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
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (_settingBool(KrevzyKeyboardChatSettings.clipboard))
              IconButton(
                tooltip: 'Paste',
                onPressed: !_isUnlocked || _isSending
                    ? null
                    : _pasteFromClipboard,
                icon: const Icon(Icons.content_paste_rounded),
              ),
            if (_settingBool(KrevzyKeyboardChatSettings.emoji))
              IconButton(
                tooltip: 'Emoji',
                onPressed: !_isUnlocked || _isSending ? null : _showEmojiPicker,
                icon: const Icon(Icons.emoji_emotions_outlined),
              ),
            if (_settingBool(KrevzyKeyboardChatSettings.stickers))
              IconButton(
                tooltip: 'Stickers',
                onPressed: !_isUnlocked || _isSending
                    ? null
                    : _showStickerPicker,
                icon: const Icon(Icons.sticky_note_2_outlined),
              ),
            IconButton(
              tooltip: 'Font & tick settings',
              onPressed: !_isUnlocked ? null : _showChatStyleSheet,
              icon: const Icon(Icons.text_format_rounded),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
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
            const SizedBox(width: 4),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: IconButton(
                tooltip: 'Send payment',
                onPressed: !_isUnlocked || _isSending
                    ? null
                    : _openPaymentSheet,
                icon: const Icon(Icons.currency_rupee_rounded),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [colorScheme.primary, colorScheme.secondary],
                ),
              ),
              child: IconButton(
                tooltip: 'Send',
                onPressed: _isSending || !_isUnlocked ? null : _sendMessage,
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
                    : const Icon(Icons.send_rounded),
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
                  colors: [colorScheme.primary, colorScheme.secondary],
                ),
              ),
              child: CircleAvatar(
                backgroundColor: colorScheme.surface,
                child: Text(
                  widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?',
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
            tooltip: 'Audio call',
            onPressed: _isStartingCall || !_isUnlocked
                ? null
                : () => _startCall(video: false),
            icon: const Icon(Icons.call_rounded),
          ),
          IconButton(
            tooltip: 'Video call',
            onPressed: _isStartingCall || !_isUnlocked
                ? null
                : () => _startCall(video: true),
            icon: const Icon(Icons.videocam_rounded),
          ),
          IconButton(
            tooltip: 'Chat options',
            onPressed: _showChatMenu,
            icon: const Icon(Icons.more_vert_rounded),
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

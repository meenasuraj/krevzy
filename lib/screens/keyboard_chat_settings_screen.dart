import 'package:flutter/material.dart';

import '../services/krevzy_keyboard_chat_settings.dart';

class KeyboardChatSettingsScreen extends StatefulWidget {
  const KeyboardChatSettingsScreen({super.key});

  @override
  State<KeyboardChatSettingsScreen> createState() =>
      _KeyboardChatSettingsScreenState();
}

class _KeyboardChatSettingsScreenState
    extends State<KeyboardChatSettingsScreen> {
  Map<String, Object> _values = {};
  bool _loading = true;

  static const _fonts = <String>[
    'Default',
    'Serif',
    'Mono',
    'Rounded',
    'Elegant',
    'Typewriter',
    'Playful',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final values = await KrevzyKeyboardChatSettings.load();
    if (!mounted) return;
    setState(() {
      _values = values;
      _loading = false;
    });
  }

  bool _bool(String key) => (_values[key] as bool?) ?? true;

  double _double(String key) => (_values[key] as double?) ?? 16.0;

  String _string(String key) => (_values[key] as String?) ?? 'Default';

  Future<void> _setBool(String key, bool value) async {
    await KrevzyKeyboardChatSettings.setBool(key, value);
    if (!mounted) return;
    setState(() => _values[key] = value);
  }

  Future<void> _setString(String key, String value) async {
    await KrevzyKeyboardChatSettings.setString(key, value);
    if (!mounted) return;
    setState(() => _values[key] = value);
  }

  Future<void> _setDouble(String key, double value) async {
    await KrevzyKeyboardChatSettings.setDouble(key, value);
    if (!mounted) return;
    setState(() => _values[key] = value);
  }

  Future<void> _reset() async {
    await KrevzyKeyboardChatSettings.reset();
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Keyboard & chat settings restored')),
    );
  }

  TextStyle _previewStyle(String font, double size) {
    final base = TextStyle(fontSize: size, height: 1.25);
    if (font == 'Serif') return base.copyWith(fontFamily: 'serif');
    if (font == 'Mono') return base.copyWith(fontFamily: 'monospace');
    if (font == 'Rounded') {
      return base.copyWith(letterSpacing: .2, fontWeight: FontWeight.w500);
    }
    if (font == 'Elegant') {
      return base.copyWith(fontFamily: 'serif', fontStyle: FontStyle.italic);
    }
    if (font == 'Typewriter') {
      return base.copyWith(fontFamily: 'monospace', letterSpacing: .4);
    }
    if (font == 'Playful') {
      return base.copyWith(letterSpacing: .5, fontWeight: FontWeight.w700);
    }
    return base;
  }

  Widget _fontSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _fonts.map((font) {
        final selected = _string(KrevzyKeyboardChatSettings.font) == font;
        return ChoiceChip(
          selected: selected,
          label: Text('Aa', style: _previewStyle(font, 16)),
          avatar: Text(
            font.substring(0, 1),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          onSelected: (_) => _setString(KrevzyKeyboardChatSettings.font, font),
        );
      }).toList(),
    );
  }

  Widget _fontSize() {
    final value = _double(KrevzyKeyboardChatSettings.fontSize)
        .clamp(13.0, 24.0)
        .toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Message size',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              '${value.toStringAsFixed(0)} px',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        Slider(
          value: value,
          min: 13,
          max: 24,
          divisions: 11,
          label: value.toStringAsFixed(0),
          onChanged: (v) => _setDouble(KrevzyKeyboardChatSettings.fontSize, v),
        ),
      ],
    );
  }

  Widget _switchTile(String title, String subtitle, IconData icon, String key) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      value: _bool(key),
      onChanged: (v) => _setBool(key, v),
      secondary: Icon(icon, color: const Color(0xFF625B9B)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
    );
  }

  Widget _section(String title, IconData icon, List<Widget> children) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: const Color(0xFFF0EEFF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF625B9B)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _tickChoice(String value, String title, String subtitle) {
    return RadioListTile<String>(
      value: value,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      contentPadding: EdgeInsets.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF625B9B);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F7FF),
        foregroundColor: const Color(0xFF20202A),
        elevation: 0,
        title: const Text(
          'Keyboard & Chat Settings',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Reset',
            onPressed: _loading ? null : _reset,
            icon: const Icon(Icons.restart_alt_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
                children: [
                  const Text(
                    'Customize how typing and messages behave in Krevzy.',
                    style: TextStyle(color: Color(0xFF555361), fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  _section('Message appearance', Icons.text_fields_rounded, [
                    const Text(
                      'Font',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    _fontSelector(),
                    const SizedBox(height: 12),
                    _fontSize(),
                    const Divider(height: 20),
                    _switchTile(
                      'Text editing',
                      'Keep normal text editing controls enabled.',
                      Icons.edit_rounded,
                      KrevzyKeyboardChatSettings.textEditing,
                    ),
                  ]),
                  const SizedBox(height: 12),
                  _section(
                    'Composer & content',
                    Icons.chat_bubble_outline_rounded,
                    [
                      _switchTile(
                        'Stickers',
                        'Show the sticker picker in chat.',
                        Icons.stars_rounded,
                        KrevzyKeyboardChatSettings.stickers,
                      ),
                      _switchTile(
                        'Emoji',
                        'Show emoji tools in the composer.',
                        Icons.emoji_emotions_outlined,
                        KrevzyKeyboardChatSettings.emoji,
                      ),
                      _switchTile(
                        'GIFs',
                        'Allow GIF tools when available.',
                        Icons.gif_box_outlined,
                        KrevzyKeyboardChatSettings.gif,
                      ),
                      _switchTile(
                        'Clipboard',
                        'Show paste/clipboard actions.',
                        Icons.content_paste_rounded,
                        KrevzyKeyboardChatSettings.clipboard,
                      ),
                      _switchTile(
                        'Share',
                        'Allow sharing message content.',
                        Icons.share_rounded,
                        KrevzyKeyboardChatSettings.share,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _section(
                    'Photos, videos & camera',
                    Icons.photo_camera_back_outlined,
                    [
                      _switchTile(
                        'Photos',
                        'Allow photo selection from the gallery.',
                        Icons.photo_library_outlined,
                        KrevzyKeyboardChatSettings.photos,
                      ),
                      _switchTile(
                        'Videos',
                        'Allow video selection from the gallery.',
                        Icons.video_library_outlined,
                        KrevzyKeyboardChatSettings.videos,
                      ),
                      _switchTile(
                        'Camera',
                        'Allow taking photos or videos with camera.',
                        Icons.camera_alt_outlined,
                        KrevzyKeyboardChatSettings.camera,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _section('Voice', Icons.mic_none_rounded, [
                    _switchTile(
                      'Voice messages',
                      'Show the voice-message action.',
                      Icons.mic_rounded,
                      KrevzyKeyboardChatSettings.voice,
                    ),
                    _switchTile(
                      'Voice preview',
                      'Preview a recording before sending.',
                      Icons.play_circle_outline_rounded,
                      KrevzyKeyboardChatSettings.voicePreview,
                    ),
                  ]),
                  const SizedBox(height: 12),
                  _section('Typing assistance', Icons.keyboard_alt_outlined, [
                    _switchTile(
                      'Correction',
                      'Krevzy preference for text correction.',
                      Icons.spellcheck_rounded,
                      KrevzyKeyboardChatSettings.correction,
                    ),
                    _switchTile(
                      'Suggestions',
                      'Krevzy preference for suggestions.',
                      Icons.lightbulb_outline_rounded,
                      KrevzyKeyboardChatSettings.suggestions,
                    ),
                    _switchTile(
                      'Next-word prediction',
                      'Krevzy preference for next-word suggestions.',
                      Icons.next_plan_outlined,
                      KrevzyKeyboardChatSettings.nextWord,
                    ),
                    _switchTile(
                      'Glide typing',
                      'Krevzy preference for swipe typing.',
                      Icons.gesture_rounded,
                      KrevzyKeyboardChatSettings.glideTyping,
                    ),
                    _switchTile(
                      'Resizable keyboard',
                      'Allow Krevzy keyboard layout preferences.',
                      Icons.height_rounded,
                      KrevzyKeyboardChatSettings.resizeKeyboard,
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(4, 4, 4, 8),
                      child: Text(
                        'Note: Android/Gboard controls its own correction, suggestions, Glide typing and keyboard height. Krevzy stores these preferences but cannot directly change Gboard system settings.',
                        style: TextStyle(
                          color: Color(0xFF555361),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  _section('Message ticks', Icons.done_all_rounded, [
                    RadioGroup<String>(
                      groupValue: _string(KrevzyKeyboardChatSettings.tickMode),
                      onChanged: (value) {
                        if (value != null) {
                          _setString(
                            KrevzyKeyboardChatSettings.tickMode,
                            value,
                          );
                        }
                      },
                      child: Column(
                        children: [
                          _tickChoice(
                            'single',
                            'Single tick',
                            'Show one tick.',
                          ),
                          _tickChoice(
                            'read',
                            'Single + double tick',
                            'Show read state with a second tick.',
                          ),
                          _tickChoice(
                            'off',
                            'Hide ticks',
                            'Do not show ticks.',
                          ),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.restore_rounded),
                    label: const Text('Restore all defaults'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primary,
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
    );
  }
}

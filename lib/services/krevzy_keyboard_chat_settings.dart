import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KrevzyKeyboardChatSettings {
  KrevzyKeyboardChatSettings._();

  static const _prefix = 'krevzy_keyboard_chat_';

  static const font = '${_prefix}font';
  static const fontSize = '${_prefix}font_size';
  static const tickMode = '${_prefix}tick_mode';
  static const stickers = '${_prefix}stickers';
  static const emoji = '${_prefix}emoji';
  static const clipboard = '${_prefix}clipboard';
  static const voice = '${_prefix}voice';
  static const photos = '${_prefix}photos';
  static const videos = '${_prefix}videos';
  static const camera = '${_prefix}camera';
  static const textEditing = '${_prefix}text_editing';
  static const correction = '${_prefix}correction';
  static const suggestions = '${_prefix}suggestions';
  static const nextWord = '${_prefix}next_word';
  static const glideTyping = '${_prefix}glide_typing';
  static const resizeKeyboard = '${_prefix}resize_keyboard';
  static const keyboardHeight = '${_prefix}keyboard_height';
  static const share = '${_prefix}share';
  static const gif = '${_prefix}gif';
  static const voicePreview = '${_prefix}voice_preview';

  static const defaults = <String, Object>{
    font: 'Default',
    fontSize: 16.0,
    tickMode: 'read',
    stickers: true,
    emoji: true,
    clipboard: true,
    voice: true,
    photos: true,
    videos: true,
    camera: true,
    textEditing: true,
    correction: true,
    suggestions: true,
    nextWord: true,
    glideTyping: true,
    resizeKeyboard: true,
    keyboardHeight: 1.0,
    share: true,
    gif: true,
    voicePreview: true,
  };

  static final ValueNotifier<int> changed = ValueNotifier<int>(0);

  static Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  static Future<void> setBool(String key, bool value) async {
    final p = await _prefs();
    await p.setBool(key, value);
    changed.value++;
  }

  static Future<void> setDouble(String key, double value) async {
    final p = await _prefs();
    await p.setDouble(key, value);
    changed.value++;
  }

  static Future<void> setString(String key, String value) async {
    final p = await _prefs();
    await p.setString(key, value);
    changed.value++;
  }

  static Future<Object> get(String key) async {
    final p = await _prefs();
    final fallback = defaults[key];
    if (fallback is bool) return p.getBool(key) ?? fallback;
    if (fallback is double) return p.getDouble(key) ?? fallback;
    if (fallback is String) return p.getString(key) ?? fallback;
    return fallback ?? '';
  }

  static Future<Map<String, Object>> load() async {
    final p = await _prefs();
    return {
      for (final entry in defaults.entries)
        entry.key: switch (entry.value) {
          bool _ => p.getBool(entry.key) ?? entry.value,
          double _ => p.getDouble(entry.key) ?? entry.value,
          String _ => p.getString(entry.key) ?? entry.value,
          _ => entry.value,
        },
    };
  }

  static Future<void> reset() async {
    final p = await _prefs();
    for (final key in defaults.keys) {
      await p.remove(key);
    }
    changed.value++;
  }
}


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class KrevzyBackgroundService {
  /// Notifies the app shell that the selected app background changed.
  static final ValueNotifier<int> backgroundChanged = ValueNotifier<int>(0);

  static const _appTypeKey = 'krevzy_app_background_type';
  static const _appUrlKey = 'krevzy_app_background_url';

  static final _prefsFuture = SharedPreferences.getInstance();
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;
  static final _storage = FirebaseStorage.instance;

  static Future<String> getAppBackgroundType() async {
    final prefs = await _prefsFuture;
    return prefs.getString(_appTypeKey) ?? 'krevzy';
  }

  static Future<String?> getAppBackgroundUrl() async {
    final prefs = await _prefsFuture;
    return prefs.getString(_appUrlKey);
  }

  static Future<void> setAppPreset(String preset) async {
    final prefs = await _prefsFuture;
    await prefs.setString(_appTypeKey, preset);
    if (preset != 'photo') await prefs.remove(_appUrlKey);
    backgroundChanged.value++;
  }

  static Future<String?> pickAndUploadAppBackground({
    ImageSource source = ImageSource.gallery,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Please log in first.');

    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 88,
      maxWidth: 2200,
    );
    if (picked == null) return null;

    final bytes = await picked.readAsBytes();
    final id = DateTime.now().millisecondsSinceEpoch;
    final path = 'users/${user.uid}/backgrounds/app_$id.jpg';
    final ref = _storage.ref().child(path);

    await ref.putData(
      Uint8List.fromList(bytes),
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final url = await ref.getDownloadURL();

    final prefs = await _prefsFuture;
    await prefs.setString(_appTypeKey, 'photo');
    await prefs.setString(_appUrlKey, url);
    backgroundChanged.value++;

    await _firestore.collection('users').doc(user.uid).set({
      'appBackground': {
        'type': 'photo',
        'storagePath': path,
        'url': url,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    }, SetOptions(merge: true));

    return url;
  }

  static Future<String?> getChatBackgroundUrl(String chatId) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final snap = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('chatSettings')
        .doc(chatId)
        .get();
    return snap.data()?['backgroundUrl']?.toString();
  }

  static Future<void> setChatPreset(String chatId, String preset) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Please log in first.');
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('chatSettings')
        .doc(chatId)
        .set({
      'backgroundType': preset,
      'backgroundUrl': null,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<String?> pickAndUploadChatBackground({
    required String chatId,
    ImageSource source = ImageSource.gallery,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Please log in first.');

    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 88,
      maxWidth: 2200,
    );
    if (picked == null) return null;

    final bytes = await picked.readAsBytes();
    final id = DateTime.now().millisecondsSinceEpoch;
    final path = 'users/${user.uid}/chat-backgrounds/${chatId}_$id.jpg';
    final ref = _storage.ref().child(path);
    await ref.putData(
      Uint8List.fromList(bytes),
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final url = await ref.getDownloadURL();

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('chatSettings')
        .doc(chatId)
        .set({
      'backgroundType': 'photo',
      'backgroundUrl': url,
      'storagePath': path,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return url;
  }

  static Future<String?> pickAndUploadKeyboardBackground({
    ImageSource source = ImageSource.gallery,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Please log in first.');

    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 88,
      maxWidth: 2200,
    );
    if (picked == null) return null;

    final bytes = await picked.readAsBytes();
    final id = DateTime.now().millisecondsSinceEpoch;
    final path = 'users/${user.uid}/keyboard-backgrounds/keyboard_$id.jpg';
    final ref = _storage.ref().child(path);
    await ref.putData(
      Uint8List.fromList(bytes),
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final url = await ref.getDownloadURL();

    final prefs = await _prefsFuture;
    await prefs.setString('krevzy_keyboard_background_url', url);
    await prefs.setString('krevzy_keyboard_background_type', 'photo');

    await _firestore.collection('users').doc(user.uid).set({
      'keyboardBackground': {
        'type': 'photo',
        'storagePath': path,
        'url': url,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    }, SetOptions(merge: true));

    return url;
  }

  static Future<String?> getKeyboardBackgroundUrl() async {
    final prefs = await _prefsFuture;
    return prefs.getString('krevzy_keyboard_background_url');
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores and manages KREVZY app, keyboard/composer and per-chat backgrounds.
///
/// The API is intentionally static because existing KREVZY screens use
/// KrevzyBackgroundService.methodName(...).  [instance] is retained for
/// callers that prefer a singleton reference.
class KrevzyBackgroundService {
  KrevzyBackgroundService._();

  static final KrevzyBackgroundService instance = KrevzyBackgroundService._();

  static final ValueNotifier<int> backgroundChanged = ValueNotifier<int>(0);

  static const String _appTypeKey = 'krevzy_app_background_type';
  static const String _appUrlKey = 'krevzy_app_background_url';
  static const String _keyboardTypeKey = 'krevzy_keyboard_background_type';
  static const String _keyboardUrlKey = 'krevzy_keyboard_background_url';

  static final Future<SharedPreferences> _prefsFuture =
      SharedPreferences.getInstance();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final ImagePicker _picker = ImagePicker();

  static User? get currentUser => _auth.currentUser;

  // ---------------------------------------------------------------------------
  // APP BACKGROUND
  // ---------------------------------------------------------------------------

  static Future<String> getAppBackgroundType() async {
    final prefs = await _prefsFuture;
    return prefs.getString(_appTypeKey) ?? 'krevzy';
  }

  static Future<String?> getAppBackgroundUrl() async {
    final prefs = await _prefsFuture;
    return prefs.getString(_appUrlKey);
  }

  static Future<void> setAppPreset(String preset) async {
    final normalized = preset.trim().isEmpty ? 'krevzy' : preset.trim();

    final prefs = await _prefsFuture;
    await prefs.setString(_appTypeKey, normalized);

    if (normalized != 'photo') {
      await prefs.remove(_appUrlKey);
    }

    backgroundChanged.value++;
  }

  static Future<String?> pickAndUploadAppBackground({
    ImageSource source = ImageSource.gallery,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'Please log in first.',
      );
    }

    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 88,
      maxWidth: 2200,
      maxHeight: 2200,
    );

    if (picked == null) return null;

    final bytes = await picked.readAsBytes();
    if (bytes.isEmpty) {
      throw Exception('The selected image is empty.');
    }

    final id = DateTime.now().millisecondsSinceEpoch;
    final storagePath = 'users/${user.uid}/backgrounds/app_$id.jpg';
    final ref = _storage.ref().child(storagePath);

    await ref.putData(
      Uint8List.fromList(bytes),
      SettableMetadata(contentType: 'image/jpeg'),
    );

    final url = await ref.getDownloadURL();

    final prefs = await _prefsFuture;
    await prefs.setString(_appTypeKey, 'photo');
    await prefs.setString(_appUrlKey, url);

    await _firestore.collection('users').doc(user.uid).set({
      'appBackground': {
        'type': 'photo',
        'storagePath': storagePath,
        'url': url,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    }, SetOptions(merge: true));

    backgroundChanged.value++;
    return url;
  }

  // ---------------------------------------------------------------------------
  // KEYBOARD / COMPOSER BACKGROUND
  // ---------------------------------------------------------------------------

  static Future<String?> getKeyboardBackgroundUrl() async {
    final prefs = await _prefsFuture;
    return prefs.getString(_keyboardUrlKey);
  }

  static Future<String> getKeyboardBackgroundType() async {
    final prefs = await _prefsFuture;
    return prefs.getString(_keyboardTypeKey) ?? 'default';
  }

  static Future<String?> pickAndUploadKeyboardBackground({
    ImageSource source = ImageSource.gallery,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'Please log in first.',
      );
    }

    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 88,
      maxWidth: 2200,
      maxHeight: 2200,
    );

    if (picked == null) return null;

    final bytes = await picked.readAsBytes();
    if (bytes.isEmpty) {
      throw Exception('The selected image is empty.');
    }

    final id = DateTime.now().millisecondsSinceEpoch;
    final storagePath =
        'users/${user.uid}/keyboard-backgrounds/keyboard_$id.jpg';
    final ref = _storage.ref().child(storagePath);

    await ref.putData(
      Uint8List.fromList(bytes),
      SettableMetadata(contentType: 'image/jpeg'),
    );

    final url = await ref.getDownloadURL();

    final prefs = await _prefsFuture;
    await prefs.setString(_keyboardTypeKey, 'photo');
    await prefs.setString(_keyboardUrlKey, url);

    await _firestore.collection('users').doc(user.uid).set({
      'keyboardBackground': {
        'type': 'photo',
        'storagePath': storagePath,
        'url': url,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    }, SetOptions(merge: true));

    backgroundChanged.value++;
    return url;
  }

  static Future<void> setKeyboardDefault() async {
    final prefs = await _prefsFuture;
    await prefs.setString(_keyboardTypeKey, 'default');
    await prefs.remove(_keyboardUrlKey);
    backgroundChanged.value++;
  }

  // ---------------------------------------------------------------------------
  // CHAT BACKGROUND
  // ---------------------------------------------------------------------------

  static Future<String?> getChatBackgroundUrl(String chatId) async {
    final cleanChatId = chatId.trim();
    if (cleanChatId.isEmpty) return null;

    final user = _auth.currentUser;

    debugPrint('========== GET CHAT BACKGROUND ==========');
    debugPrint('Chat ID: $cleanChatId');
    debugPrint('Current UID: ${user?.uid}');
    debugPrint('Is authenticated: ${user != null}');

    if (user == null) {
      debugPrint('No authenticated Firebase user.');
      return null;
    }

    final path = 'users/${user.uid}/chatSettings/$cleanChatId';
    debugPrint('Firestore path: $path');

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('chatSettings')
          .doc(cleanChatId)
          .get();

      if (!snapshot.exists) {
        debugPrint('No chat background document exists.');
        return null;
      }

      final data = snapshot.data();
      final value = data?['backgroundUrl'];

      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }

      return null;
    } on FirebaseException catch (e, stackTrace) {
      debugPrint('Chat background Firebase error.');
      debugPrint('Path: $path');
      debugPrint('Code: ${e.code}');
      debugPrint('Message: ${e.message}');
      debugPrint('$stackTrace');
      rethrow;
    }
  }

  static Future<String?> getChatBackgroundType(String chatId) async {
    final cleanChatId = chatId.trim();
    if (cleanChatId.isEmpty) return null;

    final user = _auth.currentUser;
    if (user == null) return null;

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('chatSettings')
        .doc(cleanChatId)
        .get();

    return snapshot.data()?['backgroundType']?.toString();
  }

  /// Saves a chat preset.
  ///
  /// [backgroundUrl] is optional so older callers can simply pass a preset.
  /// For a photo, use [pickAndUploadChatBackground].
  static Future<void> setChatPreset(
    String chatId,
    String preset, {
    String? backgroundUrl,
  }) async {
    final cleanChatId = chatId.trim();
    if (cleanChatId.isEmpty) {
      throw ArgumentError('Chat ID is required.');
    }

    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'User is not authenticated.',
      );
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('chatSettings')
        .doc(cleanChatId)
        .set({
          'backgroundType': preset.trim().isEmpty ? 'krevzy' : preset.trim(),
          'backgroundUrl': backgroundUrl,
          'storagePath': null,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  static Future<String?> pickAndUploadChatBackground({
    required String chatId,
    ImageSource source = ImageSource.gallery,
  }) async {
    final cleanChatId = chatId.trim();
    if (cleanChatId.isEmpty) {
      throw ArgumentError('Chat ID is required.');
    }

    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'User is not authenticated.',
      );
    }

    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1920,
    );

    if (picked == null) return null;

    final bytes = await picked.readAsBytes();
    if (bytes.isEmpty) {
      throw Exception('The selected image is empty.');
    }

    final id = DateTime.now().millisecondsSinceEpoch;
    final storagePath =
        'users/${user.uid}/chat-backgrounds/${cleanChatId}_$id.jpg';
    final ref = _storage.ref().child(storagePath);

    final uploadTask = ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    uploadTask.snapshotEvents.listen((snapshot) {
      if (snapshot.totalBytes > 0) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes * 100;
        debugPrint('Chat background upload: ${progress.toStringAsFixed(1)}%');
      }
    });

    await uploadTask;
    final url = await ref.getDownloadURL();

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('chatSettings')
        .doc(cleanChatId)
        .set({
          'backgroundType': 'photo',
          'backgroundUrl': url,
          'storagePath': storagePath,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    return url;
  }

  static Future<void> removeChatBackground(String chatId) async {
    final cleanChatId = chatId.trim();
    if (cleanChatId.isEmpty) return;

    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'User is not authenticated.',
      );
    }

    final docRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('chatSettings')
        .doc(cleanChatId);

    final snapshot = await docRef.get();
    final storagePath = snapshot.data()?['storagePath'];

    if (storagePath is String && storagePath.isNotEmpty) {
      try {
        await _storage.ref().child(storagePath).delete();
      } on FirebaseException catch (e) {
        // A missing file should not prevent the Firestore setting from being
        // removed.
        if (e.code != 'object-not-found') rethrow;
      }
    }

    await docRef.delete();
  }
}

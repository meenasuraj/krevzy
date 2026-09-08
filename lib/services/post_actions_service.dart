import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostActionsService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('You are not logged in.');
    return uid;
  }

  static DocumentReference<Map<String, dynamic>> _saved(String postId) =>
      _db.collection('users').doc(_uid).collection('savedPosts').doc(postId);

  static Future<bool> isSaved(String postId) async => (await _saved(postId).get()).exists;

  static Future<bool> toggleSaved(String postId) async {
    final ref = _saved(postId);
    final snap = await ref.get();
    if (snap.exists) {
      await ref.delete();
      return false;
    }
    await ref.set({
      'postId': postId,
      'savedAt': FieldValue.serverTimestamp(),
    });
    return true;
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> savedPosts() =>
      _db.collection('users').doc(_uid).collection('savedPosts')
          .snapshots();

  static Future<void> removeSaved(String postId) => _saved(postId).delete();

  static Future<void> blockUser(String targetUid, {String? username}) async {
    if (targetUid == _uid) throw Exception('You cannot block yourself.');
    await _db.collection('users').doc(_uid).collection('blocked').doc(targetUid).set({
      'userId': targetUid,
      'username': username ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> unblockUser(String targetUid) =>
      _db.collection('users').doc(_uid).collection('blocked').doc(targetUid).delete();

  static Future<bool> isBlocked(String targetUid) async =>
      (await _db.collection('users').doc(_uid).collection('blocked').doc(targetUid).get()).exists;

  static Stream<QuerySnapshot<Map<String, dynamic>>> blockedUsers() =>
      _db.collection('users').doc(_uid).collection('blocked').snapshots();
}

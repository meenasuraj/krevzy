import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountCenterService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static DocumentReference<Map<String, dynamic>> _settings(String uid) =>
      _db.collection('users').doc(uid).collection('settings').doc('accountCenter');

  static Future<void> setValue(String key, dynamic value) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('User is not signed in.');
    await _settings(uid).set({key: value, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> watchSettings() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _settings(uid).snapshots();
  }

  static Future<void> updateProfile({required String name, required String username, required String bio}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('User is not signed in.');
    final usernameLowercase = username.trim().toLowerCase();
    final existing = await _db.collection('users').where('usernameLowercase', isEqualTo: usernameLowercase).limit(2).get();
    final conflict = existing.docs.any((d) => d.id != uid);
    if (conflict) throw StateError('Username is already in use.');
    await _db.collection('users').doc(uid).set({
      'name': name.trim(),
      'nameLowercase': name.trim().toLowerCase(),
      'username': username.trim(),
      'usernameLowercase': usernameLowercase,
      'bio': bio.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> updateEmail(String newEmail) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('User is not signed in.');
    final email = newEmail.trim();
    if (email.isEmpty) throw StateError('Email is required.');
    await user.verifyBeforeUpdateEmail(email);
    await _userDoc(user.uid).set({
      'pendingEmail': email,
      'email': user.email,
      'emailUpdateRequestedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static DocumentReference<Map<String, dynamic>> _userDoc(String uid) => _db.collection('users').doc(uid);

  static Future<void> sendPasswordReset() async {
    final email = _auth.currentUser?.email;
    if (email == null || email.isEmpty) throw StateError('No email is linked to this account.');
    await _auth.sendPasswordResetEmail(email: email);
  }
}

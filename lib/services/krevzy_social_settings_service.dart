import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class KrevzySocialSettingsService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;
  static String get uid => _auth.currentUser?.uid ?? '';
  static DocumentReference<Map<String, dynamic>> get _settings =>
      _db.collection('users').doc(uid).collection('settings').doc('social');

  static Future<Map<String, dynamic>> getSettings() async {
    if (uid.isEmpty) return {};
    final snap = await _settings.get();
    return snap.data() ?? <String, dynamic>{};
  }

  static Future<bool?> getBool(String key) async {
    final data = await getSettings();
    final value = data[key];
    return value is bool ? value : null;
  }

  static Future<String?> getString(String key) async {
    final data = await getSettings();
    final value = data[key];
    return value?.toString();
  }
  static Future<void> setValue(String key, dynamic value) async {
    if (uid.isEmpty) throw Exception('Please log in first.');
    final now = FieldValue.serverTimestamp();
    await _settings.set({key: value, 'updatedAt': now}, SetOptions(merge: true));
    if (key == 'activity_status' && value is bool) {
      await _db.collection('users').doc(uid).set({
        'activityStatus': value,
        'updatedAt': now,
      }, SetOptions(merge: true));
    }
  }
  static Stream<DocumentSnapshot<Map<String, dynamic>>> watchSettings() =>
      uid.isEmpty ? const Stream.empty() : _settings.snapshots();
  static CollectionReference<Map<String, dynamic>> _people(String collection) =>
      _db.collection('users').doc(uid).collection(collection);
  static Stream<QuerySnapshot<Map<String, dynamic>>> watchPeople(String collection) =>
      uid.isEmpty ? const Stream.empty() : _people(collection).orderBy('createdAt', descending: true).snapshots();
  static Future<void> addPersonByUsername(String collection, String username) async {
    if (uid.isEmpty || username.trim().isEmpty) return;
    final q = await _db.collection('users').where('usernameLowercase', isEqualTo: username.trim().toLowerCase()).limit(1).get();
    if (q.docs.isEmpty) throw Exception('User not found.');
    await addPerson(collection, q.docs.first.id);
  }
  static Future<void> addPerson(String collection, String targetUid) async {
    if (uid.isEmpty || targetUid.isEmpty || targetUid == uid) return;
    final userSnap = await _db.collection('users').doc(targetUid).get();
    if (!userSnap.exists) throw Exception('User not found.');
    final data = userSnap.data() ?? {};
    await _people(collection).doc(targetUid).set({
      'uid': targetUid,
      'username': data['username']?.toString() ?? '',
      'name': data['name']?.toString() ?? data['userName']?.toString() ?? '',
      'photoUrl': data['photoUrl']?.toString() ?? data['userPhotoUrl']?.toString() ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
  static Future<void> removePerson(String collection, String targetUid) async {
    if (uid.isEmpty) return;
    await _people(collection).doc(targetUid).delete();
  }
  static Future<void> writeActivity({required String type, required String title, String? targetUid, String? detail}) async {
    if (uid.isEmpty) return;
    await _db.collection('users').doc(uid).collection('activity').add({
      'type': type, 'title': title, 'detail': detail ?? '', 'targetUid': targetUid ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
  static Stream<QuerySnapshot<Map<String, dynamic>>> watchActivity() =>
      uid.isEmpty ? const Stream.empty() : _db.collection('users').doc(uid).collection('activity').orderBy('createdAt', descending: true).limit(200).snapshots();
  static Future<void> clearActivity() async {
    if (uid.isEmpty) return;
    final snap = await _db.collection('users').doc(uid).collection('activity').limit(200).get();
    final batch = _db.batch();
    for (final doc in snap.docs) { batch.delete(doc.reference); }
    await batch.commit();
  }
}

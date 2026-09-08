import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoomService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String get uid => _auth.currentUser?.uid ?? (throw Exception('Please log in first.'));

  static Stream<QuerySnapshot<Map<String, dynamic>>> watchPublicRooms() {
    return _firestore.collection('rooms').where('isPublic', isEqualTo: true).snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> watchMyRooms() {
    return _firestore.collection('rooms').where('ownerId', isEqualTo: uid).snapshots();
  }

  static Future<String> createRoom({
    required String name,
    required String username,
    required String description,
    required String category,
    required bool isPublic,
    required bool requiresApproval,
    required int maxMembers,
  }) async {
    final ref = _firestore.collection('rooms').doc();
    final now = FieldValue.serverTimestamp();
    final batch = _firestore.batch();
    batch.set(ref, {
      'ownerId': uid,
      'name': name.trim(),
      'username': username.trim().toLowerCase(),
      'description': description.trim(),
      'category': category,
      'isPublic': isPublic,
      'requiresApproval': requiresApproval,
      'maxMembers': maxMembers,
      'memberCount': 1,
      'onlineCount': 1,
      'createdAt': now,
      'updatedAt': now,
    });
    batch.set(ref.collection('members').doc(uid), {
      'uid': uid,
      'role': 'owner',
      'status': 'active',
      'joinedAt': now,
    });
    await batch.commit();
    return ref.id;
  }

  static Future<void> joinRoom(String roomId) async {
    final roomRef = _firestore.collection('rooms').doc(roomId);
    final memberRef = roomRef.collection('members').doc(uid);
    final snap = await roomRef.get();
    if (!snap.exists) throw Exception('Room not found.');
    final data = snap.data()!;
    final count = (data['memberCount'] as num?)?.toInt() ?? 0;
    final max = (data['maxMembers'] as num?)?.toInt() ?? 100;
    if (count >= max) throw Exception('This room is full.');
    if (data['requiresApproval'] == true && data['ownerId'] != uid) {
      await roomRef.collection('joinRequests').doc(uid).set({'uid': uid, 'status': 'pending', 'requestedAt': FieldValue.serverTimestamp()});
      return;
    }
    final batch = _firestore.batch();
    batch.set(memberRef, {'uid': uid, 'role': 'member', 'status': 'active', 'joinedAt': FieldValue.serverTimestamp()});
    batch.update(roomRef, {'memberCount': FieldValue.increment(1), 'updatedAt': FieldValue.serverTimestamp()});
    await batch.commit();
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> watchRoom(String roomId) => _firestore.collection('rooms').doc(roomId).snapshots();

  static Stream<QuerySnapshot<Map<String, dynamic>>> watchMembers(String roomId) => _firestore.collection('rooms').doc(roomId).collection('members').snapshots();

  static Stream<QuerySnapshot<Map<String, dynamic>>> watchMessages(String roomId) => _firestore.collection('rooms').doc(roomId).collection('messages').orderBy('createdAt', descending: true).limit(100).snapshots();

  static Future<void> sendMessage({required String roomId, required String text}) async {
    final value = text.trim();
    if (value.isEmpty || value.length > 500) return;
    await _firestore.collection('rooms').doc(roomId).collection('messages').add({
      'senderId': uid,
      'text': value,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> requestJoin(String roomId) async {
    await _firestore.collection('rooms').doc(roomId).collection('joinRequests').doc(uid).set({
      'uid': uid,
      'status': 'pending',
      'requestedAt': FieldValue.serverTimestamp(),
    });
  }
}

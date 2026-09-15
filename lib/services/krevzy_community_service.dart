import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/krevzy_community.dart';
import '../models/krevzy_challenge.dart';

class KrevzyCommunityService {
  KrevzyCommunityService._();

  static final KrevzyCommunityService instance = KrevzyCommunityService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('User is not signed in.');
    }

    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _rooms =>
      _firestore.collection('gameRooms');

  Future<String> createRoom({
    required String name,
    required String description,
    required CommunityCategory category,
    bool isPublic = true,
    bool allowMemberChallenges = true,
    bool allowMemberRules = true,
  }) async {
    final uid = _uid;

    if (name.trim().isEmpty) {
      throw ArgumentError('Room name is required.');
    }

    final userDoc = await _firestore.collection('users').doc(uid).get();

    final userData = userDoc.data();

    final ownerName =
        userData?['userName']?.toString() ??
        userData?['username']?.toString() ??
        _auth.currentUser?.displayName ??
        'KREVZY User';

    final room = await _rooms.add({
      'name': name.trim(),
      'description': description.trim(),
      'category': category.value,
      'ownerId': uid,
      'ownerName': ownerName,
      'isPublic': isPublic,
      'allowMemberChallenges': allowMemberChallenges,
      'allowMemberRules': allowMemberRules,
      'memberCount': 1,
      'challengeCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await room.collection('members').doc(uid).set({
      'userId': uid,
      'role': 'owner',
      'joinedAt': FieldValue.serverTimestamp(),
    });

    return room.id;
  }

  Stream<List<KrevzyCommunity>> watchPublicRooms() {
    return _rooms.where('isPublic', isEqualTo: true).snapshots().map((
      snapshot,
    ) {
      final rooms = snapshot.docs
          .map((doc) => KrevzyCommunity.fromMap(doc.id, doc.data()))
          .toList();

      rooms.sort((a, b) => b.memberCount.compareTo(a.memberCount));

      return rooms;
    });
  }

  Stream<KrevzyCommunity?> watchRoom(String roomId) {
    return _rooms.doc(roomId).snapshots().map((doc) {
      if (!doc.exists) {
        return null;
      }

      return KrevzyCommunity.fromMap(doc.id, doc.data()!);
    });
  }

  Future<bool> isMember(String roomId) async {
    final member = await _rooms
        .doc(roomId)
        .collection('members')
        .doc(_uid)
        .get();

    return member.exists;
  }

  Future<void> joinRoom(String roomId) async {
    final uid = _uid;

    final roomRef = _rooms.doc(roomId);
    final memberRef = roomRef.collection('members').doc(uid);

    final member = await memberRef.get();

    if (member.exists) {
      return;
    }

    await _firestore.runTransaction((transaction) async {
      final roomSnapshot = await transaction.get(roomRef);

      if (!roomSnapshot.exists) {
        throw StateError('Room does not exist.');
      }

      final data = roomSnapshot.data()!;

      final count = (data['memberCount'] as num?)?.toInt() ?? 0;

      transaction.set(memberRef, {
        'userId': uid,
        'role': 'member',
        'joinedAt': FieldValue.serverTimestamp(),
      });

      transaction.update(roomRef, {
        'memberCount': count + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> leaveRoom(String roomId) async {
    final uid = _uid;

    final roomRef = _rooms.doc(roomId);
    final memberRef = roomRef.collection('members').doc(uid);

    await _firestore.runTransaction((transaction) async {
      final roomSnapshot = await transaction.get(roomRef);

      final memberSnapshot = await transaction.get(memberRef);

      if (!memberSnapshot.exists || !roomSnapshot.exists) {
        return;
      }

      final data = roomSnapshot.data()!;

      final count = (data['memberCount'] as num?)?.toInt() ?? 1;

      transaction.delete(memberRef);

      transaction.update(roomRef, {
        'memberCount': count > 0 ? count - 1 : 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchMessages(String roomId) {
    return _rooms
        .doc(roomId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  Future<void> sendMessage({
    required String roomId,
    required String text,
  }) async {
    final clean = text.trim();

    if (clean.isEmpty) {
      return;
    }

    final uid = _uid;

    final member = await _rooms
        .doc(roomId)
        .collection('members')
        .doc(uid)
        .get();

    if (!member.exists) {
      throw StateError('Join the room before chatting.');
    }

    final userDoc = await _firestore.collection('users').doc(uid).get();

    final userData = userDoc.data();

    final username =
        userData?['userName']?.toString() ??
        userData?['username']?.toString() ??
        _auth.currentUser?.displayName ??
        'KREVZY User';

    await _rooms.doc(roomId).collection('messages').add({
      'userId': uid,
      'username': username,
      'text': clean,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchChallenges(String roomId) {
    return _rooms
        .doc(roomId)
        .collection('challenges')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<String> createChallenge({
    required String roomId,
    required String title,
    required String description,
    required ChallengeType type,
    String gameName = '',
    int level = 1,
    int xpReward = 25,
    bool requiresEvidence = false,
    DateTime? expiresAt,
  }) async {
    final uid = _uid;

    final roomRef = _rooms.doc(roomId);

    final roomSnapshot = await roomRef.get();

    if (!roomSnapshot.exists) {
      throw StateError('Room does not exist.');
    }

    final roomData = roomSnapshot.data()!;

    final ownerId = roomData['ownerId']?.toString() ?? '';

    final allowMemberChallenges = roomData['allowMemberChallenges'] != false;

    final memberSnapshot = await roomRef.collection('members').doc(uid).get();

    if (!memberSnapshot.exists) {
      throw StateError('Join the room first.');
    }

    if (!allowMemberChallenges && uid != ownerId) {
      throw StateError('Only the room owner can create challenges.');
    }

    final challengeRef = roomRef.collection('challenges').doc();

    await challengeRef.set({
      'roomId': roomId,
      'creatorId': uid,
      'title': title.trim(),
      'description': description.trim(),
      'type': type.value,
      'gameName': gameName.trim(),
      'level': level,
      'xpReward': xpReward,
      'requiresEvidence': requiresEvidence,
      'isActive': true,
      'expiresAt': expiresAt == null ? null : Timestamp.fromDate(expiresAt),
      'createdAt': FieldValue.serverTimestamp(),
    });

    await roomRef.update({
      'challengeCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return challengeRef.id;
  }

  Future<String> submitChallenge({
    required String roomId,
    required String challengeId,
    String screenshotUrl = '',
    String note = '',
  }) async {
    final uid = _uid;

    final member = await _rooms
        .doc(roomId)
        .collection('members')
        .doc(uid)
        .get();

    if (!member.exists) {
      throw StateError('Join the room first.');
    }

    final submissionRef = _rooms
        .doc(roomId)
        .collection('challenges')
        .doc(challengeId)
        .collection('submissions')
        .doc();

    await submissionRef.set({
      'userId': uid,
      'screenshotUrl': screenshotUrl,
      'note': note.trim(),
      'status': 'pending',
      'xpAwarded': 0,
      'submittedAt': FieldValue.serverTimestamp(),
    });

    return submissionRef.id;
  }
}

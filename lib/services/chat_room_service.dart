import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/chat_room_rule.dart';

class ChatRoomService {
  ChatRoomService._();

  static final ChatRoomService instance = ChatRoomService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _rooms =>
      _firestore.collection('chatRooms');

  String get _uid {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('User is not logged in.');
    }

    return user.uid;
  }

  DocumentReference<Map<String, dynamic>> roomRef(String roomId) {
    return _rooms.doc(roomId);
  }

  CollectionReference<Map<String, dynamic>> rulesRef(String roomId) {
    return roomRef(roomId).collection('rules');
  }

  // ============================================================
  // ROOM
  // ============================================================

  Future<String> createRoom({
    required String name,
    required String description,
    required String category,
    required bool isPublic,
    required bool allowMemberChallenges,
    required bool allowMemberRules,
  }) async {
    final uid = _uid;

    final cleanName = name.trim();
    final cleanDescription = description.trim();
    final cleanCategory = category.trim();

    if (cleanName.isEmpty) {
      throw ArgumentError('Room name is required.');
    }

    if (cleanDescription.isEmpty) {
      throw ArgumentError('Room description is required.');
    }

    if (cleanCategory.isEmpty) {
      throw ArgumentError('Room category is required.');
    }

    final room = _rooms.doc();

    await room.set({
      'name': cleanName,
      'description': cleanDescription,
      'category': cleanCategory,
      'ownerId': uid,
      'isPublic': isPublic,
      'allowMemberChallenges': allowMemberChallenges,
      'allowMemberRules': allowMemberRules,
      'memberCount': 1,
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

  Stream<QuerySnapshot<Map<String, dynamic>>> watchPublicRooms() {
    return _rooms
        .where('isPublic', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchRoom(String roomId) {
    return roomRef(roomId).snapshots();
  }

  // ============================================================
  // MEMBERS
  // ============================================================

  Future<bool> isMember(String roomId) async {
    final uid = _uid;

    final doc = await roomRef(roomId).collection('members').doc(uid).get();

    return doc.exists;
  }

  Future<String?> getMemberRole(String roomId) async {
    final uid = _uid;

    final doc = await roomRef(roomId).collection('members').doc(uid).get();

    if (!doc.exists) {
      return null;
    }

    return (doc.data()?['role'] ?? 'member').toString();
  }

  Future<void> joinRoom(String roomId) async {
    final uid = _uid;

    final roomSnapshot = await roomRef(roomId).get();

    if (!roomSnapshot.exists) {
      throw StateError('Room does not exist.');
    }

    final roomData = roomSnapshot.data() ?? {};

    if (roomData['isPublic'] != true) {
      throw StateError('This room is private.');
    }

    final memberRef = roomRef(roomId).collection('members').doc(uid);

    final existing = await memberRef.get();

    if (existing.exists) {
      return;
    }

    await memberRef.set({
      'userId': uid,
      'role': 'member',
      'joinedAt': FieldValue.serverTimestamp(),
    });

    await roomRef(roomId).update({
      'memberCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> leaveRoom(String roomId) async {
    final uid = _uid;

    final memberRef = roomRef(roomId).collection('members').doc(uid);

    final memberSnapshot = await memberRef.get();

    if (!memberSnapshot.exists) {
      return;
    }

    final role = (memberSnapshot.data()?['role'] ?? 'member').toString();

    if (role == 'owner') {
      throw StateError('Room owner cannot leave the room.');
    }

    await memberRef.delete();

    await roomRef(roomId).update({
      'memberCount': FieldValue.increment(-1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchMembers(String roomId) {
    return roomRef(roomId)
        .collection('members')
        .orderBy('joinedAt')
        .snapshots();
  }

  // ============================================================
  // MESSAGES
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> watchMessages(String roomId) {
    return roomRef(roomId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> sendMessage({
    required String roomId,
    required String text,
  }) async {
    final uid = _uid;

    final cleanText = text.trim();

    if (cleanText.isEmpty) {
      return;
    }

    final member = await roomRef(roomId).collection('members').doc(uid).get();

    if (!member.exists) {
      throw StateError('You must join this room first.');
    }

    await roomRef(roomId).collection('messages').add({
      'senderId': uid,
      'text': cleanText,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await roomRef(roomId).update({'updatedAt': FieldValue.serverTimestamp()});
  }

  // ============================================================
  // RULES
  // ============================================================

  Stream<List<ChatRoomRule>> watchActiveRules(String roomId) {
    return rulesRef(roomId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(ChatRoomRule.fromDocument)
              .where((rule) => rule.status == 'active')
              .toList(),
        );
  }

  Stream<List<ChatRoomRule>> watchAllRules(String roomId) {
    return rulesRef(roomId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(ChatRoomRule.fromDocument).toList(),
        );
  }

  Future<String> addRule({
    required String roomId,
    required String title,
    required String description,
  }) async {
    final uid = _uid;

    final cleanTitle = title.trim();
    final cleanDescription = description.trim();

    if (cleanTitle.isEmpty) {
      throw ArgumentError('Rule title is required.');
    }

    if (cleanDescription.isEmpty) {
      throw ArgumentError('Rule description is required.');
    }

    final roomSnapshot = await roomRef(roomId).get();

    if (!roomSnapshot.exists) {
      throw StateError('Room does not exist.');
    }

    final roomData = roomSnapshot.data() ?? {};

    final ownerId = (roomData['ownerId'] ?? '').toString();

    if (ownerId != uid) {
      final role = await getMemberRole(roomId);

      if (role != 'moderator') {
        throw StateError(
          'Only the room owner or moderator can add active rules.',
        );
      }
    }

    final rule = rulesRef(roomId).doc();

    await rule.set({
      'roomId': roomId,
      'title': cleanTitle,
      'description': cleanDescription,
      'createdBy': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
      'status': 'active',
    });

    return rule.id;
  }

  Future<String> suggestRule({
    required String roomId,
    required String title,
    required String description,
  }) async {
    final uid = _uid;

    final cleanTitle = title.trim();
    final cleanDescription = description.trim();

    if (cleanTitle.isEmpty) {
      throw ArgumentError('Rule title is required.');
    }

    if (cleanDescription.isEmpty) {
      throw ArgumentError('Rule description is required.');
    }

    final member = await roomRef(roomId).collection('members').doc(uid).get();

    if (!member.exists) {
      throw StateError('You must join this room first.');
    }

    final rule = rulesRef(roomId).doc();

    await rule.set({
      'roomId': roomId,
      'title': cleanTitle,
      'description': cleanDescription,
      'createdBy': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': false,
      'status': 'pending',
    });

    return rule.id;
  }

  Future<void> approveRule({
    required String roomId,
    required String ruleId,
  }) async {
    final uid = _uid;

    final roomSnapshot = await roomRef(roomId).get();

    if (!roomSnapshot.exists) {
      throw StateError('Room does not exist.');
    }

    final roomData = roomSnapshot.data() ?? {};

    final ownerId = (roomData['ownerId'] ?? '').toString();

    if (ownerId != uid) {
      final role = await getMemberRole(roomId);

      if (role != 'moderator') {
        throw StateError('Only the room owner or moderator can approve rules.');
      }
    }

    await rulesRef(roomId).doc(ruleId).update({
      'isActive': true,
      'status': 'active',
      'approvedBy': uid,
      'approvedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rejectRule({
    required String roomId,
    required String ruleId,
  }) async {
    final uid = _uid;

    final roomSnapshot = await roomRef(roomId).get();

    if (!roomSnapshot.exists) {
      throw StateError('Room does not exist.');
    }

    final roomData = roomSnapshot.data() ?? {};

    final ownerId = (roomData['ownerId'] ?? '').toString();

    if (ownerId != uid) {
      final role = await getMemberRole(roomId);

      if (role != 'moderator') {
        throw StateError('Only the room owner or moderator can reject rules.');
      }
    }

    await rulesRef(roomId).doc(ruleId).update({
      'isActive': false,
      'status': 'rejected',
      'reviewedBy': uid,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deactivateRule({
    required String roomId,
    required String ruleId,
  }) async {
    final uid = _uid;

    final roomSnapshot = await roomRef(roomId).get();

    if (!roomSnapshot.exists) {
      throw StateError('Room does not exist.');
    }

    final roomData = roomSnapshot.data() ?? {};

    final ownerId = (roomData['ownerId'] ?? '').toString();

    if (ownerId != uid) {
      final role = await getMemberRole(roomId);

      if (role != 'moderator') {
        throw StateError(
          'Only the room owner or moderator can deactivate rules.',
        );
      }
    }

    await rulesRef(roomId).doc(ruleId).update({
      'isActive': false,
      'status': 'inactive',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // CHALLENGES
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> watchChallenges(String roomId) {
    return roomRef(roomId)
        .collection('challenges')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<String> createChallenge({
    required String roomId,
    required String title,
    required String description,
    required int rewardXp,
    DateTime? deadline,
  }) async {
    final uid = _uid;

    final roomSnapshot = await roomRef(roomId).get();

    if (!roomSnapshot.exists) {
      throw StateError('Room does not exist.');
    }

    final roomData = roomSnapshot.data() ?? {};

    final ownerId = (roomData['ownerId'] ?? '').toString();

    if (ownerId != uid) {
      final role = await getMemberRole(roomId);

      final allowed = roomData['allowMemberChallenges'] == true;

      if (!allowed || (role != 'moderator' && role != 'member')) {
        throw StateError('You cannot create challenges in this room.');
      }
    }

    final challenge = roomRef(roomId).collection('challenges').doc();

    await challenge.set({
      'roomId': roomId,
      'title': title.trim(),
      'description': description.trim(),
      'createdBy': uid,
      'rewardXp': rewardXp,
      'deadline': deadline == null ? null : Timestamp.fromDate(deadline),
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return challenge.id;
  }

  Future<String> submitChallenge({
    required String roomId,
    required String challengeId,
    required String evidenceUrl,
  }) async {
    final uid = _uid;

    final member = await roomRef(roomId).collection('members').doc(uid).get();

    if (!member.exists) {
      throw StateError('You must join this room first.');
    }

    final challenge = await roomRef(roomId)
        .collection('challenges')
        .doc(challengeId)
        .get();

    if (!challenge.exists) {
      throw StateError('Challenge does not exist.');
    }

    final submission = roomRef(roomId)
        .collection('challenges')
        .doc(challengeId)
        .collection('submissions')
        .doc();

    await submission.set({
      'userId': uid,
      'evidenceUrl': evidenceUrl,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return submission.id;
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/sports_room_catalog.dart';
import 'chat_room_service.dart';

/// Connects Krevzy Sports with the existing Room Chat system.
///
/// Sports rooms use stable IDs such as:
/// sports_cricket
/// sports_football
/// sports_basketball
/// etc.
class SportsRoomService {
  SportsRoomService._();

  static final SportsRoomService instance = SportsRoomService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ChatRoomService get _chatRoomService => ChatRoomService.instance;

  CollectionReference<Map<String, dynamic>> get _rooms =>
      _firestore.collection('chatRooms');

  User? get currentUser => _auth.currentUser;

  String? get currentUserId => _auth.currentUser?.uid;

  List<SportsRoomDefinition> get allSports => SportsRoomCatalog.all;

  // ---------------------------------------------------------------------------
  // LOOKUP
  // ---------------------------------------------------------------------------

  SportsRoomDefinition? getSportByRoomId(String roomId) {
    return SportsRoomCatalog.byId(roomId);
  }

  SportsRoomDefinition? getSportByCategory(String category) {
    return SportsRoomCatalog.byCategory(category);
  }

  String? getRoomIdForSport(String sport) {
    return SportsRoomCatalog.byCategory(sport)?.id;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getRoom(String roomId) {
    return _rooms.doc(roomId).get();
  }

  Future<Map<String, dynamic>?> getRoomData(String roomId) async {
    final snapshot = await _rooms.doc(roomId).get();

    if (!snapshot.exists) {
      return null;
    }

    final data = snapshot.data();

    if (data == null) {
      return null;
    }

    return <String, dynamic>{'id': snapshot.id, ...data};
  }

  Future<bool> roomExists(String roomId) async {
    final snapshot = await _rooms.doc(roomId).get();
    return snapshot.exists;
  }

  // ---------------------------------------------------------------------------
  // ROOM CREATION / PROVISIONING
  // ---------------------------------------------------------------------------

  /// Creates a sports room if it does not already exist.
  Future<String> ensureSportRoom(String sport, {String? ownerId}) async {
    final definition = SportsRoomCatalog.byCategory(sport);

    if (definition == null) {
      throw ArgumentError('Unknown sport: $sport');
    }

    return ensureSportRoomByDefinition(definition, ownerId: ownerId);
  }

  /// Creates a room using its catalog definition.
  Future<String> ensureSportRoomByDefinition(
    SportsRoomDefinition definition, {
    String? ownerId,
  }) async {
    final roomId = definition.id;

    final roomRef = _rooms.doc(roomId);

    final existing = await roomRef.get();

    if (existing.exists) {
      return roomId;
    }

    final uid = ownerId ?? currentUserId;

    if (uid == null || uid.isEmpty) {
      throw StateError('A logged-in user is required to create a sports room.');
    }

    await roomRef.set(<String, dynamic>{
      'name': '${definition.emoji} ${definition.name}',
      'description': definition.description,
      'category': definition.category,
      'ownerId': uid,
      'isPublic': true,
      'allowMemberChallenges': true,
      'allowMemberRules': true,
      'memberCount': 0,
      'isSportsRoom': true,
      'sportId': definition.id,
      'sportName': definition.name,
      'sportEmoji': definition.emoji,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return roomId;
  }

  /// Ensures all 20 sports rooms exist.
  Future<List<String>> ensureAllSportsRooms({String? ownerId}) async {
    final roomIds = <String>[];

    for (final definition in SportsRoomCatalog.all) {
      final roomId = await ensureSportRoomByDefinition(
        definition,
        ownerId: ownerId,
      );

      roomIds.add(roomId);
    }

    return roomIds;
  }

  Future<List<String>> provisionAllRooms({String? ownerId}) {
    return ensureAllSportsRooms(ownerId: ownerId);
  }

  // ---------------------------------------------------------------------------
  // STREAMS
  // ---------------------------------------------------------------------------

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchRoom(String roomId) {
    return _rooms.doc(roomId).snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchSportRoom(String sport) {
    final definition = SportsRoomCatalog.byCategory(sport);

    if (definition == null) {
      throw ArgumentError('Unknown sport: $sport');
    }

    return watchRoom(definition.id);
  }

  Stream<List<Map<String, dynamic>>> watchSportsRooms() {
    return _rooms
        .where('isSportsRoom', isEqualTo: true)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return <String, dynamic>{'id': doc.id, ...doc.data()};
          }).toList();
        });
  }

  // ---------------------------------------------------------------------------
  // JOIN
  // ---------------------------------------------------------------------------

  Future<void> joinSportRoom(String sport) async {
    final definition = SportsRoomCatalog.byCategory(sport);

    if (definition == null) {
      throw ArgumentError('Unknown sport: $sport');
    }

    await ensureSportRoomByDefinition(definition);

    await _chatRoomService.joinRoom(definition.id);
  }

  Future<void> joinSportRoomById(String roomId) async {
    final definition = SportsRoomCatalog.byId(roomId);

    if (definition == null) {
      throw ArgumentError('Unknown sports room ID: $roomId');
    }

    await ensureSportRoomByDefinition(definition);

    await _chatRoomService.joinRoom(roomId);
  }

  Future<bool> isMember(String roomId) {
    return _chatRoomService.isMember(roomId);
  }

  Future<bool> isSportRoomMember(String sport) async {
    final definition = SportsRoomCatalog.byCategory(sport);

    if (definition == null) {
      return false;
    }

    return isMember(definition.id);
  }

  // ---------------------------------------------------------------------------
  // LEAVE
  // ---------------------------------------------------------------------------

  Future<void> leaveSportRoom(String sport) async {
    final definition = SportsRoomCatalog.byCategory(sport);

    if (definition == null) {
      throw ArgumentError('Unknown sport: $sport');
    }

    await _chatRoomService.leaveRoom(definition.id);
  }

  Future<void> leaveSportRoomById(String roomId) async {
    if (!isSportsRoomId(roomId)) {
      throw ArgumentError('Unknown sports room ID: $roomId');
    }

    await _chatRoomService.leaveRoom(roomId);
  }

  // ---------------------------------------------------------------------------
  // ROOM INFORMATION
  // ---------------------------------------------------------------------------

  Future<int> getMemberCount(String roomId) async {
    final snapshot = await _rooms.doc(roomId).get();

    if (!snapshot.exists) {
      return 0;
    }

    final data = snapshot.data();

    if (data == null) {
      return 0;
    }

    final value = data['memberCount'];

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return 0;
  }

  Future<List<Map<String, dynamic>>> getSportsRooms() async {
    final snapshot = await _rooms.where('isSportsRoom', isEqualTo: true).get();

    return snapshot.docs.map((doc) {
      return <String, dynamic>{'id': doc.id, ...doc.data()};
    }).toList();
  }

  SportsRoomDefinition? definitionFromRoom(Map<String, dynamic> room) {
    final sportId = (room['sportId'] ?? room['id'] ?? '').toString();

    return SportsRoomCatalog.byId(sportId);
  }

  // ---------------------------------------------------------------------------
  // PREPARATION
  // ---------------------------------------------------------------------------

  Future<String> prepareSportRoom(String sport) async {
    final definition = SportsRoomCatalog.byCategory(sport);

    if (definition == null) {
      throw ArgumentError('Unknown sport: $sport');
    }

    await ensureSportRoomByDefinition(definition);

    return definition.id;
  }

  Future<void> prepareAllSportsRooms({String? ownerId}) async {
    await ensureAllSportsRooms(ownerId: ownerId);
  }

  // ---------------------------------------------------------------------------
  // SEARCH
  // ---------------------------------------------------------------------------

  List<SportsRoomDefinition> searchSports(String query) {
    final normalized = query.trim().toLowerCase();

    if (normalized.isEmpty) {
      return SportsRoomCatalog.all;
    }

    return SportsRoomCatalog.all.where((sport) {
      return sport.name.toLowerCase().contains(normalized) ||
          sport.category.toLowerCase().contains(normalized) ||
          sport.id.toLowerCase().contains(normalized);
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // VALIDATION
  // ---------------------------------------------------------------------------

  bool isSportsRoomId(String roomId) {
    return SportsRoomCatalog.byId(roomId) != null;
  }

  bool isSupportedSport(String sport) {
    return SportsRoomCatalog.byCategory(sport) != null;
  }

  List<String> get allRoomIds {
    return SportsRoomCatalog.all.map((sport) => sport.id).toList();
  }

  List<String> get allSportNames {
    return SportsRoomCatalog.all.map((sport) => sport.name).toList();
  }

  ChatRoomService get chatRoomService => _chatRoomService;
}

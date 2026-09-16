import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/sports_competition.dart';
import '../models/sports_event.dart';
import '../models/sports_match.dart';
import '../models/sports_player.dart';
import '../models/sports_standing.dart';
import '../models/sports_team.dart';
import 'sports_room_service.dart';
import 'sports_service.dart';

/// Synchronizes sports data from SportsService into Firestore.
///
/// Architecture:
///
/// Provider
///   ↓
/// SportsService
///   ↓
/// SportsSyncService
///   ↓
/// Firestore sports cache
///   ↓
/// Krevzy sports screens / rooms
///
/// This service does NOT generate fake scores.
/// Data is written only when supplied by the configured provider.
class SportsSyncService {
  SportsSyncService._();

  static final SportsSyncService instance = SportsSyncService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  SportsService get _sportsService => SportsService.instance;

  SportsRoomService get _roomService => SportsRoomService.instance;

  Timer? _syncTimer;

  bool _isSyncing = false;

  DateTime? _lastSyncAt;

  // ---------------------------------------------------------------------------
  // FIRESTORE COLLECTIONS
  // ---------------------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> get _matches =>
      _firestore.collection('sportsMatches');

  CollectionReference<Map<String, dynamic>> get _competitions =>
      _firestore.collection('sportsCompetitions');

  CollectionReference<Map<String, dynamic>> get _teams =>
      _firestore.collection('sportsTeams');

  CollectionReference<Map<String, dynamic>> get _players =>
      _firestore.collection('sportsPlayers');

  CollectionReference<Map<String, dynamic>> get _standings =>
      _firestore.collection('sportsStandings');

  CollectionReference<Map<String, dynamic>> get _events =>
      _firestore.collection('sportsEvents');

  // ---------------------------------------------------------------------------
  // STATE
  // ---------------------------------------------------------------------------

  bool get isSyncing => _isSyncing;

  DateTime? get lastSyncAt => _lastSyncAt;

  // ---------------------------------------------------------------------------
  // LIVE MATCH SYNC
  // ---------------------------------------------------------------------------

  /// Sync live matches for all supported sports.
  Future<int> syncLiveMatches() async {
    if (_isSyncing) {
      return 0;
    }

    _isSyncing = true;

    try {
      final matches = await _sportsService.getLiveMatches();

      if (matches.isEmpty) {
        _lastSyncAt = DateTime.now();
        return 0;
      }

      var count = 0;

      for (final match in matches) {
        await _writeMatch(match);
        count++;
      }

      _lastSyncAt = DateTime.now();

      return count;
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync live matches for one sport.
  Future<int> syncLiveMatchesForSport(String sport) async {
    final matches = await _sportsService.getLiveMatches(sport: sport);

    var count = 0;

    for (final match in matches) {
      await _writeMatch(match);
      count++;
    }

    _lastSyncAt = DateTime.now();

    return count;
  }

  // ---------------------------------------------------------------------------
  // UPCOMING MATCH SYNC
  // ---------------------------------------------------------------------------

  Future<int> syncUpcomingMatches({
    String? sport,
    DateTime? from,
    DateTime? to,
  }) async {
    final matches = await _sportsService.getUpcomingMatches(
      sport: sport,
      from: from,
      to: to,
    );

    var count = 0;

    for (final match in matches) {
      await _writeMatch(match);
      count++;
    }

    _lastSyncAt = DateTime.now();

    return count;
  }

  // ---------------------------------------------------------------------------
  // RESULTS SYNC
  // ---------------------------------------------------------------------------

  Future<int> syncResults({String? sport, DateTime? from, DateTime? to}) async {
    final matches = await _sportsService.getResults(
      sport: sport,
      from: from,
      to: to,
    );

    var count = 0;

    for (final match in matches) {
      await _writeMatch(match);
      count++;
    }

    _lastSyncAt = DateTime.now();

    return count;
  }

  // ---------------------------------------------------------------------------
  // COMPETITIONS
  // ---------------------------------------------------------------------------

  Future<int> syncCompetitions({String? sport}) async {
    final competitions = await _sportsService.getCompetitions(sport: sport);

    var count = 0;

    for (final competition in competitions) {
      await _writeCompetition(competition);
      count++;
    }

    return count;
  }

  // ---------------------------------------------------------------------------
  // TEAMS
  // ---------------------------------------------------------------------------

  Future<int> syncTeams({String? sport, String? competitionId}) async {
    final teams = await _sportsService.getTeams(
      sport: sport,
      competitionId: competitionId,
    );

    var count = 0;

    for (final team in teams) {
      await _writeTeam(team);
      count++;
    }

    return count;
  }

  // ---------------------------------------------------------------------------
  // PLAYERS
  // ---------------------------------------------------------------------------

  Future<int> syncPlayers({String? sport, String? teamId}) async {
    final players = await _sportsService.getPlayers(
      sport: sport,
      teamId: teamId,
    );

    var count = 0;

    for (final player in players) {
      await _writePlayer(player);
      count++;
    }

    return count;
  }

  // ---------------------------------------------------------------------------
  // STANDINGS
  // ---------------------------------------------------------------------------

  Future<int> syncStandings({
    required String competitionId,
    String? sport,
  }) async {
    final standings = await _sportsService.getStandings(
      competitionId: competitionId,
      sport: sport,
    );

    var count = 0;

    for (final standing in standings) {
      await _writeStanding(standing);
      count++;
    }

    return count;
  }

  // ---------------------------------------------------------------------------
  // MATCH EVENTS
  // ---------------------------------------------------------------------------

  Future<int> syncMatchEvents(String matchId, {String? sport}) async {
    final events = await _sportsService.getMatchEvents(matchId, sport: sport);

    var count = 0;

    for (final event in events) {
      await _writeEvent(event);
      count++;
    }

    return count;
  }

  // ---------------------------------------------------------------------------
  // COMPLETE SYNC
  // ---------------------------------------------------------------------------

  /// Runs the main sports synchronization cycle.
  ///
  /// The default cycle synchronizes:
  /// - live matches
  /// - upcoming matches
  /// - recent results
  Future<SportsSyncResult> syncAll({
    DateTime? upcomingFrom,
    DateTime? upcomingTo,
    DateTime? resultsFrom,
    DateTime? resultsTo,
  }) async {
    if (_isSyncing) {
      return SportsSyncResult.empty();
    }

    _isSyncing = true;

    try {
      var liveCount = 0;
      var upcomingCount = 0;
      var resultCount = 0;

      final liveMatches = await _sportsService.getLiveMatches();

      for (final match in liveMatches) {
        await _writeMatch(match);
        liveCount++;
      }

      final upcomingMatches = await _sportsService.getUpcomingMatches(
        from: upcomingFrom,
        to: upcomingTo,
      );

      for (final match in upcomingMatches) {
        await _writeMatch(match);
        upcomingCount++;
      }

      final results = await _sportsService.getResults(
        from: resultsFrom,
        to: resultsTo,
      );

      for (final match in results) {
        await _writeMatch(match);
        resultCount++;
      }

      _lastSyncAt = DateTime.now();

      return SportsSyncResult(
        liveMatches: liveCount,
        upcomingMatches: upcomingCount,
        results: resultCount,
        syncedAt: _lastSyncAt!,
      );
    } finally {
      _isSyncing = false;
    }
  }

  // ---------------------------------------------------------------------------
  // AUTOMATIC SYNC
  // ---------------------------------------------------------------------------

  /// Starts automatic live-score synchronization.
  ///
  /// The default interval is 30 seconds.
  void startAutoSync({Duration interval = const Duration(seconds: 30)}) {
    stopAutoSync();

    _syncTimer = Timer.periodic(interval, (_) async {
      try {
        await syncLiveMatches();
      } catch (_) {
        // A temporary provider/network error should not terminate
        // the periodic synchronization loop.
      }
    });

    // Run once immediately.
    unawaited(syncLiveMatches().catchError((_) => 0));
  }

  void stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  // ---------------------------------------------------------------------------
  // MATCH WRITE
  // ---------------------------------------------------------------------------

  Future<void> _writeMatch(SportsMatch match) async {
    await _matches.doc(match.id).set(<String, dynamic>{
      ...match.toMap(),
      'isLive': match.isLive,
      'syncedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ---------------------------------------------------------------------------
  // COMPETITION WRITE
  // ---------------------------------------------------------------------------

  Future<void> _writeCompetition(SportsCompetition competition) async {
    await _competitions.doc(competition.id).set(<String, dynamic>{
      ...competition.toMap(),
      'syncedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ---------------------------------------------------------------------------
  // TEAM WRITE
  // ---------------------------------------------------------------------------

  Future<void> _writeTeam(SportsTeam team) async {
    await _teams.doc(team.id).set(<String, dynamic>{
      ...team.toMap(),
      'syncedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ---------------------------------------------------------------------------
  // PLAYER WRITE
  // ---------------------------------------------------------------------------

  Future<void> _writePlayer(SportsPlayer player) async {
    await _players.doc(player.id).set(<String, dynamic>{
      ...player.toMap(),
      'syncedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ---------------------------------------------------------------------------
  // STANDING WRITE
  // ---------------------------------------------------------------------------

  Future<void> _writeStanding(SportsStanding standing) async {
    final documentId = '${standing.competitionId}_${standing.teamId}';

    await _standings.doc(documentId).set(<String, dynamic>{
      ...standing.toMap(),
      'syncedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ---------------------------------------------------------------------------
  // EVENT WRITE
  // ---------------------------------------------------------------------------

  Future<void> _writeEvent(SportsEvent event) async {
    await _events.doc(event.id).set(<String, dynamic>{
      ...event.toMap(),
      'syncedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ---------------------------------------------------------------------------
  // FIRESTORE LIVE DATA
  // ---------------------------------------------------------------------------

  Stream<List<SportsMatch>> watchLiveMatches({String? sport}) {
    Query<Map<String, dynamic>> query = _matches.where(
      'isLive',
      isEqualTo: true,
    );

    if (sport != null && sport.trim().isNotEmpty) {
      query = query.where('sport', isEqualTo: sport);
    }

    return query.snapshots().map((snapshot) {
      final matches = snapshot.docs.map((doc) {
        return SportsMatch.fromFirestore(doc);
      }).toList();

      matches.sort((a, b) {
        final aTime = a.startTime;
        final bTime = b.startTime;

        if (aTime == null && bTime == null) {
          return 0;
        }

        if (aTime == null) {
          return 1;
        }

        if (bTime == null) {
          return -1;
        }

        return aTime.compareTo(bTime);
      });

      return matches;
    });
  }

  Stream<List<SportsMatch>> watchMatches({String? sport, bool? liveOnly}) {
    Query<Map<String, dynamic>> query = _matches;

    if (sport != null && sport.trim().isNotEmpty) {
      query = query.where('sport', isEqualTo: sport);
    }

    if (liveOnly == true) {
      query = query.where('isLive', isEqualTo: true);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map(SportsMatch.fromFirestore).toList();
    });
  }

  Stream<SportsMatch?> watchMatch(String matchId) {
    return _matches.doc(matchId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }

      return SportsMatch.fromFirestore(snapshot);
    });
  }

  // ---------------------------------------------------------------------------
  // CACHE READS
  // ---------------------------------------------------------------------------

  Future<SportsMatch?> getCachedMatch(String matchId) async {
    final snapshot = await _matches.doc(matchId).get();

    if (!snapshot.exists) {
      return null;
    }

    return SportsMatch.fromFirestore(snapshot);
  }

  Future<List<SportsMatch>> getCachedLiveMatches({String? sport}) async {
    Query<Map<String, dynamic>> query = _matches.where(
      'isLive',
      isEqualTo: true,
    );

    if (sport != null && sport.trim().isNotEmpty) {
      query = query.where('sport', isEqualTo: sport);
    }

    final snapshot = await query.get();

    return snapshot.docs.map(SportsMatch.fromFirestore).toList();
  }

  Future<List<SportsMatch>> getCachedMatches({
    String? sport,
    int limit = 100,
  }) async {
    Query<Map<String, dynamic>> query = _matches;

    if (sport != null && sport.trim().isNotEmpty) {
      query = query.where('sport', isEqualTo: sport);
    }

    query = query.limit(limit);

    final snapshot = await query.get();

    return snapshot.docs.map(SportsMatch.fromFirestore).toList();
  }

  // ---------------------------------------------------------------------------
  // SPORTS ROOM CONNECTION
  // ---------------------------------------------------------------------------

  /// Returns the Room Chat ID associated with a sport.
  String? getSportsRoomId(String sport) {
    return _roomService.getRoomIdForSport(sport);
  }

  /// Ensures the corresponding sports discussion room exists.
  Future<String> prepareSportsRoom(String sport) async {
    return _roomService.prepareSportRoom(sport);
  }

  /// Ensures all 20 sports rooms exist.
  Future<void> prepareAllSportsRooms() async {
    await _roomService.prepareAllSportsRooms();
  }

  // ---------------------------------------------------------------------------
  // MATCH → ROOM
  // ---------------------------------------------------------------------------

  /// Returns the sports discussion room for a match.
  ///
  /// Match-specific rooms are deliberately not created here yet.
  /// The match remains connected to its main sport room.
  String? getMatchDiscussionRoom(SportsMatch match) {
    return _roomService.getRoomIdForSport(match.sport);
  }

  // ---------------------------------------------------------------------------
  // CLEANUP
  // ---------------------------------------------------------------------------

  Future<void> clearCachedMatch(String matchId) async {
    await _matches.doc(matchId).delete();
  }

  Future<void> dispose() async {
    stopAutoSync();
  }
}

/// Result of one complete synchronization cycle.
class SportsSyncResult {
  final int liveMatches;
  final int upcomingMatches;
  final int results;
  final DateTime syncedAt;

  const SportsSyncResult({
    required this.liveMatches,
    required this.upcomingMatches,
    required this.results,
    required this.syncedAt,
  });

  factory SportsSyncResult.empty() {
    return SportsSyncResult(
      liveMatches: 0,
      upcomingMatches: 0,
      results: 0,
      syncedAt: DateTime.now(),
    );
  }

  int get totalMatches {
    return liveMatches + upcomingMatches + results;
  }

  bool get hasData {
    return totalMatches > 0;
  }
}

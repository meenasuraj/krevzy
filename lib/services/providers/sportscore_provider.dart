import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/sports_competition.dart';
import '../../models/sports_event.dart';
import '../../models/sports_match.dart';
import '../../models/sports_player.dart';
import '../../models/sports_standing.dart';
import '../../models/sports_team.dart';
import '../sports_provider.dart';

class SportScoreProvider implements SportsProvider {
  SportScoreProvider({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _baseUrl = 'https://sportscore.com';

  @override
  String get name => 'SportScore';

  @override
  bool get isConfigured => true;

  static const Set<String> supportedSports = <String>{
    'football',
    'basketball',
    'cricket',
    'tennis',
  };

  bool supportsSport(String? sport) {
    if (sport == null || sport.trim().isEmpty) {
      return true;
    }

    return supportedSports.contains(sport.trim().toLowerCase());
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    required Map<String, String> query,
  }) async {
    final uri = Uri.parse('$_baseUrl$path')
        .replace(queryParameters: <String, String>{...query, 'src': 'krevzy'});

    try {
      final response = await _client
          .get(
            uri,
            headers: const <String, String>{'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw SportsProviderException(
          'SportScore returned HTTP ${response.statusCode}.',
        );
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map) {
        throw SportsProviderDataException(
          'SportScore returned an invalid response.',
        );
      }

      return Map<String, dynamic>.from(decoded);
    } on SportsProviderException {
      rethrow;
    } on http.ClientException catch (error) {
      throw SportsProviderException('SportScore network error: $error');
    } on FormatException catch (error) {
      throw SportsProviderDataException('Invalid SportScore JSON: $error');
    } catch (error) {
      throw SportsProviderException('SportScore request failed: $error');
    }
  }

  List<Map<String, dynamic>> _list(dynamic value) {
    if (value is! List) {
      return <Map<String, dynamic>>[];
    }

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  String _string(dynamic value) {
    return value?.toString() ?? '';
  }

  int _int(dynamic value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  DateTime _date(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    final parsed = DateTime.tryParse(value?.toString() ?? '');

    return parsed ?? DateTime.now();
  }

  SportsMatchStatus _status(String value) {
    final normalized = value.trim().toLowerCase();

    if (normalized.contains('live') ||
        normalized.contains('playing') ||
        normalized.contains('in progress')) {
      return SportsMatchStatus.live;
    }

    if (normalized.contains('half')) {
      return SportsMatchStatus.halftime;
    }

    if (normalized.contains('finished') ||
        normalized.contains('ended') ||
        normalized == 'ft') {
      return SportsMatchStatus.finished;
    }

    if (normalized.contains('postpon')) {
      return SportsMatchStatus.postponed;
    }

    if (normalized.contains('cancel')) {
      return SportsMatchStatus.cancelled;
    }

    if (normalized.contains('suspend')) {
      return SportsMatchStatus.suspended;
    }

    if (normalized.contains('abandon')) {
      return SportsMatchStatus.abandoned;
    }

    if (normalized.contains('scheduled') ||
        normalized.contains('upcoming') ||
        normalized.contains('not started')) {
      return SportsMatchStatus.scheduled;
    }

    return SportsMatchStatus.unknown;
  }

  Map<String, dynamic> _teamMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return <String, dynamic>{};
  }

  SportsTeam _teamFromMap(dynamic value, String sport) {
    final data = _teamMap(value);

    return SportsTeam(
      id: _string(data['id'] ?? data['teamId'] ?? data['slug']),
      name: _string(data['name'] ?? data['teamName'] ?? data['strTeam']),
      shortName: _string(
        data['shortName'] ?? data['short_name'] ?? data['name'],
      ),
      logoUrl:
          _nullableString(
            data['logo'] ??
                data['logoUrl'] ??
                data['badge'] ??
                data['teamLogo'],
          ) ??
          '',
      country: _string(data['country']),
      sport: sport,
      venue: _string(data['venue']),
    );
  }

  SportsMatch _matchFromMap(Map<String, dynamic> data, String sport) {
    final homeData = data['homeTeam'] ?? data['home_team'] ?? data['home'];

    final awayData = data['awayTeam'] ?? data['away_team'] ?? data['away'];

    final competition = data['competition'] ?? data['league'];

    final homeScore =
        data['homeScore'] ??
        data['home_score'] ??
        data['scoreHome'] ??
        data['home_score_current'];

    final awayScore =
        data['awayScore'] ??
        data['away_score'] ??
        data['scoreAway'] ??
        data['away_score_current'];

    final statusText = _string(
      data['status'] ?? data['statusText'] ?? data['state'],
    );

    final minute = _int(data['minute'] ?? data['elapsed'] ?? data['time']);

    return SportsMatch(
      id: _string(data['id'] ?? data['matchId'] ?? data['eventId']),
      sport: sport,
      competitionId: _string(
        competition is Map ? competition['id'] : data['competitionId'],
      ),
      competitionName: _string(
        competition is Map ? competition['name'] : competition,
      ),
      season: _string(data['season']),
      homeTeam: _teamFromMap(homeData, sport),
      awayTeam: _teamFromMap(awayData, sport),
      homeScore: _int(homeScore),
      awayScore: _int(awayScore),
      homePeriodScore: 0,
      awayPeriodScore: 0,
      status: _status(statusText),
      statusText: statusText,
      startTime: _date(
        data['startTime'] ??
            data['start_time'] ??
            data['date'] ??
            data['matchDate'],
      ),
      endTime: null,
      venue: _string(data['venue'] ?? data['venueName']),
      country: _string(data['country']),
      minute: minute,
      round: _string(data['round']),
      stage: _string(data['stage']),
      isLive: _isLive(statusText, data),
      updatedAt: DateTime.now(),
      streamUrls: const <String>[],
    );
  }

  bool _isLive(String status, Map<String, dynamic> data) {
    if (data['isLive'] == true || data['is_live'] == true) {
      return true;
    }

    final normalized = status.toLowerCase();

    return normalized.contains('live') ||
        normalized.contains('playing') ||
        normalized.contains('in progress');
  }

  String? _nullableString(dynamic value) {
    final result = value?.toString().trim();

    if (result == null || result.isEmpty) {
      return null;
    }

    return result;
  }

  Future<List<SportsMatch>> _matches(String sport) async {
    if (!supportsSport(sport)) {
      return <SportsMatch>[];
    }

    final response = await _get(
      '/api/widget/matches/',
      query: <String, String>{'sport': sport, 'limit': '50'},
    );

    final rawMatches =
        response['matches'] ?? response['data'] ?? response['events'];

    return _list(rawMatches).map((item) => _matchFromMap(item, sport)).toList();
  }

  @override
  Future<List<SportsMatch>> getLiveMatches({String? sport}) async {
    if (sport != null) {
      final matches = await _matches(sport.toLowerCase());

      return matches.where((match) => match.isLive).toList();
    }

    final result = <SportsMatch>[];

    for (final supportedSport in supportedSports) {
      result.addAll(await _matches(supportedSport));
    }

    return result.where((match) => match.isLive).toList();
  }

  @override
  Future<List<SportsMatch>> getUpcomingMatches({
    String? sport,
    DateTime? from,
    DateTime? to,
  }) async {
    final matches = sport == null
        ? await getLiveMatches()
        : await _matches(sport.toLowerCase());

    return matches.where((match) => match.isUpcoming).toList();
  }

  @override
  Future<List<SportsMatch>> getResults({
    String? sport,
    DateTime? from,
    DateTime? to,
  }) async {
    final matches = sport == null
        ? await getLiveMatches()
        : await _matches(sport.toLowerCase());

    return matches.where((match) => match.isFinished).toList();
  }

  @override
  Future<SportsMatch?> getMatch(String matchId, {String? sport}) async {
    if (sport == null || !supportsSport(sport)) {
      return null;
    }

    final response = await _get(
      '/api/widget/match/',
      query: <String, String>{'sport': sport.toLowerCase(), 'slug': matchId},
    );

    final data = response['match'] ?? response['data'];

    if (data is! Map) {
      return null;
    }

    return _matchFromMap(Map<String, dynamic>.from(data), sport.toLowerCase());
  }

  @override
  Future<List<SportsCompetition>> getCompetitions({String? sport}) async {
    return <SportsCompetition>[];
  }

  @override
  Future<List<SportsTeam>> getTeams({
    String? sport,
    String? competitionId,
  }) async {
    return <SportsTeam>[];
  }

  @override
  Future<List<SportsPlayer>> getPlayers({String? sport, String? teamId}) async {
    return <SportsPlayer>[];
  }

  @override
  Future<List<SportsStanding>> getStandings({
    required String competitionId,
    String? sport,
  }) async {
    return <SportsStanding>[];
  }

  @override
  Future<List<SportsEvent>> getMatchEvents(
    String matchId, {
    String? sport,
  }) async {
    return <SportsEvent>[];
  }

  @override
  Future<void> dispose() async {
    _client.close();
  }
}

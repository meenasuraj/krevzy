import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/sports_competition.dart';
import '../../models/sports_event.dart';
import '../../models/sports_match.dart';
import '../../models/sports_player.dart';
import '../../models/sports_standing.dart';
import '../../models/sports_team.dart';
import '../sports_provider.dart';
import '../sports_config.dart';

class ApiSportsProvider implements SportsProvider {
  ApiSportsProvider({http.Client? client, String? apiKey})
    : _client = client ?? http.Client(),
      _apiKey = (apiKey ?? SportsConfig.apiSportsKey).trim();

  final http.Client _client;
  final String _apiKey;

  @override
  String get name => 'API-Sports';

  @override
  bool get isConfigured => _apiKey.isNotEmpty;

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = Uri.parse(SportsConfig.apiSportsBaseUrl);

    return base.replace(path: '${base.path}$path', queryParameters: query);
  }

  Future<dynamic> _get(String path, {Map<String, String>? query}) async {
    if (!isConfigured) {
      throw SportsProviderNotConfiguredException(
        'API-Sports API key is not configured.',
      );
    }

    try {
      final response = await _client
          .get(
            _uri(path, query),
            headers: <String, String>{
              'x-apisports-key': _apiKey,
              'Accept': 'application/json',
            },
          )
          .timeout(SportsConfig.requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw SportsProviderException(
          'API-Sports returned HTTP ${response.statusCode}.',
        );
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw SportsProviderDataException(
          'API-Sports returned an invalid response.',
        );
      }

      final errors = decoded['errors'];

      if (errors is Map && errors.isNotEmpty) {
        throw SportsProviderException(
          'API-Sports error: ${errors.values.join(', ')}',
        );
      }

      return decoded['response'];
    } on SportsProviderException {
      rethrow;
    } on http.ClientException catch (error) {
      throw SportsProviderException('API-Sports network error: $error');
    } on FormatException catch (error) {
      throw SportsProviderDataException('Invalid API-Sports JSON: $error');
    } catch (error) {
      throw SportsProviderException('API-Sports request failed: $error');
    }
  }

  List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is! List) return <Map<String, dynamic>>[];

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  int? _int(dynamic value) {
    if (value is int) return value;

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '');
  }

  String _string(dynamic value) {
    return value?.toString() ?? '';
  }

  DateTime? _date(dynamic value) {
    if (value is DateTime) return value;

    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  SportsMatchStatus _status(String value) {
    final status = value.toUpperCase();

    switch (status) {
      case 'TBD':
      case 'NS':
        return SportsMatchStatus.scheduled;

      case '1H':
      case '2H':
      case 'ET':
      case 'P':
      case 'LIVE':
        return SportsMatchStatus.live;

      case 'HT':
        return SportsMatchStatus.halftime;

      case 'FT':
      case 'AET':
      case 'PEN':
        return SportsMatchStatus.finished;

      case 'PST':
        return SportsMatchStatus.postponed;

      case 'CANC':
        return SportsMatchStatus.cancelled;

      case 'ABD':
        return SportsMatchStatus.abandoned;

      case 'SUSP':
        return SportsMatchStatus.suspended;

      default:
        return SportsMatchStatus.unknown;
    }
  }

  SportsMatch _matchFromMap(Map<String, dynamic> item) {
    final fixture = Map<String, dynamic>.from(item['fixture'] as Map? ?? {});

    final league = Map<String, dynamic>.from(item['league'] as Map? ?? {});

    final teams = Map<String, dynamic>.from(item['teams'] as Map? ?? {});

    final goals = Map<String, dynamic>.from(item['goals'] as Map? ?? {});

    final home = Map<String, dynamic>.from(teams['home'] as Map? ?? {});

    final away = Map<String, dynamic>.from(teams['away'] as Map? ?? {});

    final status = Map<String, dynamic>.from(fixture['status'] as Map? ?? {});

    final venue = Map<String, dynamic>.from(fixture['venue'] as Map? ?? {});

    final fixtureId = _string(fixture['id']);

    return SportsMatch(
      id: fixtureId,
      sport: 'football',
      competitionId: _string(league['id']),
      competitionName: _string(league['name']),
      season: _string(league['season']),
      homeTeam: SportsTeam(
        id: _string(home['id']),
        name: _string(home['name']),
        shortName: _string(home['name']),
        logoUrl: _string(home['logo']),
        country: '',
        sport: 'football',
        venue: '',
      ),
      awayTeam: SportsTeam(
        id: _string(away['id']),
        name: _string(away['name']),
        shortName: _string(away['name']),
        logoUrl: _string(away['logo']),
        country: '',
        sport: 'football',
        venue: '',
      ),
      homeScore: _int(goals['home']) ?? 0,
      awayScore: _int(goals['away']) ?? 0,
      homePeriodScore: 0,
      awayPeriodScore: 0,
      status: _status(_string(status['short'])),
      statusText: _string(status['long']),
      startTime: _date(fixture['date']),
      endTime: null,
      venue: _string(venue['name']),
      country: _string(league['country']),
      minute:
          _int(
            (status['elapsed'] is Map)
                ? (status['elapsed'] as Map)['elapsed']
                : status['elapsed'],
          ) ??
          0,
      round: _string(league['round']),
      stage: _string(league['round']),
      isLive: <String>[
        '1H',
        '2H',
        'ET',
        'P',
        'LIVE',
      ].contains(_string(status['short']).toUpperCase()),
      updatedAt: DateTime.now(),
      streamUrls: const <String>[],
    );
  }

  @override
  Future<List<SportsMatch>> getLiveMatches({String? sport}) async {
    if (sport != null &&
        sport.trim().isNotEmpty &&
        sport.toLowerCase() != 'football') {
      return <SportsMatch>[];
    }

    final response = await _get(
      '/fixtures',
      query: <String, String>{'live': 'all'},
    );

    return _mapList(response)
        .map(_matchFromMap)
        .where((match) => match.isLive)
        .toList();
  }

  @override
  Future<List<SportsMatch>> getUpcomingMatches({
    String? sport,
    DateTime? from,
    DateTime? to,
  }) async {
    if (sport != null &&
        sport.trim().isNotEmpty &&
        sport.toLowerCase() != 'football') {
      return <SportsMatch>[];
    }

    final DateTime start = from ?? DateTime.now();

    final DateTime end = to ?? start.add(const Duration(days: 7));

    final response = await _get(
      '/fixtures',
      query: <String, String>{
        'from': _dateString(start),
        'to': _dateString(end),
      },
    );

    return _mapList(response)
        .map(_matchFromMap)
        .where((match) => match.isUpcoming)
        .toList();
  }

  @override
  Future<List<SportsMatch>> getResults({
    String? sport,
    DateTime? from,
    DateTime? to,
  }) async {
    if (sport != null &&
        sport.trim().isNotEmpty &&
        sport.toLowerCase() != 'football') {
      return <SportsMatch>[];
    }

    final DateTime start =
        from ?? DateTime.now().subtract(const Duration(days: 7));

    final DateTime end = to ?? DateTime.now();

    final response = await _get(
      '/fixtures',
      query: <String, String>{
        'from': _dateString(start),
        'to': _dateString(end),
      },
    );

    return _mapList(response)
        .map(_matchFromMap)
        .where((match) => match.isFinished)
        .toList();
  }

  @override
  Future<SportsMatch?> getMatch(String matchId, {String? sport}) async {
    if (sport != null &&
        sport.trim().isNotEmpty &&
        sport.toLowerCase() != 'football') {
      return null;
    }

    final response = await _get(
      '/fixtures',
      query: <String, String>{'id': matchId},
    );

    final list = _mapList(response);

    if (list.isEmpty) return null;

    return _matchFromMap(list.first);
  }

  @override
  Future<List<SportsCompetition>> getCompetitions({String? sport}) async {
    if (sport != null &&
        sport.trim().isNotEmpty &&
        sport.toLowerCase() != 'football') {
      return <SportsCompetition>[];
    }

    final response = await _get('/leagues');

    return _mapList(response).map((item) {
      final league = Map<String, dynamic>.from(item['league'] as Map? ?? {});

      final country = Map<String, dynamic>.from(item['country'] as Map? ?? {});

      final seasons = item['seasons'];

      String season = '';

      if (seasons is List && seasons.isNotEmpty) {
        final latest = seasons.last;

        if (latest is Map) {
          season = _string(latest['year']);
        }
      }

      return SportsCompetition(
        id: _string(league['id']),
        name: _string(league['name']),
        shortName: _string(league['name']),
        sport: 'football',
        country: _string(country['name']),
        logoUrl: _string(league['logo']).isEmpty ? '' : _string(league['logo']),
        season: season,
        type: _string(league['type']),
      );
    }).toList();
  }

  @override
  Future<List<SportsTeam>> getTeams({
    String? sport,
    String? competitionId,
  }) async {
    if (sport != null &&
        sport.trim().isNotEmpty &&
        sport.toLowerCase() != 'football') {
      return <SportsTeam>[];
    }

    if (competitionId == null || competitionId.trim().isEmpty) {
      return <SportsTeam>[];
    }

    final response = await _get(
      '/teams',
      query: <String, String>{
        'league': competitionId,
        'season': DateTime.now().year.toString(),
      },
    );

    return _mapList(response).map((item) {
      final team = Map<String, dynamic>.from(item['team'] as Map? ?? {});

      final venue = Map<String, dynamic>.from(item['venue'] as Map? ?? {});

      final country = Map<String, dynamic>.from(
        team['country'] is Map ? team['country'] : <String, dynamic>{},
      );

      return SportsTeam(
        id: _string(team['id']),
        name: _string(team['name']),
        shortName: _string(team['name']),
        logoUrl: _string(team['logo']),
        country: _string(country['name']),
        sport: 'football',
        venue: _string(venue['name']),
      );
    }).toList();
  }

  @override
  Future<List<SportsPlayer>> getPlayers({String? sport, String? teamId}) async {
    if (sport != null &&
        sport.trim().isNotEmpty &&
        sport.toLowerCase() != 'football') {
      return <SportsPlayer>[];
    }

    if (teamId == null || teamId.trim().isEmpty) {
      return <SportsPlayer>[];
    }

    final response = await _get(
      '/players',
      query: <String, String>{
        'team': teamId,
        'season': DateTime.now().year.toString(),
      },
    );

    return _mapList(response).map((item) {
      final player = Map<String, dynamic>.from(item['player'] as Map? ?? {});

      final nationality = _string(player['nationality']);

      return SportsPlayer(
        id: _string(player['id']),
        name: _string(player['name']),
        shortName: _string(player['firstname']),
        photoUrl: _string(player['photo']),
        country: nationality,
        sport: 'football',
        teamId: teamId,
        position: '',
        jerseyNumber: null,
      );
    }).toList();
  }

  @override
  Future<List<SportsStanding>> getStandings({
    required String competitionId,
    String? sport,
  }) async {
    if (sport != null &&
        sport.trim().isNotEmpty &&
        sport.toLowerCase() != 'football') {
      return <SportsStanding>[];
    }

    final response = await _get(
      '/standings',
      query: <String, String>{
        'league': competitionId,
        'season': DateTime.now().year.toString(),
      },
    );

    final output = <SportsStanding>[];

    for (final item in _mapList(response)) {
      final league = Map<String, dynamic>.from(item['league'] as Map? ?? {});

      final standings = league['standings'];

      if (standings is! List) continue;

      for (final group in standings) {
        if (group is! List) continue;

        for (final row in group) {
          if (row is! Map) continue;

          final data = Map<String, dynamic>.from(row);

          final team = Map<String, dynamic>.from(data['team'] as Map? ?? {});

          final all = Map<String, dynamic>.from(data['all'] as Map? ?? {});

          output.add(
            SportsStanding(
              id: '${competitionId}_${_string(team['id'])}',
              competitionId: competitionId,
              sport: 'football',
              teamId: _string(team['id']),
              teamName: _string(team['name']),
              teamLogoUrl: _string(team['logo']),
              position: _int(data['rank']) ?? 0,
              played: _int(all['played']) ?? 0,
              won: _int(all['win']) ?? 0,
              drawn: _int(all['draw']) ?? 0,
              lost: _int(all['lose']) ?? 0,
              points: _int(data['points']) ?? 0,
              goalsFor:
                  _int(
                    (all['goals'] is Map) ? (all['goals'] as Map)['for'] : null,
                  ) ??
                  0,
              goalsAgainst:
                  _int(
                    (all['goals'] is Map)
                        ? (all['goals'] as Map)['against']
                        : null,
                  ) ??
                  0,
              goalDifference: _int(data['goalsDiff']) ?? 0,
              wins: _int(all['win']) ?? 0,
              losses: _int(all['lose']) ?? 0,
            ),
          );
        }
      }
    }

    return output;
  }

  @override
  Future<List<SportsEvent>> getMatchEvents(
    String matchId, {
    String? sport,
  }) async {
    if (sport != null &&
        sport.trim().isNotEmpty &&
        sport.toLowerCase() != 'football') {
      return <SportsEvent>[];
    }

    final response = await _get(
      '/fixtures/events',
      query: <String, String>{'fixture': matchId},
    );

    return _mapList(response).map((item) {
      final time = Map<String, dynamic>.from(item['time'] as Map? ?? {});

      final team = Map<String, dynamic>.from(item['team'] as Map? ?? {});

      final player = Map<String, dynamic>.from(item['player'] as Map? ?? {});

      final type = _string(item['type']);
      final detail = _string(item['detail']);

      return SportsEvent(
        id: '${matchId}_${_string(time['elapsed'])}_${_string(player['id'])}_$type',
        matchId: matchId,
        sport: 'football',
        type: type,
        title: detail,
        description: detail,
        teamId: _string(team['id']),
        playerId: _string(player['id']),
        playerName: _string(player['name']),
        minute: _string(time['elapsed']),
        createdAt: DateTime.now(),
      );
    }).toList();
  }

  String _dateString(DateTime date) {
    final value = date.toUtc();

    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  @override
  Future<void> dispose() async {
    _client.close();
  }
}

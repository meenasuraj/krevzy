import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/sports_competition.dart';
import '../models/sports_event.dart';
import '../models/sports_match.dart';
import '../models/sports_player.dart';
import '../models/sports_standing.dart';
import '../models/sports_team.dart';
import 'sports_provider.dart';
// import 'providers/api_sports_provider.dart';
// import 'providers/sportscore_provider.dart';

/// Central sports service used by Krevzy.
///
/// Responsibilities:
/// - provider management
/// - request timeout handling
/// - small in-memory cache
/// - live-score polling
/// - common error handling
/// - provider-independent API for the rest of the app
///
/// Screens should use this class rather than calling an external sports API
/// directly.
class SportsService {
  SportsService._internal({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  static final SportsService instance = SportsService._internal();

  SportsProvider? _provider;
  final http.Client _httpClient;

  Duration requestTimeout = const Duration(seconds: 20);

  Duration liveRefreshInterval = const Duration(seconds: 30);

  final Map<String, _SportsCacheEntry<dynamic>> _cache =
      <String, _SportsCacheEntry<dynamic>>{};

  Timer? _liveTimer;
  StreamController<List<SportsMatch>>? _liveController;

  /// Current provider.
  SportsProvider? get provider => _provider;

  /// Whether a provider is configured.
  bool get isConfigured => _provider != null && _provider!.isConfigured;

  /// Configure the provider.
  ///
  /// This can be called during app startup.
  void configureProvider(SportsProvider provider) {
    _provider = provider;
    clearCache();
  }

  /// Replace the current provider.
  void setProvider(SportsProvider provider) {
    configureProvider(provider);
  }

  /// Remove the current provider.
  void clearProvider() {
    stopLiveUpdates();
    _provider = null;
    clearCache();
  }

  // ---------------------------------------------------------------------------
  // LIVE MATCHES
  // ---------------------------------------------------------------------------

  Future<List<SportsMatch>> getLiveMatches({
    String? sport,
    bool forceRefresh = false,
  }) async {
    final provider = _requireProvider();

    final cacheKey = _cacheKey('live', sport: sport);

    if (!forceRefresh) {
      final cached = _getCached<List<SportsMatch>>(cacheKey);

      if (cached != null) {
        return cached;
      }
    }

    final matches = await _run(
      () => provider.getLiveMatches(sport: _clean(sport)),
    );

    final normalized = _normalizeMatches(matches);

    _saveCache(cacheKey, normalized);

    return normalized;
  }

  // ---------------------------------------------------------------------------
  // UPCOMING
  // ---------------------------------------------------------------------------

  Future<List<SportsMatch>> getUpcomingMatches({
    String? sport,
    DateTime? from,
    DateTime? to,
    bool forceRefresh = false,
  }) async {
    final provider = _requireProvider();

    final cacheKey = _cacheKey('upcoming', sport: sport, from: from, to: to);

    if (!forceRefresh) {
      final cached = _getCached<List<SportsMatch>>(cacheKey);

      if (cached != null) {
        return cached;
      }
    }

    final matches = await _run(
      () =>
          provider.getUpcomingMatches(sport: _clean(sport), from: from, to: to),
    );

    final normalized = _normalizeMatches(matches);

    _saveCache(cacheKey, normalized);

    return normalized;
  }

  // ---------------------------------------------------------------------------
  // RESULTS
  // ---------------------------------------------------------------------------

  Future<List<SportsMatch>> getResults({
    String? sport,
    DateTime? from,
    DateTime? to,
    bool forceRefresh = false,
  }) async {
    final provider = _requireProvider();

    final cacheKey = _cacheKey('results', sport: sport, from: from, to: to);

    if (!forceRefresh) {
      final cached = _getCached<List<SportsMatch>>(cacheKey);

      if (cached != null) {
        return cached;
      }
    }

    final matches = await _run(
      () => provider.getResults(sport: _clean(sport), from: from, to: to),
    );

    final normalized = _normalizeMatches(matches);

    _saveCache(cacheKey, normalized);

    return normalized;
  }

  // ---------------------------------------------------------------------------
  // SINGLE MATCH
  // ---------------------------------------------------------------------------

  Future<SportsMatch?> getMatch(
    String matchId, {
    String? sport,
    bool forceRefresh = false,
  }) async {
    final provider = _requireProvider();

    final id = matchId.trim();

    if (id.isEmpty) {
      throw const SportsProviderDataException('Match ID cannot be empty.');
    }

    final cacheKey = _cacheKey('match:$id', sport: sport);

    if (!forceRefresh) {
      final cached = _getCached<SportsMatch?>(cacheKey);

      if (cached != null) {
        return cached;
      }
    }

    final match = await _run(() => provider.getMatch(id, sport: _clean(sport)));

    if (match != null) {
      final normalized = _normalizeMatch(match);

      _saveCache(cacheKey, normalized);

      return normalized;
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // COMPETITIONS
  // ---------------------------------------------------------------------------

  Future<List<SportsCompetition>> getCompetitions({
    String? sport,
    bool forceRefresh = false,
  }) async {
    final provider = _requireProvider();

    final cacheKey = _cacheKey('competitions', sport: sport);

    if (!forceRefresh) {
      final cached = _getCached<List<SportsCompetition>>(cacheKey);

      if (cached != null) {
        return cached;
      }
    }

    final competitions = await _run(
      () => provider.getCompetitions(sport: _clean(sport)),
    );

    final normalized = _normalizeCompetitions(competitions);

    _saveCache(cacheKey, normalized);

    return normalized;
  }

  // ---------------------------------------------------------------------------
  // TEAMS
  // ---------------------------------------------------------------------------

  Future<List<SportsTeam>> getTeams({
    String? sport,
    String? competitionId,
    bool forceRefresh = false,
  }) async {
    final provider = _requireProvider();

    final cacheKey = _cacheKey('teams', sport: sport, extra: competitionId);

    if (!forceRefresh) {
      final cached = _getCached<List<SportsTeam>>(cacheKey);

      if (cached != null) {
        return cached;
      }
    }

    final teams = await _run(
      () => provider.getTeams(
        sport: _clean(sport),
        competitionId: _clean(competitionId),
      ),
    );

    final normalized = _normalizeTeams(teams);

    _saveCache(cacheKey, normalized);

    return normalized;
  }

  // ---------------------------------------------------------------------------
  // PLAYERS
  // ---------------------------------------------------------------------------

  Future<List<SportsPlayer>> getPlayers({
    String? sport,
    String? teamId,
    bool forceRefresh = false,
  }) async {
    final provider = _requireProvider();

    final cacheKey = _cacheKey('players', sport: sport, extra: teamId);

    if (!forceRefresh) {
      final cached = _getCached<List<SportsPlayer>>(cacheKey);

      if (cached != null) {
        return cached;
      }
    }

    final players = await _run(
      () => provider.getPlayers(sport: _clean(sport), teamId: _clean(teamId)),
    );

    final normalized = _normalizePlayers(players);

    _saveCache(cacheKey, normalized);

    return normalized;
  }

  // ---------------------------------------------------------------------------
  // STANDINGS
  // ---------------------------------------------------------------------------

  Future<List<SportsStanding>> getStandings({
    required String competitionId,
    String? sport,
    bool forceRefresh = false,
  }) async {
    final provider = _requireProvider();

    final id = competitionId.trim();

    if (id.isEmpty) {
      throw const SportsProviderDataException(
        'Competition ID cannot be empty.',
      );
    }

    final cacheKey = _cacheKey('standings:$id', sport: sport);

    if (!forceRefresh) {
      final cached = _getCached<List<SportsStanding>>(cacheKey);

      if (cached != null) {
        return cached;
      }
    }

    final standings = await _run(
      () => provider.getStandings(competitionId: id, sport: _clean(sport)),
    );

    final normalized = _normalizeStandings(standings);

    _saveCache(cacheKey, normalized);

    return normalized;
  }

  // ---------------------------------------------------------------------------
  // MATCH EVENTS
  // ---------------------------------------------------------------------------

  Future<List<SportsEvent>> getMatchEvents(
    String matchId, {
    String? sport,
    bool forceRefresh = false,
  }) async {
    final provider = _requireProvider();

    final id = matchId.trim();

    if (id.isEmpty) {
      throw const SportsProviderDataException('Match ID cannot be empty.');
    }

    final cacheKey = _cacheKey('events:$id', sport: sport);

    if (!forceRefresh) {
      final cached = _getCached<List<SportsEvent>>(cacheKey);

      if (cached != null) {
        return cached;
      }
    }

    final events = await _run(
      () => provider.getMatchEvents(id, sport: _clean(sport)),
    );

    final normalized = _normalizeEvents(events);

    _saveCache(cacheKey, normalized);

    return normalized;
  }

  // ---------------------------------------------------------------------------
  // LIVE STREAM
  // ---------------------------------------------------------------------------

  /// Poll live matches and expose them as a stream.
  ///
  /// The stream automatically refreshes according to
  /// [liveRefreshInterval].
  Stream<List<SportsMatch>> watchLiveMatches({
    String? sport,
    bool emitCachedValue = true,
  }) {
    _liveController ??= StreamController<List<SportsMatch>>.broadcast(
      onCancel: () {
        if (_liveController != null && !_liveController!.hasListener) {
          stopLiveUpdates();
        }
      },
    );

    final controller = _liveController!;

    if (emitCachedValue) {
      unawaited(
        getLiveMatches(sport: sport, forceRefresh: false)
            .then((matches) {
              if (!controller.isClosed) {
                controller.add(matches);
              }
            })
            .catchError((Object error) {
              if (!controller.isClosed) {
                controller.addError(error);
              }
            }),
      );
    }

    _startLiveUpdates(sport);

    return controller.stream;
  }

  void _startLiveUpdates(String? sport) {
    _liveTimer?.cancel();

    _liveTimer = Timer.periodic(liveRefreshInterval, (_) async {
      try {
        final matches = await getLiveMatches(sport: sport, forceRefresh: true);

        if (_liveController != null && !_liveController!.isClosed) {
          _liveController!.add(matches);
        }
      } catch (error, stackTrace) {
        if (_liveController != null && !_liveController!.isClosed) {
          _liveController!.addError(error, stackTrace);
        }
      }
    });
  }

  void stopLiveUpdates() {
    _liveTimer?.cancel();
    _liveTimer = null;
  }

  // ---------------------------------------------------------------------------
  // CACHE
  // ---------------------------------------------------------------------------

  void clearCache() {
    _cache.clear();
  }

  void clearCacheForSport(String sport) {
    final target = sport.trim().toLowerCase();

    if (target.isEmpty) return;

    _cache.removeWhere((key, value) => key.contains('sport=$target'));
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  SportsProvider _requireProvider() {
    final provider = _provider;

    if (provider == null) {
      throw const SportsProviderNotConfiguredException();
    }

    if (!provider.isConfigured) {
      throw const SportsProviderNotConfiguredException();
    }

    return provider;
  }

  Future<T> _run<T>(Future<T> Function() operation) async {
    try {
      return await operation().timeout(
        requestTimeout,
        onTimeout: () {
          throw const SportsProviderTimeoutException();
        },
      );
    } on SportsProviderException {
      rethrow;
    } catch (error) {
      throw SportsProviderException(
        error.toString(),
        code: 'request_failed',
        cause: error,
      );
    }
  }

  void _saveCache<T>(String key, T value) {
    _cache[key] = _SportsCacheEntry<T>(value, DateTime.now());
  }

  T? _getCached<T>(String key) {
    final entry = _cache[key];

    if (entry == null) {
      return null;
    }

    // Five-minute general cache lifetime.
    final age = DateTime.now().difference(entry.createdAt);

    if (age > const Duration(minutes: 5)) {
      _cache.remove(key);
      return null;
    }

    final value = entry.value;

    if (value is T) {
      return value;
    }

    return null;
  }

  String _cacheKey(
    String type, {
    String? sport,
    DateTime? from,
    DateTime? to,
    String? extra,
  }) {
    final parts = <String>[type];

    final normalizedSport = _clean(sport);

    if (normalizedSport != null) {
      parts.add('sport=$normalizedSport');
    }

    if (from != null) {
      parts.add('from=${from.toUtc().toIso8601String()}');
    }

    if (to != null) {
      parts.add('to=${to.toUtc().toIso8601String()}');
    }

    final normalizedExtra = _clean(extra);

    if (normalizedExtra != null) {
      parts.add('extra=$normalizedExtra');
    }

    return parts.join('|');
  }

  String? _clean(String? value) {
    if (value == null) return null;

    final result = value.trim();

    if (result.isEmpty) {
      return null;
    }

    return result.toLowerCase();
  }

  // ---------------------------------------------------------------------------
  // NORMALIZATION
  // ---------------------------------------------------------------------------

  List<SportsMatch> _normalizeMatches(List<SportsMatch> matches) {
    final result = matches
        .map(_normalizeMatch)
        .where((match) => match.id.trim().isNotEmpty)
        .toList();

    result.sort((a, b) {
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

    return List.unmodifiable(result);
  }

  SportsMatch _normalizeMatch(SportsMatch match) {
    final home = match.homeTeam.copyWith(
      sport: match.homeTeam.sport.isEmpty ? match.sport : match.homeTeam.sport,
    );

    final away = match.awayTeam.copyWith(
      sport: match.awayTeam.sport.isEmpty ? match.sport : match.awayTeam.sport,
    );

    final shouldBeLive =
        match.status == SportsMatchStatus.live ||
        match.status == SportsMatchStatus.halftime;

    return match.copyWith(
      homeTeam: home,
      awayTeam: away,
      isLive: match.isLive || shouldBeLive,
      updatedAt: match.updatedAt ?? DateTime.now(),
    );
  }

  List<SportsCompetition> _normalizeCompetitions(
    List<SportsCompetition> competitions,
  ) {
    final result = competitions
        .where((item) => item.id.trim().isNotEmpty)
        .map((item) => item.copyWith(name: item.name.trim()))
        .toList();

    result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return List.unmodifiable(result);
  }

  List<SportsTeam> _normalizeTeams(List<SportsTeam> teams) {
    final result = teams
        .where((item) => item.id.trim().isNotEmpty)
        .map((item) => item.copyWith(name: item.name.trim()))
        .toList();

    result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return List.unmodifiable(result);
  }

  List<SportsPlayer> _normalizePlayers(List<SportsPlayer> players) {
    final result = players
        .where((item) => item.id.trim().isNotEmpty)
        .map((item) => item.copyWith(name: item.name.trim()))
        .toList();

    result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return List.unmodifiable(result);
  }

  List<SportsStanding> _normalizeStandings(List<SportsStanding> standings) {
    final result = standings
        .where((item) => item.teamId.trim().isNotEmpty)
        .toList();

    result.sort((a, b) {
      if (a.position == 0 && b.position == 0) {
        return a.teamName.toLowerCase().compareTo(b.teamName.toLowerCase());
      }

      if (a.position == 0) {
        return 1;
      }

      if (b.position == 0) {
        return -1;
      }

      return a.position.compareTo(b.position);
    });

    return List.unmodifiable(result);
  }

  List<SportsEvent> _normalizeEvents(List<SportsEvent> events) {
    final result = events.where((item) => item.id.trim().isNotEmpty).toList();

    result.sort((a, b) {
      final aTime = a.createdAt;
      final bTime = b.createdAt;

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

    return List.unmodifiable(result);
  }

  // ---------------------------------------------------------------------------
  // HTTP HELPERS
  //
  // These are intentionally generic. A concrete provider can use the same
  // SportsService HTTP client architecture if desired.
  // ---------------------------------------------------------------------------

  Future<dynamic> getJson(Uri uri, {Map<String, String>? headers}) async {
    try {
      final response = await _httpClient
          .get(uri, headers: headers)
          .timeout(requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw SportsProviderException(
          'Sports API returned HTTP ${response.statusCode}.',
          code: 'http_${response.statusCode}',
        );
      }

      if (response.body.trim().isEmpty) {
        throw const SportsProviderDataException(
          'Sports API returned an empty response.',
        );
      }

      try {
        return jsonDecode(response.body);
      } catch (_) {
        throw const SportsProviderDataException(
          'Sports API returned invalid JSON.',
        );
      }
    } on TimeoutException {
      throw const SportsProviderTimeoutException();
    } on SportsProviderException {
      rethrow;
    } catch (error) {
      throw SportsProviderException(
        'Unable to contact sports API.',
        code: 'network_error',
        cause: error,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // DISPOSE
  // ---------------------------------------------------------------------------

  Future<void> dispose() async {
    stopLiveUpdates();

    final provider = _provider;

    if (provider != null) {
      await provider.dispose();
    }

    _provider = null;

    if (_liveController != null && !_liveController!.isClosed) {
      await _liveController!.close();
    }

    _liveController = null;

    _httpClient.close();

    _cache.clear();
  }
}

/// Internal cache record.
class _SportsCacheEntry<T> {
  final T value;
  final DateTime createdAt;

  const _SportsCacheEntry(this.value, this.createdAt);
}

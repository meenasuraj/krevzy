import '../models/sports_competition.dart';
import '../models/sports_event.dart';
import '../models/sports_match.dart';
import '../models/sports_player.dart';
import '../models/sports_standing.dart';
import '../models/sports_team.dart';

/// Common interface for any sports-data provider.
///
/// The rest of Krevzy should communicate with [SportsProvider] instead of
/// depending directly on a particular sports API.
///
/// This makes it possible to change providers later without rewriting the
/// sports screens, Firestore layer, or room-chat integration.
abstract class SportsProvider {
  /// Human-readable provider name.
  String get name;

  /// Whether this provider is currently configured.
  bool get isConfigured;

  /// Fetch live matches.
  Future<List<SportsMatch>> getLiveMatches({String? sport});

  /// Fetch upcoming/scheduled matches.
  Future<List<SportsMatch>> getUpcomingMatches({
    String? sport,
    DateTime? from,
    DateTime? to,
  });

  /// Fetch completed matches/results.
  Future<List<SportsMatch>> getResults({
    String? sport,
    DateTime? from,
    DateTime? to,
  });

  /// Fetch a single match.
  Future<SportsMatch?> getMatch(String matchId, {String? sport});

  /// Fetch competitions/leagues.
  Future<List<SportsCompetition>> getCompetitions({String? sport});

  /// Fetch teams.
  Future<List<SportsTeam>> getTeams({String? sport, String? competitionId});

  /// Fetch players.
  Future<List<SportsPlayer>> getPlayers({String? sport, String? teamId});

  /// Fetch standings/table.
  Future<List<SportsStanding>> getStandings({
    required String competitionId,
    String? sport,
  });

  /// Fetch match events.
  Future<List<SportsEvent>> getMatchEvents(String matchId, {String? sport});

  /// Release resources such as HTTP clients.
  Future<void> dispose() async {}
}

/// Provider exception used by the sports layer.
///
/// UI code should not need to understand HTTP/API-specific exceptions.
class SportsProviderException implements Exception {
  final String message;
  final String? code;
  final Object? cause;

  const SportsProviderException(this.message, {this.code, this.cause});

  @override
  String toString() {
    if (code == null || code!.trim().isEmpty) {
      return 'SportsProviderException: $message';
    }

    return 'SportsProviderException($code): $message';
  }
}

/// Thrown when the provider is not configured.
class SportsProviderNotConfiguredException extends SportsProviderException {
  // The explicit super call is required to preserve the error code.
  // ignore: use_super_parameters
  const SportsProviderNotConfiguredException([
    String message = 'Sports data provider is not configured.',
  ]) : super(message, code: 'provider_not_configured');
}

/// Thrown when an API request exceeds its timeout.
class SportsProviderTimeoutException extends SportsProviderException {
  const SportsProviderTimeoutException([
    super.message = 'Sports data request timed out.',
  ]) : super(code: 'timeout');
}

/// Thrown when a provider returns invalid/unusable data.
class SportsProviderDataException extends SportsProviderException {
  const SportsProviderDataException([
    super.message = 'Sports provider returned invalid data.',
  ]) : super(code: 'invalid_data');
}

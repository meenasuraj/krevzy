import 'package:cloud_firestore/cloud_firestore.dart';

import 'sports_team.dart';

enum SportsMatchStatus {
  scheduled,
  live,
  halftime,
  finished,
  postponed,
  cancelled,
  abandoned,
  suspended,
  unknown,
}

class SportsMatch {
  final String id;
  final String sport;

  final String competitionId;
  final String competitionName;

  final String season;

  final SportsTeam homeTeam;
  final SportsTeam awayTeam;

  final int homeScore;
  final int awayScore;

  final int homePeriodScore;
  final int awayPeriodScore;

  final SportsMatchStatus status;
  final String statusText;

  final DateTime? startTime;
  final DateTime? endTime;

  final String venue;
  final String country;

  final int? minute;

  final String round;
  final String stage;

  final bool isLive;

  final DateTime? updatedAt;

  final List<String> streamUrls;

  const SportsMatch({
    required this.id,
    required this.sport,
    required this.competitionId,
    required this.competitionName,
    required this.season,
    required this.homeTeam,
    required this.awayTeam,
    this.homeScore = 0,
    this.awayScore = 0,
    this.homePeriodScore = 0,
    this.awayPeriodScore = 0,
    this.status = SportsMatchStatus.unknown,
    this.statusText = '',
    this.startTime,
    this.endTime,
    this.venue = '',
    this.country = '',
    this.minute,
    this.round = '',
    this.stage = '',
    this.isLive = false,
    this.updatedAt,
    this.streamUrls = const [],
  });

  factory SportsMatch.fromMap(Map<String, dynamic> map) {
    final homeMap = _map(map['homeTeam'] ?? map['home'] ?? map['home_team']);

    final awayMap = _map(map['awayTeam'] ?? map['away'] ?? map['away_team']);

    final homeTeam = SportsTeam.fromMap({
      ...homeMap,
      'id': homeMap['id'] ?? homeMap['teamId'] ?? map['homeTeamId'],
      'name': homeMap['name'] ?? homeMap['teamName'] ?? map['homeTeamName'],
      'logoUrl': homeMap['logoUrl'] ?? homeMap['logo'] ?? map['homeTeamLogo'],
    });

    final awayTeam = SportsTeam.fromMap({
      ...awayMap,
      'id': awayMap['id'] ?? awayMap['teamId'] ?? map['awayTeamId'],
      'name': awayMap['name'] ?? awayMap['teamName'] ?? map['awayTeamName'],
      'logoUrl': awayMap['logoUrl'] ?? awayMap['logo'] ?? map['awayTeamLogo'],
    });

    final status = _parseStatus(
      map['status'] ?? map['matchStatus'] ?? map['state'],
    );

    final isLiveValue = map['isLive'];

    return SportsMatch(
      id: _string(map['id'] ?? map['matchId'] ?? map['eventId']),
      sport: _string(map['sport']),
      competitionId: _string(map['competitionId'] ?? map['leagueId']),
      competitionName: _string(
        map['competitionName'] ?? map['leagueName'] ?? map['competition'],
      ),
      season: _string(map['season']),
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      homeScore: _int(
        map['homeScore'] ?? map['home_score'] ?? homeMap['score'],
      ),
      awayScore: _int(
        map['awayScore'] ?? map['away_score'] ?? awayMap['score'],
      ),
      homePeriodScore: _int(map['homePeriodScore'] ?? map['home_period_score']),
      awayPeriodScore: _int(map['awayPeriodScore'] ?? map['away_period_score']),
      status: status,
      statusText: _string(
        map['statusText'] ?? map['status_text'] ?? map['status'],
      ),
      startTime: _dateTime(
        map['startTime'] ?? map['start_time'] ?? map['date'],
      ),
      endTime: _dateTime(map['endTime'] ?? map['end_time']),
      venue: _string(map['venue'] ?? map['stadium']),
      country: _string(map['country'] ?? map['countryName']),
      minute: _nullableInt(map['minute'] ?? map['elapsed']),
      round: _string(map['round']),
      stage: _string(map['stage']),
      isLive: isLiveValue is bool
          ? isLiveValue
          : status == SportsMatchStatus.live ||
                status == SportsMatchStatus.halftime,
      updatedAt: _dateTime(map['updatedAt']),
      streamUrls: _stringList(map['streamUrls'] ?? map['streams']),
    );
  }

  factory SportsMatch.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};

    return SportsMatch.fromMap({...data, 'id': document.id});
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sport': sport,
      'competitionId': competitionId,
      'competitionName': competitionName,
      'season': season,
      'homeTeam': homeTeam.toMap(),
      'awayTeam': awayTeam.toMap(),
      'homeScore': homeScore,
      'awayScore': awayScore,
      'homePeriodScore': homePeriodScore,
      'awayPeriodScore': awayPeriodScore,
      'status': status.name,
      'statusText': statusText,
      'startTime': startTime == null ? null : Timestamp.fromDate(startTime!),
      'endTime': endTime == null ? null : Timestamp.fromDate(endTime!),
      'venue': venue,
      'country': country,
      'minute': minute,
      'round': round,
      'stage': stage,
      'isLive': isLive,
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
      'streamUrls': streamUrls,
    };
  }

  SportsMatch copyWith({
    String? id,
    String? sport,
    String? competitionId,
    String? competitionName,
    String? season,
    SportsTeam? homeTeam,
    SportsTeam? awayTeam,
    int? homeScore,
    int? awayScore,
    int? homePeriodScore,
    int? awayPeriodScore,
    SportsMatchStatus? status,
    String? statusText,
    DateTime? startTime,
    DateTime? endTime,
    String? venue,
    String? country,
    int? minute,
    String? round,
    String? stage,
    bool? isLive,
    DateTime? updatedAt,
    List<String>? streamUrls,
  }) {
    return SportsMatch(
      id: id ?? this.id,
      sport: sport ?? this.sport,
      competitionId: competitionId ?? this.competitionId,
      competitionName: competitionName ?? this.competitionName,
      season: season ?? this.season,
      homeTeam: homeTeam ?? this.homeTeam,
      awayTeam: awayTeam ?? this.awayTeam,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      homePeriodScore: homePeriodScore ?? this.homePeriodScore,
      awayPeriodScore: awayPeriodScore ?? this.awayPeriodScore,
      status: status ?? this.status,
      statusText: statusText ?? this.statusText,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      venue: venue ?? this.venue,
      country: country ?? this.country,
      minute: minute ?? this.minute,
      round: round ?? this.round,
      stage: stage ?? this.stage,
      isLive: isLive ?? this.isLive,
      updatedAt: updatedAt ?? this.updatedAt,
      streamUrls: streamUrls ?? this.streamUrls,
    );
  }

  bool get hasStarted {
    return isLive ||
        status == SportsMatchStatus.halftime ||
        status == SportsMatchStatus.finished ||
        status == SportsMatchStatus.suspended ||
        status == SportsMatchStatus.abandoned;
  }

  bool get isFinished {
    return status == SportsMatchStatus.finished ||
        status == SportsMatchStatus.cancelled ||
        status == SportsMatchStatus.abandoned;
  }

  bool get isUpcoming {
    return status == SportsMatchStatus.scheduled;
  }

  String get displayScore {
    return '$homeScore - $awayScore';
  }

  String get displayStatus {
    if (statusText.trim().isNotEmpty) {
      return statusText;
    }

    switch (status) {
      case SportsMatchStatus.scheduled:
        return 'Upcoming';

      case SportsMatchStatus.live:
        return minute == null ? 'LIVE' : 'LIVE ${minute!}\'';

      case SportsMatchStatus.halftime:
        return 'Half Time';

      case SportsMatchStatus.finished:
        return 'Finished';

      case SportsMatchStatus.postponed:
        return 'Postponed';

      case SportsMatchStatus.cancelled:
        return 'Cancelled';

      case SportsMatchStatus.abandoned:
        return 'Abandoned';

      case SportsMatchStatus.suspended:
        return 'Suspended';

      case SportsMatchStatus.unknown:
        return 'Unknown';
    }
  }

  static SportsMatchStatus _parseStatus(dynamic value) {
    final text = value?.toString().toLowerCase().trim() ?? '';

    if (text.isEmpty) {
      return SportsMatchStatus.unknown;
    }

    if (text.contains('live') ||
        text.contains('inplay') ||
        text.contains('in-play')) {
      return SportsMatchStatus.live;
    }

    if (text.contains('half')) {
      return SportsMatchStatus.halftime;
    }

    if (text.contains('finish') || text.contains('completed') || text == 'ft') {
      return SportsMatchStatus.finished;
    }

    if (text.contains('postpon')) {
      return SportsMatchStatus.postponed;
    }

    if (text.contains('cancel')) {
      return SportsMatchStatus.cancelled;
    }

    if (text.contains('abandon')) {
      return SportsMatchStatus.abandoned;
    }

    if (text.contains('suspend')) {
      return SportsMatchStatus.suspended;
    }

    if (text.contains('scheduled') ||
        text.contains('upcoming') ||
        text.contains('not started') ||
        text == 'ns') {
      return SportsMatchStatus.scheduled;
    }

    return SportsMatchStatus.unknown;
  }

  static Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return <String, dynamic>{};
  }

  static String _string(dynamic value) {
    return value?.toString() ?? '';
  }

  static int _int(dynamic value) {
    if (value is int) return value;

    if (value is double) {
      return value.round();
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _nullableInt(dynamic value) {
    if (value == null) return null;

    if (value is int) return value;

    if (value is num) return value.toInt();

    return int.tryParse(value.toString());
  }

  static DateTime? _dateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item?.toString() ?? '')
          .where((item) => item.isNotEmpty)
          .toList();
    }

    return const [];
  }
}

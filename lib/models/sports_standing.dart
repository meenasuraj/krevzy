import 'package:cloud_firestore/cloud_firestore.dart';

class SportsStanding {
  final String id;
  final String competitionId;
  final String sport;
  final String teamId;
  final String teamName;
  final String teamLogoUrl;

  final int position;
  final int played;
  final int won;
  final int drawn;
  final int lost;

  final int points;
  final int goalsFor;
  final int goalsAgainst;
  final int goalDifference;

  final int wins;
  final int losses;

  const SportsStanding({
    required this.id,
    required this.competitionId,
    required this.sport,
    required this.teamId,
    required this.teamName,
    this.teamLogoUrl = '',
    this.position = 0,
    this.played = 0,
    this.won = 0,
    this.drawn = 0,
    this.lost = 0,
    this.points = 0,
    this.goalsFor = 0,
    this.goalsAgainst = 0,
    this.goalDifference = 0,
    this.wins = 0,
    this.losses = 0,
  });

  factory SportsStanding.fromMap(Map<String, dynamic> map) {
    return SportsStanding(
      id: _string(map['id'] ?? map['standingId']),
      competitionId: _string(map['competitionId'] ?? map['leagueId']),
      sport: _string(map['sport']),
      teamId: _string(map['teamId'] ?? map['team_id']),
      teamName: _string(map['teamName'] ?? map['name']),
      teamLogoUrl: _string(map['teamLogoUrl'] ?? map['logo'] ?? map['logoUrl']),
      position: _int(map['position'] ?? map['rank']),
      played: _int(map['played'] ?? map['gamesPlayed']),
      won: _int(map['won'] ?? map['wins']),
      drawn: _int(map['drawn'] ?? map['draws']),
      lost: _int(map['lost'] ?? map['losses']),
      points: _int(map['points']),
      goalsFor: _int(map['goalsFor'] ?? map['for']),
      goalsAgainst: _int(map['goalsAgainst'] ?? map['against']),
      goalDifference: _int(
        map['goalDifference'] ?? map['goalDiff'] ?? map['gd'],
      ),
      wins: _int(map['wins']),
      losses: _int(map['losses']),
    );
  }

  factory SportsStanding.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};

    return SportsStanding(
      id: document.id,
      competitionId: _string(data['competitionId']),
      sport: _string(data['sport']),
      teamId: _string(data['teamId']),
      teamName: _string(data['teamName']),
      teamLogoUrl: _string(data['teamLogoUrl']),
      position: _int(data['position']),
      played: _int(data['played']),
      won: _int(data['won']),
      drawn: _int(data['drawn']),
      lost: _int(data['lost']),
      points: _int(data['points']),
      goalsFor: _int(data['goalsFor']),
      goalsAgainst: _int(data['goalsAgainst']),
      goalDifference: _int(data['goalDifference']),
      wins: _int(data['wins']),
      losses: _int(data['losses']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'competitionId': competitionId,
      'sport': sport,
      'teamId': teamId,
      'teamName': teamName,
      'teamLogoUrl': teamLogoUrl,
      'position': position,
      'played': played,
      'won': won,
      'drawn': drawn,
      'lost': lost,
      'points': points,
      'goalsFor': goalsFor,
      'goalsAgainst': goalsAgainst,
      'goalDifference': goalDifference,
      'wins': wins,
      'losses': losses,
    };
  }

  SportsStanding copyWith({
    String? id,
    String? competitionId,
    String? sport,
    String? teamId,
    String? teamName,
    String? teamLogoUrl,
    int? position,
    int? played,
    int? won,
    int? drawn,
    int? lost,
    int? points,
    int? goalsFor,
    int? goalsAgainst,
    int? goalDifference,
    int? wins,
    int? losses,
  }) {
    return SportsStanding(
      id: id ?? this.id,
      competitionId: competitionId ?? this.competitionId,
      sport: sport ?? this.sport,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      teamLogoUrl: teamLogoUrl ?? this.teamLogoUrl,
      position: position ?? this.position,
      played: played ?? this.played,
      won: won ?? this.won,
      drawn: drawn ?? this.drawn,
      lost: lost ?? this.lost,
      points: points ?? this.points,
      goalsFor: goalsFor ?? this.goalsFor,
      goalsAgainst: goalsAgainst ?? this.goalsAgainst,
      goalDifference: goalDifference ?? this.goalDifference,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
    );
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
}

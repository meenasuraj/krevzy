import 'package:cloud_firestore/cloud_firestore.dart';

class SportsCompetition {
  final String id;
  final String name;
  final String shortName;
  final String sport;
  final String country;
  final String logoUrl;
  final String season;
  final String? type;

  const SportsCompetition({
    required this.id,
    required this.name,
    this.shortName = '',
    this.sport = '',
    this.country = '',
    this.logoUrl = '',
    this.season = '',
    this.type,
  });

  factory SportsCompetition.fromMap(Map<String, dynamic> map) {
    return SportsCompetition(
      id: _string(map['id'] ?? map['competitionId'] ?? map['leagueId']),
      name: _string(map['name'] ?? map['competitionName'] ?? map['leagueName']),
      shortName: _string(map['shortName'] ?? map['short_name']),
      sport: _string(map['sport']),
      country: _string(map['country'] ?? map['countryName']),
      logoUrl: _string(map['logoUrl'] ?? map['logo'] ?? map['imageUrl']),
      season: _string(map['season'] ?? map['seasonName']),
      type: _nullableString(map['type']),
    );
  }

  factory SportsCompetition.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};

    return SportsCompetition(
      id: document.id,
      name: _string(data['name']),
      shortName: _string(data['shortName']),
      sport: _string(data['sport']),
      country: _string(data['country']),
      logoUrl: _string(data['logoUrl']),
      season: _string(data['season']),
      type: _nullableString(data['type']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'shortName': shortName,
      'sport': sport,
      'country': country,
      'logoUrl': logoUrl,
      'season': season,
      'type': type,
    };
  }

  SportsCompetition copyWith({
    String? id,
    String? name,
    String? shortName,
    String? sport,
    String? country,
    String? logoUrl,
    String? season,
    String? type,
  }) {
    return SportsCompetition(
      id: id ?? this.id,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      sport: sport ?? this.sport,
      country: country ?? this.country,
      logoUrl: logoUrl ?? this.logoUrl,
      season: season ?? this.season,
      type: type ?? this.type,
    );
  }

  static String _string(dynamic value) {
    return value?.toString() ?? '';
  }

  static String? _nullableString(dynamic value) {
    if (value == null) return null;

    final result = value.toString().trim();

    return result.isEmpty ? null : result;
  }
}

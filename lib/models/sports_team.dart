import 'package:cloud_firestore/cloud_firestore.dart';

class SportsTeam {
  final String id;
  final String name;
  final String shortName;
  final String logoUrl;
  final String country;
  final String sport;
  final String? venue;

  const SportsTeam({
    required this.id,
    required this.name,
    this.shortName = '',
    this.logoUrl = '',
    this.country = '',
    this.sport = '',
    this.venue,
  });

  factory SportsTeam.fromMap(Map<String, dynamic> map) {
    return SportsTeam(
      id: _string(map['id'] ?? map['teamId']),
      name: _string(map['name'] ?? map['teamName']),
      shortName: _string(map['shortName'] ?? map['short_name'] ?? map['abbr']),
      logoUrl: _string(map['logoUrl'] ?? map['logo'] ?? map['imageUrl']),
      country: _string(map['country'] ?? map['countryName']),
      sport: _string(map['sport']),
      venue: _nullableString(map['venue']),
    );
  }

  factory SportsTeam.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return SportsTeam(
      id: document.id,
      name: _string(document.data()?['name']),
      shortName: _string(document.data()?['shortName']),
      logoUrl: _string(document.data()?['logoUrl']),
      country: _string(document.data()?['country']),
      sport: _string(document.data()?['sport']),
      venue: _nullableString(document.data()?['venue']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'shortName': shortName,
      'logoUrl': logoUrl,
      'country': country,
      'sport': sport,
      'venue': venue,
    };
  }

  SportsTeam copyWith({
    String? id,
    String? name,
    String? shortName,
    String? logoUrl,
    String? country,
    String? sport,
    String? venue,
  }) {
    return SportsTeam(
      id: id ?? this.id,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      logoUrl: logoUrl ?? this.logoUrl,
      country: country ?? this.country,
      sport: sport ?? this.sport,
      venue: venue ?? this.venue,
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

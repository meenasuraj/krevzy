import 'package:cloud_firestore/cloud_firestore.dart';

class SportsPlayer {
  final String id;
  final String name;
  final String shortName;
  final String photoUrl;
  final String country;
  final String sport;
  final String teamId;
  final String position;
  final String? jerseyNumber;

  const SportsPlayer({
    required this.id,
    required this.name,
    this.shortName = '',
    this.photoUrl = '',
    this.country = '',
    this.sport = '',
    this.teamId = '',
    this.position = '',
    this.jerseyNumber,
  });

  factory SportsPlayer.fromMap(Map<String, dynamic> map) {
    return SportsPlayer(
      id: _string(map['id'] ?? map['playerId']),
      name: _string(map['name'] ?? map['playerName']),
      shortName: _string(map['shortName'] ?? map['short_name']),
      photoUrl: _string(map['photoUrl'] ?? map['photo'] ?? map['imageUrl']),
      country: _string(map['country'] ?? map['countryName']),
      sport: _string(map['sport']),
      teamId: _string(map['teamId'] ?? map['team_id']),
      position: _string(map['position'] ?? map['role']),
      jerseyNumber: _nullableString(map['jerseyNumber'] ?? map['number']),
    );
  }

  factory SportsPlayer.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};

    return SportsPlayer(
      id: document.id,
      name: _string(data['name']),
      shortName: _string(data['shortName']),
      photoUrl: _string(data['photoUrl']),
      country: _string(data['country']),
      sport: _string(data['sport']),
      teamId: _string(data['teamId']),
      position: _string(data['position']),
      jerseyNumber: _nullableString(data['jerseyNumber']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'shortName': shortName,
      'photoUrl': photoUrl,
      'country': country,
      'sport': sport,
      'teamId': teamId,
      'position': position,
      'jerseyNumber': jerseyNumber,
    };
  }

  SportsPlayer copyWith({
    String? id,
    String? name,
    String? shortName,
    String? photoUrl,
    String? country,
    String? sport,
    String? teamId,
    String? position,
    String? jerseyNumber,
  }) {
    return SportsPlayer(
      id: id ?? this.id,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      photoUrl: photoUrl ?? this.photoUrl,
      country: country ?? this.country,
      sport: sport ?? this.sport,
      teamId: teamId ?? this.teamId,
      position: position ?? this.position,
      jerseyNumber: jerseyNumber ?? this.jerseyNumber,
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

import 'package:cloud_firestore/cloud_firestore.dart';

class SportsEvent {
  final String id;
  final String matchId;
  final String sport;
  final String type;
  final String title;
  final String description;
  final String teamId;
  final String playerId;
  final String playerName;
  final String minute;
  final DateTime? createdAt;

  const SportsEvent({
    required this.id,
    required this.matchId,
    required this.sport,
    required this.type,
    required this.title,
    this.description = '',
    this.teamId = '',
    this.playerId = '',
    this.playerName = '',
    this.minute = '',
    this.createdAt,
  });

  factory SportsEvent.fromMap(Map<String, dynamic> map) {
    return SportsEvent(
      id: _string(map['id'] ?? map['eventId']),
      matchId: _string(map['matchId'] ?? map['match_id']),
      sport: _string(map['sport']),
      type: _string(map['type'] ?? map['eventType']),
      title: _string(map['title']),
      description: _string(map['description']),
      teamId: _string(map['teamId'] ?? map['team_id']),
      playerId: _string(map['playerId'] ?? map['player_id']),
      playerName: _string(map['playerName'] ?? map['player_name']),
      minute: _string(map['minute'] ?? map['time']),
      createdAt: _dateTime(map['createdAt']),
    );
  }

  factory SportsEvent.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};

    return SportsEvent(
      id: document.id,
      matchId: _string(data['matchId']),
      sport: _string(data['sport']),
      type: _string(data['type']),
      title: _string(data['title']),
      description: _string(data['description']),
      teamId: _string(data['teamId']),
      playerId: _string(data['playerId']),
      playerName: _string(data['playerName']),
      minute: _string(data['minute']),
      createdAt: _dateTime(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'matchId': matchId,
      'sport': sport,
      'type': type,
      'title': title,
      'description': description,
      'teamId': teamId,
      'playerId': playerId,
      'playerName': playerName,
      'minute': minute,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
    };
  }

  SportsEvent copyWith({
    String? id,
    String? matchId,
    String? sport,
    String? type,
    String? title,
    String? description,
    String? teamId,
    String? playerId,
    String? playerName,
    String? minute,
    DateTime? createdAt,
  }) {
    return SportsEvent(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      sport: sport ?? this.sport,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      teamId: teamId ?? this.teamId,
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      minute: minute ?? this.minute,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static String _string(dynamic value) {
    return value?.toString() ?? '';
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
}

enum ChallengeType { game, study, knowledge, sports, business }

extension ChallengeTypeExtension on ChallengeType {
  String get value {
    switch (this) {
      case ChallengeType.game:
        return 'game';
      case ChallengeType.study:
        return 'study';
      case ChallengeType.knowledge:
        return 'knowledge';
      case ChallengeType.sports:
        return 'sports';
      case ChallengeType.business:
        return 'business';
    }
  }

  String get label {
    switch (this) {
      case ChallengeType.game:
        return 'Game Challenge';
      case ChallengeType.study:
        return 'Study Challenge';
      case ChallengeType.knowledge:
        return 'Knowledge Challenge';
      case ChallengeType.sports:
        return 'Sports Challenge';
      case ChallengeType.business:
        return 'Business Challenge';
    }
  }
}

class KrevzyChallenge {
  final String id;
  final String roomId;
  final String creatorId;
  final String title;
  final String description;
  final String gameName;
  final ChallengeType type;
  final int xpReward;
  final int level;
  final bool requiresEvidence;
  final bool isActive;
  final DateTime? expiresAt;

  const KrevzyChallenge({
    required this.id,
    required this.roomId,
    required this.creatorId,
    required this.title,
    required this.description,
    required this.gameName,
    required this.type,
    required this.xpReward,
    required this.level,
    required this.requiresEvidence,
    required this.isActive,
    this.expiresAt,
  });

  factory KrevzyChallenge.fromMap(String id, Map<String, dynamic> data) {
    final expires = data['expiresAt'];

    return KrevzyChallenge(
      id: id,
      roomId: data['roomId']?.toString() ?? '',
      creatorId: data['creatorId']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      gameName: data['gameName']?.toString() ?? '',
      type: _typeFromString(data['type']?.toString()),
      xpReward: (data['xpReward'] as num?)?.toInt() ?? 0,
      level: (data['level'] as num?)?.toInt() ?? 1,
      requiresEvidence: data['requiresEvidence'] == true,
      isActive: data['isActive'] != false,
      expiresAt: expires is DateTime ? expires : null,
    );
  }

  static ChallengeType _typeFromString(String? value) {
    switch (value) {
      case 'game':
        return ChallengeType.game;
      case 'study':
        return ChallengeType.study;
      case 'knowledge':
        return ChallengeType.knowledge;
      case 'sports':
        return ChallengeType.sports;
      case 'business':
        return ChallengeType.business;
      default:
        return ChallengeType.knowledge;
    }
  }
}

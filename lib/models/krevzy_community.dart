enum CommunityCategory {
  study,
  gaming,
  business,
  shareMarket,
  history,
  geography,
  cricket,
  hockey,
  football,
  other,
}

extension CommunityCategoryExtension on CommunityCategory {
  String get value {
    switch (this) {
      case CommunityCategory.study:
        return 'study';
      case CommunityCategory.gaming:
        return 'gaming';
      case CommunityCategory.business:
        return 'business';
      case CommunityCategory.shareMarket:
        return 'share_market';
      case CommunityCategory.history:
        return 'history';
      case CommunityCategory.geography:
        return 'geography';
      case CommunityCategory.cricket:
        return 'cricket';
      case CommunityCategory.hockey:
        return 'hockey';
      case CommunityCategory.football:
        return 'football';
      case CommunityCategory.other:
        return 'other';
    }
  }

  String get label {
    switch (this) {
      case CommunityCategory.study:
        return 'Group Study';
      case CommunityCategory.gaming:
        return 'Gaming';
      case CommunityCategory.business:
        return 'Business';
      case CommunityCategory.shareMarket:
        return 'Share Market';
      case CommunityCategory.history:
        return 'History';
      case CommunityCategory.geography:
        return 'Geography';
      case CommunityCategory.cricket:
        return 'Cricket';
      case CommunityCategory.hockey:
        return 'Hockey';
      case CommunityCategory.football:
        return 'Football';
      case CommunityCategory.other:
        return 'Other';
    }
  }

  static CommunityCategory fromValue(String value) {
    switch (value) {
      case 'study':
        return CommunityCategory.study;
      case 'gaming':
        return CommunityCategory.gaming;
      case 'business':
        return CommunityCategory.business;
      case 'share_market':
        return CommunityCategory.shareMarket;
      case 'history':
        return CommunityCategory.history;
      case 'geography':
        return CommunityCategory.geography;
      case 'cricket':
        return CommunityCategory.cricket;
      case 'hockey':
        return CommunityCategory.hockey;
      case 'football':
        return CommunityCategory.football;
      default:
        return CommunityCategory.other;
    }
  }
}

class KrevzyCommunity {
  final String id;
  final String name;
  final String description;
  final String ownerId;
  final String ownerName;
  final CommunityCategory category;
  final bool isPublic;
  final bool allowMemberChallenges;
  final bool allowMemberRules;
  final int memberCount;
  final int challengeCount;
  final DateTime? createdAt;

  const KrevzyCommunity({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerId,
    required this.ownerName,
    required this.category,
    required this.isPublic,
    required this.allowMemberChallenges,
    required this.allowMemberRules,
    required this.memberCount,
    required this.challengeCount,
    this.createdAt,
  });

  factory KrevzyCommunity.fromMap(String id, Map<String, dynamic> data) {
    final created = data['createdAt'];

    return KrevzyCommunity(
      id: id,
      name: data['name']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      ownerId: data['ownerId']?.toString() ?? '',
      ownerName: data['ownerName']?.toString() ?? '',
      category: CommunityCategoryExtension.fromValue(
        data['category']?.toString() ?? 'other',
      ),
      isPublic: data['isPublic'] == true,
      allowMemberChallenges: data['allowMemberChallenges'] != false,
      allowMemberRules: data['allowMemberRules'] != false,
      memberCount: (data['memberCount'] as num?)?.toInt() ?? 0,
      challengeCount: (data['challengeCount'] as num?)?.toInt() ?? 0,
      createdAt: created is DateTime ? created : null,
    );
  }
}

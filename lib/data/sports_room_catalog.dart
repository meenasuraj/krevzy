
class SportsRoomDefinition {
  final String id;
  final String name;
  final String emoji;
  final String category;
  final String description;

  const SportsRoomDefinition({
    required this.id,
    required this.name,
    required this.emoji,
    required this.category,
    required this.description,
  });
}

class SportsRoomCatalog {
  SportsRoomCatalog._();

  static const List<SportsRoomDefinition> all = [
    SportsRoomDefinition(
      id: 'sports_cricket',
      name: 'Cricket',
      emoji: '🏏',
      category: 'Cricket',
      description:
          'Cricket live scores, matches, results and discussions.',
    ),
    SportsRoomDefinition(
      id: 'sports_football',
      name: 'Football',
      emoji: '⚽',
      category: 'Football',
      description:
          'Football live scores, fixtures, results and discussions.',
    ),
    SportsRoomDefinition(
      id: 'sports_hockey',
      name: 'Hockey',
      emoji: '🏑',
      category: 'Hockey',
      description:
          'Hockey matches, scores, results and discussions.',
    ),
    SportsRoomDefinition(
      id: 'sports_basketball',
      name: 'Basketball',
      emoji: '🏀',
      category: 'Basketball',
      description:
          'Basketball live scores, fixtures and discussions.',
    ),
    SportsRoomDefinition(
      id: 'sports_tennis',
      name: 'Tennis',
      emoji: '🎾',
      category: 'Tennis',
      description:
          'Tennis matches, results and live match updates.',
    ),
    SportsRoomDefinition(
      id: 'sports_baseball',
      name: 'Baseball',
      emoji: '⚾',
      category: 'Baseball',
      description:
          'Baseball scores, fixtures and match discussions.',
    ),
    SportsRoomDefinition(
      id: 'sports_volleyball',
      name: 'Volleyball',
      emoji: '🏐',
      category: 'Volleyball',
      description:
          'Volleyball scores, fixtures and discussions.',
    ),
    SportsRoomDefinition(
      id: 'sports_rugby',
      name: 'Rugby',
      emoji: '🏉',
      category: 'Rugby',
      description:
          'Rugby matches, scores and live discussions.',
    ),
    SportsRoomDefinition(
      id: 'sports_kabaddi',
      name: 'Kabaddi',
      emoji: '🤼',
      category: 'Kabaddi',
      description:
          'Kabaddi matches, results and live updates.',
    ),
    SportsRoomDefinition(
      id: 'sports_handball',
      name: 'Handball',
      emoji: '🤾',
      category: 'Handball',
      description:
          'Handball scores, fixtures and discussions.',
    ),
    SportsRoomDefinition(
      id: 'sports_badminton',
      name: 'Badminton',
      emoji: '🏸',
      category: 'Badminton',
      description:
          'Badminton matches, results and live updates.',
    ),
    SportsRoomDefinition(
      id: 'sports_table_tennis',
      name: 'Table Tennis',
      emoji: '🏓',
      category: 'Table Tennis',
      description:
          'Table tennis matches, results and discussions.',
    ),
    SportsRoomDefinition(
      id: 'sports_golf',
      name: 'Golf',
      emoji: '⛳',
      category: 'Golf',
      description:
          'Golf tournaments, results and live updates.',
    ),
    SportsRoomDefinition(
      id: 'sports_boxing',
      name: 'Boxing',
      emoji: '🥊',
      category: 'Boxing',
      description:
          'Boxing events, results and discussions.',
    ),
    SportsRoomDefinition(
      id: 'sports_wrestling',
      name: 'Wrestling',
      emoji: '🤼',
      category: 'Wrestling',
      description:
          'Wrestling events, results and discussions.',
    ),
    SportsRoomDefinition(
      id: 'sports_athletics',
      name: 'Athletics',
      emoji: '🏃',
      category: 'Athletics',
      description:
          'Athletics events, results and live updates.',
    ),
    SportsRoomDefinition(
      id: 'sports_motorsport',
      name: 'Motorsport',
      emoji: '🏎️',
      category: 'Motorsport',
      description:
          'Motorsport events, results and live updates.',
    ),
    SportsRoomDefinition(
      id: 'sports_cycling',
      name: 'Cycling',
      emoji: '🚴',
      category: 'Cycling',
      description:
          'Cycling races, results and live updates.',
    ),
    SportsRoomDefinition(
      id: 'sports_swimming',
      name: 'Swimming',
      emoji: '🏊',
      category: 'Swimming',
      description:
          'Swimming events, results and live updates.',
    ),
    SportsRoomDefinition(
      id: 'sports_esports',
      name: 'Esports',
      emoji: '🎮',
      category: 'Esports',
      description:
          'Esports matches, results and live discussions.',
    ),
  ];

  static SportsRoomDefinition? byId(String id) {
    for (final room in all) {
      if (room.id == id) {
        return room;
      }
    }

    return null;
  }

  static SportsRoomDefinition? byCategory(String category) {
    final target = category.trim().toLowerCase();

    for (final room in all) {
      if (room.category.toLowerCase() == target ||
          room.name.toLowerCase() == target) {
        return room;
      }
    }

    return null;
  }
}
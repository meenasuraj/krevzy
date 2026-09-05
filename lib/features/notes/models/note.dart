class Note {
  final String id;
  final String ownerId;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Note({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });
}

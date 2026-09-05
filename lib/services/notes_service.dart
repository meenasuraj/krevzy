import '../../features/notes/models/note.dart';

abstract class NotesService {
  Stream<List<Note>> watchMyNotes(String ownerId);
  Future<String> createNote({
    required String ownerId,
    required String title,
    required String content,
  });
  Future<void> updateNote(Note note);
  Future<void> deleteNote(String ownerId, String noteId);
}

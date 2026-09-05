import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotesService {
  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static final FirebaseAuth _auth =
      FirebaseAuth.instance;

  static String get currentUserId {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    return user.uid;
  }

  static CollectionReference<Map<String, dynamic>>
      _notesCollection() {
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('notes');
  }

  // ===========================================================================
  // GET NOTES
  // ===========================================================================

  static Stream<QuerySnapshot<Map<String, dynamic>>>
      getNotes() {
    return _notesCollection()
        .orderBy(
          'updatedAt',
          descending: true,
        )
        .snapshots();
  }

  // ===========================================================================
  // CREATE NOTE
  // ===========================================================================

  static Future<String> createNote({
    required String title,
    required String content,
  }) async {
    final uid = currentUserId;

    final cleanTitle = title.trim();
    final cleanContent = content.trim();

    if (cleanTitle.isEmpty &&
        cleanContent.isEmpty) {
      throw Exception(
        'Note cannot be empty.',
      );
    }

    if (cleanTitle.length > 200) {
      throw Exception(
        'Note title cannot exceed 200 characters.',
      );
    }

    if (cleanContent.length > 10000) {
      throw Exception(
        'Note content cannot exceed 10000 characters.',
      );
    }

    final now =
        FieldValue.serverTimestamp();

    final noteRef =
        _notesCollection().doc();

    await noteRef.set({
      'userId': uid,
      'title': cleanTitle,
      'content': cleanContent,
      'createdAt': now,
      'updatedAt': now,
    });

    return noteRef.id;
  }

  // ===========================================================================
  // UPDATE NOTE
  // ===========================================================================

  static Future<void> updateNote({
    required String noteId,
    required String title,
    required String content,
  }) async {
    final cleanTitle = title.trim();
    final cleanContent = content.trim();

    if (cleanTitle.isEmpty &&
        cleanContent.isEmpty) {
      throw Exception(
        'Note cannot be empty.',
      );
    }

    if (cleanTitle.length > 200) {
      throw Exception(
        'Note title cannot exceed 200 characters.',
      );
    }

    if (cleanContent.length > 10000) {
      throw Exception(
        'Note content cannot exceed 10000 characters.',
      );
    }

    await _notesCollection()
        .doc(noteId)
        .update({
      'title': cleanTitle,
      'content': cleanContent,
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  // ===========================================================================
  // DELETE NOTE
  // ===========================================================================

  static Future<void> deleteNote(
    String noteId,
  ) async {
    await _notesCollection()
        .doc(noteId)
        .delete();
  }

  // ===========================================================================
  // SEARCH NOTES
  //
  // Search is performed locally from the already-loaded user's private notes.
  // This avoids requiring additional Firestore indexes and keeps the query
  // private to the authenticated user's notes collection.
  // ===========================================================================

  static List<QueryDocumentSnapshot<Map<String, dynamic>>>
      filterNotes(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> notes,
    String query,
  ) {
    final cleanQuery =
        query.trim().toLowerCase();

    if (cleanQuery.isEmpty) {
      return notes;
    }

    return notes.where((note) {
      final data = note.data();

      final title =
          (data['title'] ?? '')
              .toString()
              .toLowerCase();

      final content =
          (data['content'] ?? '')
              .toString()
              .toLowerCase();

      return title.contains(cleanQuery) ||
          content.contains(cleanQuery);
    }).toList();
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String get currentUserId {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    return user.uid;
  }

  // ============================================================
  // CURRENT USER PROFILE
  // ============================================================

  static Future<DocumentSnapshot<Map<String, dynamic>>>
  getCurrentUserProfile() {
    return _firestore.collection('users').doc(currentUserId).get();
  }

  // ============================================================
  // GET USER BY UID
  // ============================================================

  static Future<DocumentSnapshot<Map<String, dynamic>>> getUserById(
    String uid,
  ) {
    return _firestore.collection('users').doc(uid).get();
  }

  // ============================================================
  // SEARCH USERS BY USERNAME
  // ============================================================

  static Stream<QuerySnapshot<Map<String, dynamic>>> searchUsers(
    String username,
  ) {
    final query = username.trim().toLowerCase();

    if (query.isEmpty) {
      return const Stream.empty();
    }

    return _firestore
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThan: '$query\uf8ff')
        .limit(20)
        .snapshots();
  }

  // ============================================================
  // SEARCH USER ONCE
  // ============================================================

  static Future<QuerySnapshot<Map<String, dynamic>>> searchUsersOnce(
    String username,
  ) async {
    final query = username.trim().toLowerCase();

    if (query.isEmpty) {
      throw Exception('Username cannot be empty.');
    }

    return _firestore
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThan: '$query\uf8ff')
        .limit(20)
        .get();
  }
}

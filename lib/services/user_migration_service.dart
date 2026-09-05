import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserMigrationService {
  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static final FirebaseAuth _auth =
      FirebaseAuth.instance;

  static Future<int> migrateCurrentUser() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    final userRef = _firestore
        .collection('users')
        .doc(user.uid);

    final snapshot = await userRef.get();

    if (!snapshot.exists) {
      throw Exception(
        'Your GAPSHAP profile was not found.',
      );
    }

    final data = snapshot.data() ?? {};

    final name = data['name']?.toString().trim() ?? '';
    final username =
        data['username']?.toString().trim().toLowerCase() ?? '';

    await userRef.set(
      {
        'nameLowercase': name.toLowerCase(),
        'usernameLowercase': username,
        'postsCount': _readInt(data['postsCount']),
        'followersCount': _readInt(data['followersCount']),
        'followingCount': _readInt(data['followingCount']),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    return 1;
  }

  static int _readInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }
}
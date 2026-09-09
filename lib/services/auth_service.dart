import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Sign Up & Auto-Create User Collection in Firestore
  Future<UserCredential?> signUpWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;
      if (user != null) {
        // Automatically create 'users' document
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'username': username,
          'handle': '@${username.toLowerCase().replaceAll(' ', '')}',
          'email': email,
          'profilePic': '',
          'followers': [],
          'following': [],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // 2. Sign In
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // 3. Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
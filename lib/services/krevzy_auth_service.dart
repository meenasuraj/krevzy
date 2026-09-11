import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'session_service.dart';

class KrevzyAuthService {
  KrevzyAuthService._();

  static final KrevzyAuthService instance =
      KrevzyAuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  bool _googleInitialized = false;

  // ============================================================
  // CURRENT USER
  // ============================================================

  User? get currentFirebaseUser => _auth.currentUser;

  // ============================================================
  // EMAIL LOGIN
  // ============================================================

  Future<UserCredential> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim();

    if (cleanEmail.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: 'Email is required.',
      );
    }

    if (password.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-password',
        message: 'Password is required.',
      );
    }

    final credential =
        await _auth.signInWithEmailAndPassword(
      email: cleanEmail,
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'login-failed',
        message: 'Unable to sign in.',
      );
    }

    // Check KREVZY profile status.
    final userDoc = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

    if (userDoc.exists) {
      final data = userDoc.data();

      if (data != null &&
          data['isDeactivated'] == true) {
        await _auth.signOut();

        throw FirebaseAuthException(
          code: 'account-deactivated',
          message: 'This account has been deactivated.',
        );
      }
    }

    await SessionService.startSession();

    return credential;
  }

  // ============================================================
  // FORGOT PASSWORD
  // ============================================================

  Future<void> sendPasswordReset({
    required String email,
  }) async {
    final cleanEmail = email.trim();

    if (cleanEmail.isEmpty ||
        !cleanEmail.contains('@')) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: 'Please enter a valid email address.',
      );
    }

    await _auth.sendPasswordResetEmail(
      email: cleanEmail,
    );
  }

  // ============================================================
  // GOOGLE SIGN-IN
  // ============================================================

  Future<UserCredential> signInWithGoogle() async {
    UserCredential credential;

    if (kIsWeb) {
      final provider = GoogleAuthProvider();

      provider.setCustomParameters({
        'prompt': 'select_account',
      });

      credential =
          await _auth.signInWithPopup(provider);
    } else {
      if (!_googleInitialized) {
        await GoogleSignIn.instance.initialize();
        _googleInitialized = true;
      }

      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        // Safe to ignore.
      }

      final googleUser =
          await GoogleSignIn.instance.authenticate();

      final googleAuth =
          googleUser.authentication;

      final idToken = googleAuth.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw FirebaseAuthException(
          code: 'google-no-id-token',
          message:
              'Google did not return a valid ID token.',
        );
      }

      final googleCredential =
          GoogleAuthProvider.credential(
        idToken: idToken,
      );

      credential =
          await _auth.signInWithCredential(
        googleCredential,
      );
    }

    final user = credential.user;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'google-login-failed',
        message: 'Unable to get Google user.',
      );
    }

    // Check deactivation.
    final userDoc = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

    if (userDoc.exists) {
      final data = userDoc.data();

      if (data != null &&
          data['isDeactivated'] == true) {
        await _auth.signOut();

        throw FirebaseAuthException(
          code: 'account-deactivated',
          message: 'This account has been deactivated.',
        );
      }
    }

    await _createOrUpdateGoogleProfile(user);

    await SessionService.startSession();

    return credential;
  }

  // ============================================================
  // GOOGLE PROFILE
  // ============================================================

  Future<void> _createOrUpdateGoogleProfile(
    User user,
  ) async {
    final userRef =
        _firestore.collection('users').doc(user.uid);

    final snapshot = await userRef.get();

    final displayName =
        (user.displayName ?? '').trim();

    final email =
        (user.email ?? '').trim();

    final photoUrl =
        (user.photoURL ?? '').trim();

    if (snapshot.exists) {
      await userRef.set(
        {
          'uid': user.uid,
          'email': email,
          'name': displayName,
          'nameLowercase': displayName.toLowerCase(),
          'photoUrl': photoUrl,
          'authProvider': 'google',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      return;
    }

    final nameForUsername =
        displayName.isNotEmpty
            ? displayName
            : 'KREVZY User';

    String username = nameForUsername
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '');

    if (username.isEmpty) {
      username = 'krevzyuser';
    }

    // Make sure username is unique.
    final usernameQuery = await _firestore
        .collection('users')
        .where(
          'usernameLowercase',
          isEqualTo: username,
        )
        .limit(1)
        .get();

    if (usernameQuery.docs.isNotEmpty) {
      username =
          '$username${DateTime.now().millisecondsSinceEpoch % 100000}';
    }

    await userRef.set({
      'uid': user.uid,
      'name': nameForUsername,
      'nameLowercase':
          nameForUsername.toLowerCase(),
      'username': username,
      'usernameLowercase':
          username.toLowerCase(),
      'email': email,
      'bio': '',
      'photoUrl': photoUrl,
      'postsCount': 0,
      'followersCount': 0,
      'followingCount': 0,
      'isDeactivated': false,
      'authProvider': 'google',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // SIGN OUT
  // ============================================================

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } finally {
      if (!kIsWeb) {
        try {
          await GoogleSignIn.instance.signOut();
        } catch (_) {
          // Safe to ignore.
        }
      }
    }
  }
}
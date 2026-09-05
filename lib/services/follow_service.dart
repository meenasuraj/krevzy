import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'notification_service.dart';

class FollowService {
  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static final FirebaseAuth _auth =
      FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> _following(
    String userId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('following');
  }

  static CollectionReference<Map<String, dynamic>> _followers(
    String userId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('followers');
  }

  // ============================================================
  // CHECK FOLLOWING STATUS
  // ============================================================

  static Stream<bool> followingStream(
    String targetUserId,
  ) {
    final user = _auth.currentUser;

    if (user == null || user.uid == targetUserId) {
      return Stream.value(false);
    }

    return _following(user.uid)
        .doc(targetUserId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  // ============================================================
  // FOLLOW USER
  // ============================================================

  static Future<void> follow({
    required String targetUserId,
    required String targetUsername,
    required String targetName,
    required String targetPhotoUrl,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    if (user.uid == targetUserId) {
      throw Exception('You cannot follow yourself.');
    }

    // ----------------------------------------------------------
    // Get current user's profile information.
    // ----------------------------------------------------------

    final currentUserSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

    final currentUserData =
        currentUserSnapshot.data() ?? {};

    final currentUsername =
        currentUserData['username']?.toString() ?? '';

    final currentName =
        currentUserData['name']?.toString() ?? '';

    final currentPhotoUrl =
        currentUserData['photoUrl']?.toString() ?? '';

    // ----------------------------------------------------------
    // References
    // ----------------------------------------------------------

    final followingRef =
        _following(user.uid).doc(targetUserId);

    final followerRef =
        _followers(targetUserId).doc(user.uid);

    // ----------------------------------------------------------
    // Create both follow records together.
    // ----------------------------------------------------------

    final batch = _firestore.batch();

    batch.set(
      followingRef,
      {
        'userId': targetUserId,
        'username': targetUsername,
        'name': targetName,
        'photoUrl': targetPhotoUrl,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );

    batch.set(
      followerRef,
      {
        'userId': user.uid,
        'username': currentUsername,
        'name': currentName,
        'photoUrl': currentPhotoUrl,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();

    // ----------------------------------------------------------
    // Create follow notification for the target user.
    // ----------------------------------------------------------

    final displayUsername = currentUsername.isNotEmpty
        ? currentUsername
        : currentName.isNotEmpty
            ? currentName
            : 'Someone';

    await NotificationService.createNotification(
      receiverUserId: targetUserId,
      type: 'follow',
      message:
          '$displayUsername started following you',
      fromUsername: currentUsername,
      fromUserPhotoUrl: currentPhotoUrl,
    );
  }

  // ============================================================
  // UNFOLLOW USER
  // ============================================================

  static Future<void> unfollow(
    String targetUserId,
  ) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    if (user.uid == targetUserId) {
      return;
    }

    final followingRef =
        _following(user.uid).doc(targetUserId);

    final followerRef =
        _followers(targetUserId).doc(user.uid);

    final batch = _firestore.batch();

    batch.delete(followingRef);
    batch.delete(followerRef);

    await batch.commit();
  }

  // ============================================================
  // FOLLOWERS COUNT
  // ============================================================

  static Stream<int> followersCountStream(
    String userId,
  ) {
    return _followers(userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // ============================================================
  // FOLLOWING COUNT
  // ============================================================

  static Stream<int> followingCountStream(
    String userId,
  ) {
    return _following(userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // ============================================================
  // FOLLOWERS LIST
  // ============================================================

  static Stream<
      List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      followersStream(
    String userId,
  ) {
    return _followers(userId)
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs,
        );
  }

  // ============================================================
  // FOLLOWING LIST
  // ============================================================

  static Stream<
      List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      followingUsersStream(
    String userId,
  ) {
    return _following(userId)
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs,
        );
  }
}
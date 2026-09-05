import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/post.dart';
import 'notification_service.dart';

class PostService {
  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static final FirebaseAuth _auth =
      FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> get _posts =>
      _firestore.collection('posts');

  // ============================================================
  // CURRENT USER ID
  // ============================================================

  static String? get currentUserId {
    return _auth.currentUser?.uid;
  }

  // ============================================================
  // CREATE POST
  // ============================================================

  static Future<String> createPost({
    required String caption,
    required String mediaUrl,
    required String mediaType,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    final userDoc = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

    final userData = userDoc.data() ?? {};

    final username =
        userData['username']?.toString() ??
        user.displayName ??
        'user';

    final userName =
        userData['name']?.toString() ??
        user.displayName ??
        '';

    final userPhotoUrl =
        userData['photoUrl']?.toString() ??
        '';

    final docRef = _posts.doc();

    final post = Post(
      id: docRef.id,
      userId: user.uid,
      username: username,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      caption: caption.trim(),
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      likesCount: 0,
      commentsCount: 0,
      createdAt: DateTime.now(),
    );

    await docRef.set(post.toFirestore());

    return docRef.id;
  }

  // ============================================================
  // GET POSTS
  // ============================================================

  static Stream<List<Post>> getPosts({
    int limit = 30,
  }) {
    return _posts
        .orderBy(
          'createdAt',
          descending: true,
        )
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(Post.fromFirestore)
              .toList(),
        );
  }

  // ============================================================
  // GET SINGLE POST
  // ============================================================

  static Future<Post?> getPost(
    String postId,
  ) async {
    final snapshot =
        await _posts.doc(postId).get();

    if (!snapshot.exists) {
      return null;
    }

    return Post.fromFirestore(snapshot);
  }

  // ============================================================
  // DELETE POST
  // ============================================================

  static Future<void> deletePost(
    String postId,
  ) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'User is not logged in.',
      );
    }

    final postRef =
        _posts.doc(postId);

    final postDoc =
        await postRef.get();

    if (!postDoc.exists) {
      throw Exception(
        'Post not found.',
      );
    }

    final data =
        postDoc.data() ?? {};

    if (data['userId'] != user.uid) {
      throw Exception(
        'You can only delete your own post.',
      );
    }

    await postRef.delete();
  }

  // ============================================================
  // LIKE / UNLIKE POST
  // ============================================================

  static Future<void> likePost(
    String postId,
  ) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'User is not logged in.',
      );
    }

    final postRef =
        _posts.doc(postId);

    final likeRef = postRef
        .collection('likes')
        .doc(user.uid);

    String receiverUserId = '';
    bool wasLiked = false;

    await _firestore.runTransaction(
      (transaction) async {
        final postDoc =
            await transaction.get(postRef);

        final likeDoc =
            await transaction.get(likeRef);

        if (!postDoc.exists) {
          throw Exception(
            'Post not found.',
          );
        }

        final data =
            postDoc.data() ?? {};

        receiverUserId =
            data['userId']?.toString() ?? '';

        final currentLikes =
            (data['likesCount'] as num?)
                    ?.toInt() ??
                0;

        if (likeDoc.exists) {
          // UNLIKE
          wasLiked = false;

          transaction.delete(
            likeRef,
          );

          transaction.update(
            postRef,
            {
              'likesCount':
                  currentLikes > 0
                      ? currentLikes - 1
                      : 0,
            },
          );
        } else {
          // LIKE
          wasLiked = true;

          transaction.set(
            likeRef,
            {
              'userId': user.uid,
              'createdAt':
                  FieldValue.serverTimestamp(),
            },
          );

          transaction.update(
            postRef,
            {
              'likesCount':
                  currentLikes + 1,
            },
          );
        }
      },
    );

    // ----------------------------------------------------------
    // SEND LIKE NOTIFICATION
    // ----------------------------------------------------------

    if (wasLiked &&
        receiverUserId.isNotEmpty &&
        receiverUserId != user.uid) {
      try {
        final userDoc =
            await _firestore
                .collection('users')
                .doc(user.uid)
                .get();

        final userData =
            userDoc.data() ?? {};

        final username =
            userData['username']
                    ?.toString() ??
                user.displayName ??
                'user';

        final photoUrl =
            userData['photoUrl']
                    ?.toString() ??
                '';

        await NotificationService
            .createNotification(
          receiverUserId:
              receiverUserId,
          type: 'like',
          fromUsername:
              username,
          fromUserPhotoUrl:
              photoUrl,
          postId: postId,
          message:
              '$username liked your post',
        );
      } catch (e) {
        // Notification failure should not
        // undo the successful like.
        //
        // Print the actual Firebase error
        // so we can diagnose it.
        print(
          'LIKE NOTIFICATION ERROR: $e',
        );
      }
    }
  }

  // ============================================================
  // CHECK LIKE
  // ============================================================

  static Future<bool> hasLiked(
    String postId,
  ) async {
    final user = _auth.currentUser;

    if (user == null) {
      return false;
    }

    final likeDoc = await _posts
        .doc(postId)
        .collection('likes')
        .doc(user.uid)
        .get();

    return likeDoc.exists;
  }

  // ============================================================
  // GET COMMENTS
  // ============================================================

  static Stream<
      List<
          QueryDocumentSnapshot<
              Map<String, dynamic>>>> getComments(
    String postId,
  ) {
    return _posts
        .doc(postId)
        .collection('comments')
        .orderBy(
          'createdAt',
          descending: false,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs,
        );
  }

  // ============================================================
  // ADD COMMENT
  // ============================================================

  static Future<String> addComment({
    required String postId,
    required String text,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'User is not logged in.',
      );
    }

    final cleanText =
        text.trim();

    if (cleanText.isEmpty) {
      throw Exception(
        'Comment cannot be empty.',
      );
    }

    if (cleanText.length > 500) {
      throw Exception(
        'Comment cannot be longer than 500 characters.',
      );
    }

    final postRef =
        _posts.doc(postId);

    final postDoc =
        await postRef.get();

    if (!postDoc.exists) {
      throw Exception(
        'Post not found.',
      );
    }

    final postData =
        postDoc.data() ?? {};

    final receiverUserId =
        postData['userId']
                ?.toString() ??
            '';

    final commentRef = postRef
        .collection('comments')
        .doc();

    final userDoc =
        await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

    final userData =
        userDoc.data() ?? {};

    final username =
        userData['username']
                ?.toString() ??
            user.displayName ??
            'user';

    final userName =
        userData['name']
                ?.toString() ??
            user.displayName ??
            '';

    final userPhotoUrl =
        userData['photoUrl']
                ?.toString() ??
            '';

    // ----------------------------------------------------------
    // CREATE COMMENT
    // ----------------------------------------------------------

    await commentRef.set({
      'userId': user.uid,
      'username': username,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'text': cleanText,
      'createdAt':
          FieldValue.serverTimestamp(),
    });

    // ----------------------------------------------------------
    // UPDATE COMMENT COUNT
    // ----------------------------------------------------------

    try {
      await postRef.update({
        'commentsCount':
            FieldValue.increment(1),
      });
    } catch (e) {
      try {
        await commentRef.delete();
      } catch (_) {}

      throw Exception(
        'Comment count update failed: $e',
      );
    }

    // ----------------------------------------------------------
    // SEND COMMENT NOTIFICATION
    // ----------------------------------------------------------

    if (receiverUserId.isNotEmpty &&
        receiverUserId != user.uid) {
      try {
        await NotificationService
            .createNotification(
          receiverUserId:
              receiverUserId,
          type: 'comment',
          fromUsername:
              username,
          fromUserPhotoUrl:
              userPhotoUrl,
          postId: postId,
          message:
              '$username commented on your post',
        );
      } catch (e) {
        print(
          'COMMENT NOTIFICATION ERROR: $e',
        );
      }
    }

    return commentRef.id;
  }

  // ============================================================
  // DELETE COMMENT
  // ============================================================

  static Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'User is not logged in.',
      );
    }

    final postRef =
        _posts.doc(postId);

    final commentRef = postRef
        .collection('comments')
        .doc(commentId);

    final commentDoc =
        await commentRef.get();

    if (!commentDoc.exists) {
      throw Exception(
        'Comment not found.',
      );
    }

    final commentData =
        commentDoc.data() ?? {};

    if (commentData['userId'] !=
        user.uid) {
      throw Exception(
        'You can only delete your own comment.',
      );
    }

    await commentRef.delete();

    try {
      await postRef.update({
        'commentsCount':
            FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception(
        'Comment deleted, but count update failed: $e',
      );
    }
  }
}
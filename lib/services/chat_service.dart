import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
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

  // ---------------------------------------------------------------------------
  // CREATE OR GET 1-TO-1 CHAT
  // ---------------------------------------------------------------------------

  static Future<String> createOrGetChat({
    required String otherUserId,
  }) async {
    final currentUser = currentUserId;

    if (currentUser == otherUserId) {
      throw Exception('You cannot chat with yourself.');
    }

    final snapshot = await _firestore
        .collection('chats')
        .where(
          'participants',
          arrayContains: currentUser,
        )
        .get();

    for (final doc in snapshot.docs) {
      final participants =
          List<String>.from(doc.data()['participants'] ?? []);

      if (participants.length == 2 &&
          participants.contains(otherUserId)) {
        return doc.id;
      }
    }

    final chatRef = await _firestore.collection('chats').add({
      'participants': [
        currentUser,
        otherUserId,
      ],
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return chatRef.id;
  }

  // ---------------------------------------------------------------------------
  // MY CHATS
  // ---------------------------------------------------------------------------

  static Stream<QuerySnapshot<Map<String, dynamic>>> getMyChats() {
    return _firestore
        .collection('chats')
        .where(
          'participants',
          arrayContains: currentUserId,
        )
        .orderBy(
          'lastMessageTime',
          descending: true,
        )
        .snapshots();
  }

  // ---------------------------------------------------------------------------
  // MESSAGES
  // ---------------------------------------------------------------------------

  static Stream<QuerySnapshot<Map<String, dynamic>>> getMessages(
    String chatId,
  ) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy(
          'timestamp',
          descending: false,
        )
        .snapshots();
  }

  // ---------------------------------------------------------------------------
  // SEND MESSAGE
  // ---------------------------------------------------------------------------

  static Future<void> sendMessage({
    required String chatId,
    required String text,
  }) async {
    final cleanText = text.trim();

    if (cleanText.isEmpty) {
      return;
    }

    final userId = currentUserId;

    final chatRef =
        _firestore.collection('chats').doc(chatId);

    await chatRef.collection('messages').add({
      'senderId': userId,
      'text': cleanText,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await chatRef.update({
      'lastMessage': cleanText,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }
}
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

  // --------------------------------------------------------------------------
  // DETERMINISTIC CHAT ID
  // --------------------------------------------------------------------------

  static String getChatId({
    required String userId1,
    required String userId2,
  }) {
    final ids = [
      userId1,
      userId2,
    ]..sort();

    return '${ids[0]}_${ids[1]}';
  }

  // --------------------------------------------------------------------------
  // CREATE OR GET CHAT
  // --------------------------------------------------------------------------

  static Future<String> createOrGetChat({
    required String otherUserId,
  }) async {
    final currentUser = currentUserId;

    if (currentUser == otherUserId) {
      throw Exception(
        'You cannot chat with yourself.',
      );
    }

    final chatId = getChatId(
      userId1: currentUser,
      userId2: otherUserId,
    );

    final chatRef =
        _firestore.collection('chats').doc(chatId);

    // ------------------------------------------------------------------------
    // CHECK EXISTING CHAT DIRECTLY
    // ------------------------------------------------------------------------

    try {
      final existingChat =
          await chatRef.get();

      if (existingChat.exists) {
        final data =
            existingChat.data();

        if (data != null) {
          final participants =
              List<String>.from(
            data['participants'] ?? [],
          );

          if (participants.length == 2 &&
              participants.contains(currentUser) &&
              participants.contains(otherUserId)) {
            print(
              'Existing chat found: $chatId',
            );

            return chatId;
          }
        }
      }
    } catch (e) {
      print(
        'CHAT DIRECT READ ERROR: $e',
      );

      throw Exception(
        'Unable to access chat: $e',
      );
    }

    // ------------------------------------------------------------------------
    // CREATE CHAT
    // ------------------------------------------------------------------------

    try {
      await chatRef.set({
        'participants': [
          currentUser,
          otherUserId,
        ],
        'lastMessage': '',
        'lastMessageTime':
            FieldValue.serverTimestamp(),
        'lastMessageSenderId': '',
        'unreadCounts': {
          currentUser: 0,
          otherUserId: 0,
        },
        'typingUsers': {
          currentUser: false,
          otherUserId: false,
        },
        'createdAt':
            FieldValue.serverTimestamp(),
      });

      print(
        'NEW CHAT CREATED: $chatId',
      );

      return chatId;
    } catch (e) {
      print(
        'CHAT CREATION ERROR: $e',
      );

      throw Exception(
        'Unable to create new chat: $e',
      );
    }
  }

  // --------------------------------------------------------------------------
  // MY CHATS
  // --------------------------------------------------------------------------

  static Stream<QuerySnapshot<Map<String, dynamic>>>
      getMyChats() {
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

  // --------------------------------------------------------------------------
  // UNREAD COUNT
  // --------------------------------------------------------------------------

  static int getUnreadCount(
    Map<String, dynamic> chatData,
  ) {
    final unreadCounts =
        chatData['unreadCounts'];

    if (unreadCounts is! Map) {
      return 0;
    }

    final value =
        unreadCounts[currentUserId];

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return 0;
  }

  // --------------------------------------------------------------------------
  // TYPING STATUS
  // --------------------------------------------------------------------------

  static Future<void> setTyping({
    required String chatId,
    required bool isTyping,
  }) async {
    final userId = currentUserId;

    final chatRef =
        _firestore
            .collection('chats')
            .doc(chatId);

    final chatSnapshot =
        await chatRef.get();

    if (!chatSnapshot.exists) {
      return;
    }

    final chatData =
        chatSnapshot.data();

    if (chatData == null) {
      return;
    }

    final participants =
        List<String>.from(
      chatData['participants'] ?? [],
    );

    if (!participants.contains(userId)) {
      throw Exception(
        'You are not a participant in this chat.',
      );
    }

    await chatRef.update({
      'typingUsers.$userId': isTyping,
    });
  }

  // --------------------------------------------------------------------------
  // GET TYPING USERS
  // --------------------------------------------------------------------------

  static Stream<Map<String, bool>>
      getTypingUsers(
    String chatId,
  ) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .snapshots()
        .map((snapshot) {
      final data =
          snapshot.data();

      if (data == null) {
        return <String, bool>{};
      }

      final rawTypingUsers =
          data['typingUsers'];

      if (rawTypingUsers is! Map) {
        return <String, bool>{};
      }

      final result =
          <String, bool>{};

      rawTypingUsers.forEach(
        (key, value) {
          if (key is String &&
              value is bool) {
            result[key] = value;
          }
        },
      );

      return result;
    });
  }

  // --------------------------------------------------------------------------
  // GET MESSAGES
  // --------------------------------------------------------------------------

  static Stream<QuerySnapshot<Map<String, dynamic>>>
      getMessages(
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

  // --------------------------------------------------------------------------
  // SEND MESSAGE
  // --------------------------------------------------------------------------

  static Future<void> sendMessage({
    required String chatId,
    required String text,
  }) async {
    final cleanText =
        text.trim();

    if (cleanText.isEmpty) {
      return;
    }

    final userId =
        currentUserId;

    final chatRef =
        _firestore
            .collection('chats')
            .doc(chatId);

    final chatSnapshot =
        await chatRef.get();

    if (!chatSnapshot.exists) {
      throw Exception(
        'Chat does not exist.',
      );
    }

    final chatData =
        chatSnapshot.data();

    if (chatData == null) {
      throw Exception(
        'Unable to read chat.',
      );
    }

    final participants =
        List<String>.from(
      chatData['participants'] ?? [],
    );

    if (!participants.contains(userId)) {
      throw Exception(
        'You are not a participant in this chat.',
      );
    }

    String? receiverId;

    for (final participantId
        in participants) {
      if (participantId != userId) {
        receiverId =
            participantId;
        break;
      }
    }

    if (receiverId == null ||
        receiverId.isEmpty) {
      throw Exception(
        'Unable to determine message receiver.',
      );
    }

    final currentUnreadCounts =
        Map<String, dynamic>.from(
      chatData['unreadCounts'] ?? {},
    );

    final currentReceiverUnread =
        currentUnreadCounts[
                    receiverId] is num
            ? (currentUnreadCounts[
                    receiverId] as num)
                .toInt()
            : 0;

    final batch =
        _firestore.batch();

    final messageRef =
        chatRef
            .collection('messages')
            .doc();

    batch.set(
      messageRef,
      {
        'senderId': userId,
        'text': cleanText,
        'timestamp':
            FieldValue.serverTimestamp(),
        'isRead': false,
        'readAt': null,
      },
    );

    batch.update(
      chatRef,
      {
        'lastMessage': cleanText,
        'lastMessageTime':
            FieldValue.serverTimestamp(),
        'lastMessageSenderId':
            userId,
        'unreadCounts': {
          userId: 0,
          receiverId:
              currentReceiverUnread + 1,
        },
        'typingUsers.$userId':
            false,
      },
    );

    await batch.commit();
  }

  // --------------------------------------------------------------------------
  // MARK CHAT AS READ
  // --------------------------------------------------------------------------

  static Future<void> markChatAsRead(
    String chatId,
  ) async {
    final userId =
        currentUserId;

    final chatRef =
        _firestore
            .collection('chats')
            .doc(chatId);

    final chatSnapshot =
        await chatRef.get();

    if (!chatSnapshot.exists) {
      return;
    }

    final chatData =
        chatSnapshot.data();

    if (chatData == null) {
      return;
    }

    final participants =
        List<String>.from(
      chatData['participants'] ?? [],
    );

    if (!participants.contains(userId)) {
      throw Exception(
        'You are not a participant in this chat.',
      );
    }

    final unreadCounts =
        Map<String, dynamic>.from(
      chatData['unreadCounts'] ?? {},
    );

    final currentUnread =
        unreadCounts[userId];

    final unreadNumber =
        currentUnread is num
            ? currentUnread.toInt()
            : 0;

    if (unreadNumber == 0) {
      return;
    }

    final batch =
        _firestore.batch();

    batch.update(
      chatRef,
      {
        'unreadCounts.$userId': 0,
      },
    );

    final messagesSnapshot =
        await chatRef
            .collection('messages')
            .where(
              'senderId',
              isNotEqualTo: userId,
            )
            .get();

    final readAt =
        FieldValue.serverTimestamp();

    for (final message
        in messagesSnapshot.docs) {
      final data =
          message.data();

      final isRead =
          data['isRead'] == true;

      if (!isRead) {
        batch.update(
          message.reference,
          {
            'isRead': true,
            'readAt': readAt,
          },
        );
      }
    }

    await batch.commit();
  }
}
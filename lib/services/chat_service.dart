import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'notification_service.dart';

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

  static String getChatId({
    required String userId1,
    required String userId2,
  }) {
    final ids = [userId1, userId2]..sort();

    return '${ids[0]}_${ids[1]}';
  }

  static Future<String> createOrGetChat({
    required String otherUserId,
  }) async {
    try {
      final myUid = currentUserId;

      if (myUid == otherUserId) {
        throw Exception(
          'You cannot create a chat with yourself.',
        );
      }

      final chatId = getChatId(
        userId1: myUid,
        userId2: otherUserId,
      );

      final chatRef =
          _firestore.collection('chats').doc(chatId);

      try {
        final snapshot = await chatRef.get();

        if (snapshot.exists) {
          final data = snapshot.data();

          if (data != null) {
            final participants =
                data['participants'];

            if (participants is List &&
                participants.contains(myUid) &&
                participants.contains(otherUserId)) {
              return chatId;
            }
          }

          throw Exception(
            'Invalid chat participants.',
          );
        }
      } on FirebaseException catch (e) {
        // Permission errors are converted into a user-facing exception below.


        if (e.code != 'permission-denied') {
          rethrow;
        }

        throw Exception(
          'Unable to access chat: '
          '${e.message ?? e.code}',
        );
      }

      final now =
          FieldValue.serverTimestamp();

      await chatRef.set({
        'participants': [
          myUid,
          otherUserId,
        ],
        'lastMessage': '',
        'lastMessageTime': now,
        'lastMessageSenderId': '',
        'unreadCounts': {
          myUid: 0,
          otherUserId: 0,
        },
        'typingUsers': {
          myUid: 'none',
          otherUserId: 'none',
        },
        'createdAt': now,
      });

      return chatId;
    } catch (_) {
      rethrow;
    }
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>>
      getMyChats() {
    return _firestore
        .collection('chats')
        .where(
          'participants',
          arrayContains: currentUserId,
        )
        .snapshots();
  }

  static int getUnreadCount(
    Map<String, dynamic> data,
  ) {
    final unreadCounts =
        data['unreadCounts'];

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

  // ---------------------------------------------------------------------------
  // TYPING / THINKING
  // ---------------------------------------------------------------------------

  static Future<void> setTyping({
    required String chatId,
    required bool isTyping,
  }) async {
    await setTypingState(
      chatId: chatId,
      state: isTyping ? 'typing' : 'none',
    );
  }

  static Future<void> setTypingState({
    required String chatId,
    required String state,
  }) async {
    final uid = currentUserId;

    final validState =
        state == 'typing' ||
        state == 'thinking'
            ? state
            : 'none';

    await _firestore
        .collection('chats')
        .doc(chatId)
        .update({
      'typingUsers.$uid': validState,
    });
  }

  static Stream<Map<String, String>>
      getTypingUsers(
    String chatId,
  ) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .snapshots()
        .map(
      (snapshot) {
        if (!snapshot.exists) {
          return <String, String>{};
        }

        final data =
            snapshot.data();

        if (data == null) {
          return <String, String>{};
        }

        final typingUsers =
            data['typingUsers'];

        if (typingUsers is! Map) {
          return <String, String>{};
        }

        final result =
            <String, String>{};

        typingUsers.forEach(
          (key, value) {
            if (key is! String) {
              return;
            }

            // New format:
            // "typing"
            // "thinking"
            // "none"
            if (value is String) {
              if (value == 'typing' ||
                  value == 'thinking') {
                result[key] = value;
              } else {
                result[key] = 'none';
              }

              return;
            }

            // Backward compatibility with old bool format.
            if (value is bool) {
              result[key] =
                  value ? 'typing' : 'none';
            }
          },
        );

        return result;
      },
    );
  }

  // ---------------------------------------------------------------------------
  // MESSAGES
  // ---------------------------------------------------------------------------

  static Stream<
      QuerySnapshot<Map<String, dynamic>>>
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

  static Future<void> sendMessage({
    required String chatId,
    required String text,
  }) async {
    final uid = currentUserId;

    final trimmedText =
        text.trim();

    if (trimmedText.isEmpty) {
      return;
    }

    if (trimmedText.length > 500) {
      throw Exception(
        'Message cannot exceed 500 characters.',
      );
    }

    final chatRef =
        _firestore
            .collection('chats')
            .doc(chatId);

    final messageRef =
        chatRef
            .collection('messages')
            .doc();

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
        'Chat data is unavailable.',
      );
    }

    final participants =
        chatData['participants'];

    if (participants is! List ||
        !participants.contains(uid)) {
      throw Exception(
        'You are not a participant in this chat.',
      );
    }

    String? otherUserId;

    for (final participant
        in participants) {
      if (participant is String &&
          participant != uid) {
        otherUserId =
            participant;
        break;
      }
    }

    if (otherUserId == null) {
      throw Exception(
        'Other chat participant not found.',
      );
    }

    final unreadCounts =
        Map<String, dynamic>.from(
      chatData['unreadCounts'] ?? {},
    );

    final currentOtherUnread =
        unreadCounts[otherUserId] is num
            ? (unreadCounts[
                    otherUserId] as num)
                .toInt()
            : 0;

    unreadCounts[otherUserId] =
        currentOtherUnread + 1;

    unreadCounts[uid] =
        unreadCounts[uid] is num
            ? (unreadCounts[uid] as num)
                .toInt()
            : 0;

    final batch =
        _firestore.batch();

    batch.set(
      messageRef,
      {
        'senderId': uid,
        'text': trimmedText,
        'timestamp':
            FieldValue.serverTimestamp(),
        'isRead': false,
        'readAt': null,
      },
    );

    batch.update(
      chatRef,
      {
        'lastMessage':
            trimmedText,
        'lastMessageTime':
            FieldValue.serverTimestamp(),
        'lastMessageSenderId':
            uid,
        'unreadCounts':
            unreadCounts,
        'typingUsers.$uid':
            'none',
      },
    );

    await batch.commit();

    // Message is already safely stored.
    // Notification failure must never make
    // the message appear to have failed.
    try {
      await NotificationService
          .createMessageNotification(
        receiverUserId:
            otherUserId,
        chatId: chatId,
        message: trimmedText,
      );
    } catch (_) {
      // Notification failure must not undo a successfully sent message.
    }
  }

  // ---------------------------------------------------------------------------
  // MARK CHAT AS READ
  // ---------------------------------------------------------------------------

  static Future<void> markChatAsRead(
    String chatId,
  ) async {
    final uid = currentUserId;

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
        chatData['participants'];

    if (participants is! List ||
        !participants.contains(uid)) {
      return;
    }

    final batch =
        _firestore.batch();

    final unreadCounts =
        Map<String, dynamic>.from(
      chatData['unreadCounts'] ?? {},
    );

    unreadCounts[uid] = 0;

    batch.update(
      chatRef,
      {
        'unreadCounts':
            unreadCounts,
      },
    );

    final messagesSnapshot =
        await chatRef
            .collection('messages')
            .where(
              'isRead',
              isEqualTo: false,
            )
            .get();

    for (final messageDoc
        in messagesSnapshot.docs) {
      final messageData =
          messageDoc.data();

      final senderId =
          messageData['senderId'];

      if (senderId != uid) {
        batch.update(
          messageDoc.reference,
          {
            'isRead': true,
            'readAt':
                FieldValue.serverTimestamp(),
          },
        );
      }
    }

    await batch.commit();

    // Opening a chat also clears
    // message notifications for this chat.
    try {
      await NotificationService
          .markChatNotificationsAsRead(
        chatId,
      );
    } catch (_) {
      // Notification read-state failure must not undo chat read-state changes.
    }
  }
}
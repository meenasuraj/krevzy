import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream messages for a specific chat
  Stream<QuerySnapshot<Map<String, dynamic>>> getMessages(String chatRoomId) {
    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Send a message
  Future<void> sendMessage(String receiverId, String messageText) async {
    final String currentUserId = _auth.currentUser?.uid ?? '';
    if (currentUserId.isEmpty || messageText.trim().isEmpty) return;

    List<String> ids = [currentUserId, receiverId]..sort();
    String chatRoomId = ids.join('_');

    final Timestamp timestamp = Timestamp.now();

    // Add message to chat room
    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add({
      'senderId': currentUserId,
      'receiverId': receiverId,
      'text': messageText.trim(),
      'timestamp': timestamp,
      'isRead': false,
    });

    // Update main chat metadata
    await _firestore.collection('chats').doc(chatRoomId).set({
      'participants': [currentUserId, receiverId],
      'lastMessage': messageText.trim(),
      'lastMessageTime': timestamp,
      'unreadCount_$receiverId': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  // Mark chat as read
  Future<void> markChatAsRead(String chatRoomId) async {
    final String currentUserId = _auth.currentUser?.uid ?? '';
    if (currentUserId.isEmpty) return;

    await _firestore.collection('chats').doc(chatRoomId).set({
      'unreadCount_$currentUserId': 0,
    }, SetOptions(merge: true));
  }

  // Set typing indicator state
  Future<void> setTypingState(String chatRoomId, bool isTyping) async {
    final String currentUserId = _auth.currentUser?.uid ?? '';
    if (currentUserId.isEmpty) return;

    await _firestore.collection('chat_rooms').doc(chatRoomId).set({
      'typing_$currentUserId': isTyping,
    }, SetOptions(merge: true));
  }

  // Stream typing users
  Stream<DocumentSnapshot<Map<String, dynamic>>> getTypingUsers(String chatRoomId) {
    return _firestore.collection('chat_rooms').doc(chatRoomId).snapshots();
  }

  // Stream list of active user chats
  Stream<QuerySnapshot<Map<String, dynamic>>> getMyChats() {
    final String currentUserId = _auth.currentUser?.uid ?? '';
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .snapshots();
  }

  // Get unread count for current user
  Stream<DocumentSnapshot<Map<String, dynamic>>> getUnreadCount(String chatRoomId) {
    return _firestore.collection('chats').doc(chatRoomId).snapshots();
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class CallService {
  CallService._();
  static final CallService instance = CallService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('User is not logged in.');
    return uid;
  }

  Future<String> createCall({
    required String calleeId,
    required String type,
    required String callerName,
  }) async {
    if (calleeId.isEmpty || calleeId == _uid) {
      throw ArgumentError('Invalid call recipient.');
    }
    if (type != 'audio' && type != 'video') {
      throw ArgumentError('Invalid call type.');
    }

    final ref = _firestore.collection('calls').doc();
    await ref.set({
      'callerId': _uid,
      'calleeId': calleeId,
      'callerName': callerName,
      'type': type,
      'status': 'ringing',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  DocumentReference<Map<String, dynamic>> callRef(String callId) =>
      _firestore.collection('calls').doc(callId);

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchCall(String callId) =>
      callRef(callId).snapshots();

  Future<Map<String, dynamic>?> getCall(String callId) async =>
      (await callRef(callId).get()).data();

  Future<void> acceptCall(String callId) async {
    final snap = await callRef(callId).get();
    final data = snap.data();
    if (data == null || data['calleeId'] != _uid) {
      throw StateError('You are not the recipient of this call.');
    }
    await callRef(callId).update({
      'status': 'accepted',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setOffer(String callId, RTCSessionDescription description) async {
    await callRef(callId).update({
      'offer': {'type': description.type, 'sdp': description.sdp},
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setAnswer(String callId, RTCSessionDescription description) async {
    await callRef(callId).update({
      'answer': {'type': description.type, 'sdp': description.sdp},
      'status': 'connected',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> endCall(String callId) async {
    try {
      final snap = await callRef(callId).get();
      if (!snap.exists) return;
      final data = snap.data();
      if (data == null || (data['callerId'] != _uid && data['calleeId'] != _uid)) return;
      await callRef(callId).update({
        'status': 'ended',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // The local call screen should still close if signaling cleanup fails.
    }
  }

  CollectionReference<Map<String, dynamic>> candidatesRef(
    String callId,
    bool caller,
  ) => callRef(callId).collection(caller ? 'callerCandidates' : 'calleeCandidates');

  Future<void> addCandidate({
    required String callId,
    required bool caller,
    required RTCIceCandidate candidate,
  }) async {
    await candidatesRef(callId, caller).add({
      'candidate': candidate.candidate,
      'sdpMid': candidate.sdpMid,
      'sdpMLineIndex': candidate.sdpMLineIndex,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchCandidates({
    required String callId,
    required bool caller,
  }) => candidatesRef(callId, !caller).snapshots();
}

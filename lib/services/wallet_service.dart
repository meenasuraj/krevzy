import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WalletService {
  WalletService._();

  static final WalletService instance = WalletService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('User is not logged in.');
    }

    return user.uid;
  }

  DocumentReference<Map<String, dynamic>> get _walletRef {
    return _firestore.collection('wallets').doc(_uid);
  }

  CollectionReference<Map<String, dynamic>> get _transactionsRef {
    return _walletRef.collection('transactions');
  }

  /// Reads the current user's wallet.
  Future<DocumentSnapshot<Map<String, dynamic>>> getWallet() async {
    return _walletRef.get();
  }

  /// Wallet creation remains backend-controlled.
  Future<void> ensureWallet() async {
    final snapshot = await _walletRef.get();

    if (snapshot.exists) {
      return;
    }

    throw StateError('Wallet has not been created by the trusted backend yet.');
  }

  /// Real-time wallet stream.
  Stream<DocumentSnapshot<Map<String, dynamic>>> walletStream() {
    return _walletRef.snapshots();
  }

  /// Returns the wallet balance.
  Future<double> getBalance() async {
    final snapshot = await _walletRef.get();

    if (!snapshot.exists) {
      return 0;
    }

    final data = snapshot.data();

    if (data == null) {
      return 0;
    }

    final value = data['balance'];

    if (value is num) {
      return value.toDouble();
    }

    return 0;
  }

  /// Real-time balance stream.
  Stream<double> balanceStream() {
    return _walletRef.snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return 0;
      }

      final data = snapshot.data();

      if (data == null) {
        return 0;
      }

      final value = data['balance'];

      if (value is num) {
        return value.toDouble();
      }

      return 0;
    });
  }

  /// Creates a pending wallet top-up request.
  ///
  /// IMPORTANT:
  /// This does NOT add money to the wallet.
  Future<String> createPendingTopUp({
    required double amount,
    String provider = 'upi',
  }) async {
    if (amount <= 0) {
      throw ArgumentError('Amount must be greater than zero.');
    }

    if (amount > 100000) {
      throw ArgumentError('Maximum top-up amount for this flow is ₹100,000.');
    }

    final uid = _uid;

    final topUpRef = _firestore.collection('walletTopups').doc();

    final clientReference =
        'KREVZY-${DateTime.now().millisecondsSinceEpoch}-${topUpRef.id.substring(0, 8)}';

    await topUpRef.set({
      'userId': uid,
      'amount': amount,
      'currency': 'INR',
      'status': 'pending',
      'provider': provider,
      'clientReference': clientReference,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return topUpRef.id;
  }

  /// Reads one top-up request.
  Future<DocumentSnapshot<Map<String, dynamic>>> getTopUp(
    String topUpId,
  ) async {
    return _firestore.collection('walletTopups').doc(topUpId).get();
  }

  /// Returns the user's transaction history.
  Stream<QuerySnapshot<Map<String, dynamic>>> transactionsStream({
    int limit = 50,
  }) {
    return _transactionsRef
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  /// Reads transaction history once.
  Future<QuerySnapshot<Map<String, dynamic>>> getTransactions({
    int limit = 50,
  }) async {
    return _transactionsRef
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
  }
}

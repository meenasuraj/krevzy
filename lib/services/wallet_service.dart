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

  // ============================================================
  // WALLET
  // ============================================================

  DocumentReference<Map<String, dynamic>> get _walletRef {
    return _firestore.collection('wallets').doc(_uid);
  }

  CollectionReference<Map<String, dynamic>> get _transactionsRef {
    return _walletRef.collection('transactions');
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getWallet() async {
    return _walletRef.get();
  }

  Future<void> ensureWallet() async {
    final snapshot = await _walletRef.get();

    if (snapshot.exists) {
      return;
    }

    throw StateError(
      'Wallet has not been created by '
      'the trusted backend yet.',
    );
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> walletStream() {
    return _walletRef.snapshots();
  }

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

  // ============================================================
  // PAYMENT SETUP REFERENCE
  //
  // users/{uid}/paymentMethods/setup
  //
  // This document contains only safe state information.
  // NEVER put the full bank account number here.
  // ============================================================

  DocumentReference<Map<String, dynamic>> get _paymentSetupRef {
    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('paymentMethods')
        .doc('setup');
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> paymentSetupStream() {
    return _paymentSetupRef.snapshots();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getPaymentSetup() async {
    return _paymentSetupRef.get();
  }

  // ============================================================
  // BANK ACCOUNT
  // ============================================================

  Future<void> saveBankAccountForVerification({
    required String accountHolderName,
    required String bankName,
    required String accountNumber,
    required String ifsc,
  }) async {
    final uid = _uid;

    final cleanHolderName = accountHolderName.trim();
    final cleanBankName = bankName.trim();
    final cleanAccountNumber = accountNumber.trim();
    final cleanIfsc = ifsc.trim().toUpperCase();

    if (cleanHolderName.isEmpty) {
      throw ArgumentError('Account holder name is required.');
    }

    if (cleanBankName.isEmpty) {
      throw ArgumentError('Bank name is required.');
    }

    if (cleanAccountNumber.length < 6) {
      throw ArgumentError('Invalid bank account number.');
    }

    if (!_isValidIfsc(cleanIfsc)) {
      throw ArgumentError('Invalid IFSC code.');
    }

    final last4 = cleanAccountNumber.length >= 4
        ? cleanAccountNumber.substring(cleanAccountNumber.length - 4)
        : cleanAccountNumber;

    /*
     * IMPORTANT:
     *
     * The complete account number is deliberately NOT stored
     * in Firestore.
     *
     * A trusted backend/payment verification provider should
     * receive the actual bank details and perform verification.
     */

    await _paymentSetupRef.set({
      'userId': uid,

      'bank': {
        'accountHolderName': cleanHolderName,
        'bankName': cleanBankName,
        'maskedAccountNumber': '•••• $last4',
        'accountLast4': last4,
        'ifsc': cleanIfsc,

        'status': 'pending',

        'verificationRequestedAt': FieldValue.serverTimestamp(),

        'verifiedAt': null,
        'verificationProvider': null,
        'verificationReference': null,
      },

      // Adding/changing the bank resets UPI/payment eligibility.
      'upi': {
        'status': 'locked',
        'upiId': null,
        'verifiedAt': null,
        'verificationReference': null,
      },

      'paymentEnabled': false,

      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getBankAccount() async {
    final snapshot = await _paymentSetupRef.get();

    if (!snapshot.exists) {
      return null;
    }

    final data = snapshot.data();

    if (data == null) {
      return null;
    }

    final bank = data['bank'];

    if (bank is Map<String, dynamic>) {
      return bank;
    }

    if (bank is Map) {
      return Map<String, dynamic>.from(bank);
    }

    return null;
  }

  Stream<String> bankStatusStream() {
    return _paymentSetupRef.snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return 'not_added';
      }

      final data = snapshot.data();

      if (data == null) {
        return 'not_added';
      }

      final bank = data['bank'];

      if (bank is Map) {
        return bank['status']?.toString() ?? 'not_added';
      }

      return 'not_added';
    });
  }

  Future<String> getBankStatus() async {
    final bank = await getBankAccount();

    if (bank == null) {
      return 'not_added';
    }

    return bank['status']?.toString() ?? 'not_added';
  }

  bool _isValidIfsc(String value) {
    final regex = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');
    return regex.hasMatch(value);
  }

  // ============================================================
  // BANK VERIFICATION STATUS
  //
  // IMPORTANT:
  // The client must NOT mark the bank as verified.
  //
  // A trusted backend/provider must update:
  //
  // bank.status = verified
  //
  // and provide verificationReference.
  // ============================================================

  Future<bool> isBankVerified() async {
    final status = await getBankStatus();
    return status == 'verified';
  }

  // ============================================================
  // UPI
  // ============================================================

  Future<void> addUpiId({required String upiId}) async {
    final bankVerified = await isBankVerified();

    if (!bankVerified) {
      throw StateError('Bank account must be verified before adding UPI ID.');
    }

    final cleanUpi = upiId.trim().toLowerCase();

    if (!_isValidUpiId(cleanUpi)) {
      throw ArgumentError('Please enter a valid UPI ID.');
    }

    await _paymentSetupRef.set({
      'upi': {
        'upiId': cleanUpi,
        'status': 'pending',
        'verificationRequestedAt': FieldValue.serverTimestamp(),
        'verifiedAt': null,
        'verificationReference': null,
      },

      'paymentEnabled': false,

      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getUpiAccount() async {
    final snapshot = await _paymentSetupRef.get();

    if (!snapshot.exists) {
      return null;
    }

    final data = snapshot.data();

    if (data == null) {
      return null;
    }

    final upi = data['upi'];

    if (upi is Map<String, dynamic>) {
      return upi;
    }

    if (upi is Map) {
      return Map<String, dynamic>.from(upi);
    }

    return null;
  }

  Future<String> getUpiStatus() async {
    final upi = await getUpiAccount();

    if (upi == null) {
      return 'not_added';
    }

    return upi['status']?.toString() ?? 'not_added';
  }

  Stream<String> upiStatusStream() {
    return _paymentSetupRef.snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return 'not_added';
      }

      final data = snapshot.data();

      if (data == null) {
        return 'not_added';
      }

      final upi = data['upi'];

      if (upi is Map) {
        return upi['status']?.toString() ?? 'not_added';
      }

      return 'not_added';
    });
  }

  bool _isValidUpiId(String value) {
    final regex = RegExp(r'^[a-zA-Z0-9._-]{2,}@[a-zA-Z0-9._-]{2,}$');

    return regex.hasMatch(value);
  }

  // ============================================================
  // PAYMENT ELIGIBILITY
  // ============================================================

  Future<bool> canMakePayment() async {
    final snapshot = await _paymentSetupRef.get();

    if (!snapshot.exists) {
      return false;
    }

    final data = snapshot.data();

    if (data == null) {
      return false;
    }

    final bank = data['bank'];
    final upi = data['upi'];

    if (bank is! Map || upi is! Map) {
      return false;
    }

    final bankStatus = bank['status']?.toString() ?? '';

    final upiStatus = upi['status']?.toString() ?? '';

    return bankStatus == 'verified' && upiStatus == 'verified';
  }

  Stream<bool> paymentEligibilityStream() {
    return _paymentSetupRef.snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return false;
      }

      final data = snapshot.data();

      if (data == null) {
        return false;
      }

      final bank = data['bank'];
      final upi = data['upi'];

      if (bank is! Map || upi is! Map) {
        return false;
      }

      return bank['status'] == 'verified' && upi['status'] == 'verified';
    });
  }

  // ============================================================
  // PAYMENT
  //
  // This only creates a pending payment request.
  // Actual payment confirmation must come from the trusted
  // backend/payment provider.
  // ============================================================

  Future<String> createPendingPayment({
    required double amount,
    String provider = 'upi',
  }) async {
    if (amount <= 0) {
      throw ArgumentError('Amount must be greater than zero.');
    }

    if (amount > 100000) {
      throw ArgumentError('Maximum payment amount is ₹100,000.');
    }

    final allowed = await canMakePayment();

    if (!allowed) {
      throw StateError(
        'Please verify your bank account and UPI ID '
        'before making a payment.',
      );
    }

    final uid = _uid;

    final setup = await getPaymentSetup();

    final upi = setup['upi'];

    if (upi is! Map) {
      throw StateError('Verified UPI ID not found.');
    }

    final upiId = upi['upiId']?.toString();

    if (upiId == null || upiId.isEmpty) {
      throw StateError('Verified UPI ID not found.');
    }

    final paymentRef = _firestore.collection('payments').doc();

    final clientReference =
        'KREVZY-PAY-'
        '${DateTime.now().millisecondsSinceEpoch}-'
        '${paymentRef.id.substring(0, 8)}';

    await paymentRef.set({
      'userId': uid,
      'amount': amount,
      'currency': 'INR',

      'provider': provider,

      'upiId': upiId,

      'status': 'pending',

      'clientReference': clientReference,

      'createdAt': FieldValue.serverTimestamp(),
    });

    return paymentRef.id;
  }

  // ============================================================
  // WALLET TOP-UP
  // ============================================================

  Future<String> createPendingTopUp({
    required double amount,
    String provider = 'upi',
  }) async {
    if (amount <= 0) {
      throw ArgumentError('Amount must be greater than zero.');
    }

    if (amount > 100000) {
      throw ArgumentError('Maximum top-up amount is ₹100,000.');
    }

    final uid = _uid;

    final topUpRef = _firestore.collection('walletTopups').doc();

    final clientReference =
        'KREVZY-'
        '${DateTime.now().millisecondsSinceEpoch}-'
        '${topUpRef.id.substring(0, 8)}';

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

  Future<DocumentSnapshot<Map<String, dynamic>>> getTopUp(
    String topUpId,
  ) async {
    return _firestore.collection('walletTopups').doc(topUpId).get();
  }

  // ============================================================
  // TRANSACTIONS
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> transactionsStream({
    int limit = 50,
  }) {
    return _transactionsRef
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getTransactions({
    int limit = 50,
  }) async {
    return _transactionsRef
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
  }
}

import 'dart:async';
import 'dart:math';

import '../models/krevzy_payment.dart';

class KrevzyMockPaymentService {
  KrevzyMockPaymentService._();

  static final KrevzyMockPaymentService instance = KrevzyMockPaymentService._();

  final Random _random = Random();

  Future<KrevzyPayment> create({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String receiverName,
    required double amount,
    String note = '',
    KrevzyPaymentStatus outcome = KrevzyPaymentStatus.success,
  }) async {
    final now = DateTime.now();

    final payment = KrevzyPayment(
      id: 'mock_${now.microsecondsSinceEpoch}',
      chatId: chatId,
      senderId: senderId,
      receiverId: receiverId,
      receiverName: receiverName,
      amount: amount,
      currency: 'INR',
      status: KrevzyPaymentStatus.processing,
      note: note,
      transactionRef: 'KREVZY-TEST-${now.millisecondsSinceEpoch}',
      createdAt: now,
      updatedAt: now,
    );

    await Future<void>.delayed(
      Duration(milliseconds: 700 + _random.nextInt(500)),
    );

    return payment.copyWith(status: outcome, updatedAt: DateTime.now());
  }
}

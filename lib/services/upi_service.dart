import 'package:flutter/material.dart';
import 'package:upi_india/upi_india.dart';

class UpiService {
  final UpiIndia _upiIndia = UpiIndia();

  Future<List<UpiApp>> getInstalledApps() async {
    try {
      return await _upiIndia.getAllUpiApps();
    } catch (e) {
      debugPrint('Error fetching UPI apps: $e');
      return [];
    }
  }

  Future<UpiResponse?> startTransaction({
    required UpiApp app,
    required String receiverUpiId,
    required String receiverName,
    required double amount,
  }) async {
    try {
      return await _upiIndia.startTransaction(
        app: app,
        receiverUpiId: receiverUpiId,
        receiverName: receiverName,
        transactionRefId: 'TXN${DateTime.now().millisecondsSinceEpoch}',
        transactionNote: 'KREVZY App Payment',
        amount: amount,
      );
    } catch (e) {
      debugPrint('Transaction Error: $e');
      return null;
    }
  }
}

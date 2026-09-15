import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class UpiApp {
  final String name;
  final String packageName;

  const UpiApp({required this.name, required this.packageName});
}

class UpiResponse {
  final String status;
  final String? response;
  final int? resultCode;

  const UpiResponse({required this.status, this.response, this.resultCode});

  String get normalizedStatus => status.trim().toLowerCase();

  bool get isSuccess => normalizedStatus == 'success';

  bool get isSubmitted => normalizedStatus == 'submitted';

  bool get isPending => normalizedStatus == 'pending';

  bool get isFailure =>
      normalizedStatus == 'failure' || normalizedStatus == 'failed';

  bool get isCancelled =>
      normalizedStatus == 'cancelled' || normalizedStatus == 'canceled';

  bool get isUnknown => normalizedStatus == 'unknown';

  @override
  String toString() {
    return 'UpiResponse('
        'status: $status, '
        'response: $response, '
        'resultCode: $resultCode'
        ')';
  }
}

class UpiService {
  UpiService._();

  static final UpiService instance = UpiService._();

  static const MethodChannel _channel = MethodChannel('com.krevzy/upi');

  Future<List<UpiApp>> getInstalledApps() async {
    if (kIsWeb) {
      return const [];
    }

    /*
     * Native Android UPI chooser is responsible
     * for showing compatible installed UPI apps.
     *
     * We intentionally do not hard-code:
     * Google Pay
     * PhonePe
     * Paytm
     *
     * because installed apps differ by device.
     */
    return const [];
  }

  Future<UpiResponse> startTransaction({
    required String amount,
    required String receiverName,
    required String receiverUpiId,
    required String transactionRef,
    String transactionNote = 'KREVZY Wallet Top Up',
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('UPI payments are available on Android only.');
    }

    final cleanAmount = double.tryParse(amount);

    if (cleanAmount == null || cleanAmount <= 0) {
      throw ArgumentError('Invalid payment amount.');
    }

    if (receiverUpiId.trim().isEmpty) {
      throw ArgumentError('KREVZY UPI ID is not configured.');
    }

    if (transactionRef.trim().isEmpty) {
      throw ArgumentError('Transaction reference is required.');
    }

    try {
      final result = await _channel.invokeMethod<dynamic>(
        'launchUpi',
        <String, dynamic>{
          'amount': cleanAmount.toStringAsFixed(2),
          'receiverName': receiverName.trim(),
          'receiverUpiId': receiverUpiId.trim(),
          'transactionRef': transactionRef.trim(),
          'transactionNote': transactionNote.trim(),
        },
      );

      if (result is Map) {
        return UpiResponse(
          status: (result['status'] ?? 'unknown').toString(),
          response: result['response']?.toString(),
          resultCode: result['resultCode'] is int
              ? result['resultCode'] as int
              : null,
        );
      }

      return const UpiResponse(status: 'unknown');
    } on PlatformException catch (e) {
      throw Exception(e.message ?? 'Unable to start UPI payment.');
    } on MissingPluginException {
      throw Exception(
        'Native UPI integration is not available '
        'on this Android build.',
      );
    }
  }
}

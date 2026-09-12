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

  bool get isSuccess => status.toLowerCase() == 'success';

  bool get isSubmitted => status.toLowerCase() == 'submitted';

  bool get isPending => status.toLowerCase() == 'pending';

  bool get isFailure => status.toLowerCase() == 'failure';

  bool get isCancelled => status.toLowerCase() == 'cancelled';

  bool get isUnknown => status.toLowerCase() == 'unknown';

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

  /// Native UPI intent does not reliably expose
  /// a complete installed-app list.
  ///
  /// Therefore the app selection UI should not depend
  /// on this method for payment functionality.
  ///
  /// We return a small fallback list so existing UI
  /// can continue working if it calls getInstalledApps().
  Future<List<UpiApp>> getInstalledApps() async {
    if (kIsWeb) {
      return const [];
    }

    return const [UpiApp(name: 'UPI', packageName: 'native_upi')];
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

    try {
      final result = await _channel.invokeMethod<dynamic>(
        'launchUpi',
        <String, dynamic>{
          'amount': cleanAmount.toStringAsFixed(2),
          'receiverName': receiverName,
          'receiverUpiId': receiverUpiId,
          'transactionRef': transactionRef,
          'transactionNote': transactionNote,
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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_upi_india/flutter_upi_india.dart' as upi;

class UpiApp {
  final upi.ApplicationMeta _meta;

  const UpiApp._(this._meta);

  String get name => _meta.upiApplication.getAppName();

  String get packageName => _meta.packageName;

  Widget iconWidget(double size) {
    return _meta.iconImage(size);
  }

  upi.UpiApplication get application => _meta.upiApplication;
}

class UpiResponse {
  final String? status;

  const UpiResponse({required this.status});

  factory UpiResponse.fromPluginResponse(upi.UpiTransactionResponse response) {
    return UpiResponse(
      status: response.status.toString().split('.').last.toLowerCase(),
    );
  }

  @override
  String toString() {
    return 'UpiResponse(status: $status)';
  }
}

class UpiService {
  Future<List<UpiApp>> getInstalledApps() async {
    if (kIsWeb) {
      debugPrint('KREVZY UPI is not supported on Web.');
      return <UpiApp>[];
    }

    try {
      final List<upi.ApplicationMeta> apps =
          await upi.UpiPay.getInstalledUpiApplications(
            statusType: upi.UpiApplicationDiscoveryAppStatusType.all,
          );

      return apps.map((app) => UpiApp._(app)).toList(growable: false);
    } catch (e, stackTrace) {
      debugPrint('KREVZY UPI app discovery error: $e');
      debugPrintStack(stackTrace: stackTrace);

      return <UpiApp>[];
    }
  }

  Future<UpiResponse?> startTransaction({
    required UpiApp app,
    required String receiverUpiId,
    required String receiverName,
    required double amount,
  }) async {
    if (kIsWeb) {
      debugPrint('KREVZY UPI transactions are not supported on Web.');
      return null;
    }

    if (amount <= 0) {
      throw ArgumentError('Amount must be greater than zero.');
    }

    try {
      final String transactionRef =
          'KREVZY${DateTime.now().millisecondsSinceEpoch}';

      final upi.UpiTransactionResponse response =
          await upi.UpiPay.initiateTransaction(
            amount: amount.toStringAsFixed(2),
            app: app.application,
            receiverName: receiverName,
            receiverUpiAddress: receiverUpiId,
            transactionRef: transactionRef,
            transactionNote: 'KREVZY Wallet Top Up',
          );

      return UpiResponse.fromPluginResponse(response);
    } catch (e, stackTrace) {
      debugPrint('KREVZY UPI transaction error: $e');
      debugPrintStack(stackTrace: stackTrace);

      return null;
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/upi_service.dart';

class PaymentModal extends StatefulWidget {
  final String receiverUpiId;
  final String receiverName;
  final Function(String statusMessage) onPaymentCompleted;

  const PaymentModal({
    super.key,
    required this.receiverUpiId,
    required this.receiverName,
    required this.onPaymentCompleted,
  });

  @override
  State<PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends State<PaymentModal> {
  final TextEditingController _amountController = TextEditingController();

  final UpiService _upiService = UpiService();

  List<UpiApp> _upiApps = <UpiApp>[];

  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    fetchUpiApps();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> fetchUpiApps() async {
    if (kIsWeb) {
      debugPrint('UPI payments are not supported on Web.');

      if (mounted) {
        setState(() {
          _upiApps = <UpiApp>[];
          _isLoading = false;
        });
      }

      return;
    }

    try {
      final List<UpiApp> apps = await _upiService.getInstalledApps();

      if (!mounted) {
        return;
      }

      setState(() {
        _upiApps = apps;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('UPI Fetch Error: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        setState(() {
          _upiApps = <UpiApp>[];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _initiateTransaction(UpiApp app) async {
    if (_isProcessing) {
      return;
    }

    final String amountText = _amountController.text.trim();

    final double? amount = double.tryParse(amountText);

    if (amountText.isEmpty ||
        amount == null ||
        !amount.isFinite ||
        amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final UpiResponse? response = await _upiService.startTransaction(
        app: app,
        receiverUpiId: widget.receiverUpiId,
        receiverName: widget.receiverName,
        amount: amount,
      );

      if (!mounted) {
        return;
      }

      if (response == null) {
        widget.onPaymentCompleted(
          'Payment status unavailable. '
          'Please verify the payment before crediting any wallet balance.',
        );
      } else {
        widget.onPaymentCompleted('Status: ${response.status ?? 'unknown'}');
      }

      Navigator.of(context).pop();
    } catch (e, stackTrace) {
      debugPrint('KREVZY Payment Transaction Error: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      widget.onPaymentCompleted('Transaction failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Send Payment',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: _isProcessing ? null : () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            enabled: !_isProcessing,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Enter Amount (₹)',
              prefixText: '₹ ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Select App to Pay:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_upiApps.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Koi supported UPI app nahi mila. '
                'Android/iOS device par try karein.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: _upiApps.map((app) {
                return InkWell(
                  onTap: _isProcessing ? null : () => _initiateTransaction(app),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 52,
                          height: 52,
                          child: app.iconWidget(52),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          app.name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          if (_isProcessing) ...[
            const SizedBox(height: 20),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:upi_india/upi_india.dart';

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
  final UpiIndia _upiIndia = UpiIndia();
  List<UpiApp> _upiApps = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUpiApps();
  }

  // 🟢 Fixed: Parameter removed from getAllUpiApps()
  Future<void> fetchUpiApps() async {
    if (kIsWeb) {
      debugPrint("UPI payments are not supported on Web.");
      if (mounted) {
        setState(() {
          _upiApps = [];
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final apps = await _upiIndia.getAllUpiApps();
      if (mounted) {
        setState(() {
          _upiApps = apps;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("UPI Fetch Error: $e");
      if (mounted) {
        setState(() {
          _upiApps = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _initiateTransaction(UpiApp app) async {
    final amountText = _amountController.text.trim();
    final double? amount = double.tryParse(amountText);

    if (amountText.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    try {
      final UpiResponse response = await _upiIndia.startTransaction(
        app: app,
        receiverUpiId: widget.receiverUpiId,
        receiverName: widget.receiverName,
        transactionRefId: 'TXN${DateTime.now().millisecondsSinceEpoch}',
        transactionNote: 'KREVZY Payment',
        amount: amount,
      );

      widget.onPaymentCompleted('Status: ${response.status}');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      widget.onPaymentCompleted('Transaction failed: $e');
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
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
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
            // 🟢 Fixed: Center inside Padding Widget
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_upiApps.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'Koi supported UPI app nahi mila. Web par chalane ke bajaye Android Device ya Emulator par run karein.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: _upiApps.map((app) {
                return InkWell(
                  onTap: () => _initiateTransaction(app),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.memory(
                          app.icon,
                          height: 52,
                          width: 52,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.account_balance_wallet, size: 48),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          app.name,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
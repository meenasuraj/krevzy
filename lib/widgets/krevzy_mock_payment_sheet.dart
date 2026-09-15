import 'package:flutter/material.dart';

import '../models/krevzy_payment.dart';
import '../services/krevzy_mock_payment_service.dart';

class KrevzyMockPaymentSheet extends StatefulWidget {
  final String chatId;
  final String senderId;
  final String receiverId;
  final String receiverName;

  const KrevzyMockPaymentSheet({
    super.key,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<KrevzyMockPaymentSheet> createState() =>
      _KrevzyMockPaymentSheetState();
}

class _KrevzyMockPaymentSheetState
    extends State<KrevzyMockPaymentSheet> {
  final TextEditingController _amountController =
      TextEditingController();

  final TextEditingController _noteController =
      TextEditingController();

  KrevzyPaymentStatus _outcome =
      KrevzyPaymentStatus.success;

  bool _busy = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _runTestPayment() async {
    if (_busy) return;

    final amount = double.tryParse(
      _amountController.text.trim(),
    );

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter a valid test amount.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _busy = true;
    });

    try {
      final result =
          await KrevzyMockPaymentService.instance.create(
        chatId: widget.chatId,
        senderId: widget.senderId,
        receiverId: widget.receiverId,
        receiverName: widget.receiverName,
        amount: amount,
        note: _noteController.text.trim(),
        outcome: _outcome,
      );

      if (!mounted) return;

      Navigator.of(context).pop(result);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _busy = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Test payment failed: $e',
          ),
        ),
      );
    }
  }

  String _statusLabel(KrevzyPaymentStatus status) {
    switch (status) {
      case KrevzyPaymentStatus.success:
        return 'Success';

      case KrevzyPaymentStatus.pending:
        return 'Pending';

      case KrevzyPaymentStatus.failed:
        return 'Failed';

      case KrevzyPaymentStatus.cancelled:
        return 'Cancelled';

      default:
        return status.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final bottom =
        MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            10,
            20,
            20 + bottom,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color:
                          colorScheme.primaryContainer,
                      borderRadius:
                          BorderRadius.circular(15),
                    ),
                    child: Icon(
                      Icons.currency_rupee_rounded,
                      color: colorScheme
                          .onPrimaryContainer,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Krevzy Pay',
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Test / sandbox payment',
                          style: TextStyle(
                            color: colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                'To ${widget.receiverName}',
                style: TextStyle(
                  fontSize: 14,
                  color:
                      colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: _amountController,
                enabled: !_busy,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration:
                    const InputDecoration(
                  prefixText: '₹ ',
                  labelText: 'Test amount',
                  hintText: '100',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 14),

              TextField(
                controller: _noteController,
                enabled: !_busy,
                maxLines: 2,
                decoration:
                    const InputDecoration(
                  labelText: 'Payment note',
                  hintText: 'Optional note',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 14),

              DropdownButtonFormField<
                  KrevzyPaymentStatus>(
                initialValue: _outcome,
                decoration:
                    const InputDecoration(
                  labelText: 'Simulate result',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value:
                        KrevzyPaymentStatus.success,
                    child: Text('Success'),
                  ),
                  DropdownMenuItem(
                    value:
                        KrevzyPaymentStatus.pending,
                    child: Text('Pending'),
                  ),
                  DropdownMenuItem(
                    value:
                        KrevzyPaymentStatus.failed,
                    child: Text('Failed'),
                  ),
                  DropdownMenuItem(
                    value:
                        KrevzyPaymentStatus.cancelled,
                    child: Text('Cancelled'),
                  ),
                ],
                onChanged: _busy
                    ? null
                    : (value) {
                        if (value == null) return;

                        setState(() {
                          _outcome = value;
                        });
                      },
              ),

              const SizedBox(height: 14),

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: colorScheme
                      .secondaryContainer
                      .withValues(alpha: 0.45),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.science_outlined,
                      size: 20,
                      color: colorScheme
                          .onSecondaryContainer,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Sandbox only. This test does not move '
                        'real money or connect to UPI.',
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          color: colorScheme
                              .onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed:
                      _busy ? null : _runTestPayment,
                  icon: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.play_arrow_rounded,
                        ),
                  label: Text(
                    _busy
                        ? 'Processing test...'
                        : 'Run Test Payment',
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Center(
                child: Text(
                  'Selected: ${_statusLabel(_outcome)}',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
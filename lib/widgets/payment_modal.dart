import 'package:flutter/material.dart';

import '../services/upi_service.dart';

class PaymentModal extends StatefulWidget {
  final double amount;

  final String receiverName;

  final String receiverUpiId;

  final String transactionRef;

  final String transactionNote;

  const PaymentModal({
    super.key,
    required this.amount,
    this.receiverName = 'KREVZY',
    this.receiverUpiId = 'krevzy@upi',
    required this.transactionRef,
    this.transactionNote = 'KREVZY Wallet Top Up',
  });

  @override
  State<PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends State<PaymentModal> {
  final UpiService _upiService = UpiService.instance;

  bool _loading = false;

  String? _message;

  bool _error = false;

  Future<void> _startPayment() async {
    if (_loading) {
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
      _error = false;
    });

    try {
      final response = await _upiService.startTransaction(
        amount: widget.amount.toStringAsFixed(2),
        receiverName: widget.receiverName,
        receiverUpiId: widget.receiverUpiId,
        transactionRef: widget.transactionRef,
        transactionNote: widget.transactionNote,
      );

      if (!mounted) {
        return;
      }

      if (response.isSuccess) {
        setState(() {
          _loading = false;
          _message =
              'Payment submitted successfully. '
              'Verification is required before wallet credit.';
        });
      } else if (response.isPending || response.isSubmitted) {
        setState(() {
          _loading = false;
          _message =
              'Payment is pending. '
              'Wallet credit will appear after verification.';
        });
      } else if (response.isCancelled) {
        setState(() {
          _loading = false;
          _error = true;
          _message = 'Payment was cancelled.';
        });
      } else if (response.isFailure) {
        setState(() {
          _loading = false;
          _error = true;
          _message = 'Payment failed.';
        });
      } else {
        setState(() {
          _loading = false;
          _message =
              'Payment response received. '
              'Please wait for verification.';
        });
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _error = true;
        _message = _cleanError(e);
      });
    }
  }

  String _cleanError(Object error) {
    final text = error.toString();

    if (text.startsWith('Exception: ')) {
      return text.substring(11);
    }

    return text;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: theme.dividerColor,
                ),
              ),
            ),

            const SizedBox(height: 22),

            Text(
              'UPI Payment',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              '₹${widget.amount.toStringAsFixed(2)}',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              'Choose your installed UPI app '
              'from the Android payment chooser.',
              textAlign: TextAlign.center,
            ),

            if (_message != null) ...[
              const SizedBox(height: 18),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _error
                      ? theme.colorScheme.error.withValues(alpha: 0.10)
                      : theme.colorScheme.primary.withValues(alpha: 0.10),
                ),
                child: Text(
                  _message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _error
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 22),

            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _loading ? null : _startPayment,
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.payment),
                label: Text(_loading ? 'Opening UPI...' : 'Pay with UPI'),
              ),
            ),

            const SizedBox(height: 10),

            TextButton(
              onPressed: _loading ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

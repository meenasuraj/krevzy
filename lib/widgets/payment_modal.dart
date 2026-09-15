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
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SingleChildScrollView(
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

              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primary.withValues(alpha: 0.10),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: colorScheme.primary,
                  size: 30,
                ),
              ),

              const SizedBox(height: 14),

              Text(
                'UPI Payment',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 6),

              Text(
                '₹${widget.amount.toStringAsFixed(2)}',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                'KREVZY Wallet',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: colorScheme.surfaceContainerHighest,
                ),
                child: Row(
                  children: [
                    Icon(Icons.apps_rounded, color: colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your Android device will show '
                        'available UPI payment apps.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (_message != null) ...[
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: _error
                        ? colorScheme.error.withValues(alpha: 0.10)
                        : colorScheme.primary.withValues(alpha: 0.10),
                  ),
                  child: Text(
                    _message!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _error ? colorScheme.error : colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _startPayment,
                  icon: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.payment_rounded),
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
      ),
    );
  }
}

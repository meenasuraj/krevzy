import 'package:flutter/material.dart';

import '../services/upi_service.dart';
import '../services/wallet_service.dart';

class AddMoneyScreen extends StatefulWidget {
  const AddMoneyScreen({super.key});

  @override
  State<AddMoneyScreen> createState() => _AddMoneyScreenState();
}

class _AddMoneyScreenState extends State<AddMoneyScreen> {
  final TextEditingController _amountController = TextEditingController();

  final WalletService _walletService = WalletService.instance;

  final UpiService _upiService = UpiService.instance;

  bool _loading = false;

  String? _errorMessage;

  static const String _receiverUpiId = 'krevzy@upi';

  static const String _receiverName = 'KREVZY';

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double? get _amount {
    final value = double.tryParse(_amountController.text.trim());

    if (value == null || value <= 0) {
      return null;
    }

    return value;
  }

  Future<void> _addMoney() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _errorMessage = null;
    });

    final amount = _amount;

    if (amount == null) {
      setState(() {
        _errorMessage = 'Please enter a valid amount.';
      });
      return;
    }

    if (amount < 1) {
      setState(() {
        _errorMessage = 'Minimum amount is ₹1.';
      });
      return;
    }

    if (amount > 100000) {
      setState(() {
        _errorMessage = 'Maximum amount is ₹100,000.';
      });
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      /*
       * IMPORTANT:
       *
       * This only creates a pending top-up.
       *
       * It does NOT increase wallet.balance.
       */
      final topUpId = await _walletService.createPendingTopUp(
        amount: amount,
        provider: 'upi',
      );

      final transactionRef = 'KREVZY-$topUpId';

      final response = await _upiService.startTransaction(
        amount: amount.toStringAsFixed(2),
        receiverName: _receiverName,
        receiverUpiId: _receiverUpiId,
        transactionRef: transactionRef,
        transactionNote: 'KREVZY Wallet Top Up',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });

      await _handleUpiResponse(response, topUpId);
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _errorMessage = _cleanError(e);
      });
    }
  }

  Future<void> _handleUpiResponse(UpiResponse response, String topUpId) async {
    if (response.isSuccess) {
      /*
       * DO NOT CREDIT THE WALLET HERE.
       *
       * The UPI response must be verified by the
       * trusted backend/payment provider.
       */

      _showMessage(
        'Payment submitted successfully. '
        'Wallet credit will appear after verification.',
        isError: false,
      );

      return;
    }

    if (response.isSubmitted || response.isPending) {
      _showMessage(
        'Payment is pending. '
        'Your wallet will be updated after payment verification.',
        isError: false,
      );

      return;
    }

    if (response.isCancelled) {
      _showMessage('UPI payment was cancelled.', isError: true);

      return;
    }

    if (response.isFailure) {
      _showMessage('UPI payment failed.', isError: true);

      return;
    }

    _showMessage(
      'Payment response received. '
      'Please wait for verification.',
      isError: false,
    );
  }

  String _cleanError(Object error) {
    final text = error.toString();

    if (text.startsWith('Exception: ')) {
      return text.substring(11);
    }

    return text;
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 4)),
      );
  }

  void _setAmount(int amount) {
    _amountController.text = amount.toString();

    setState(() {
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Money')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.14),
                      theme.colorScheme.secondary.withValues(alpha: 0.08),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'Add money to KREVZY Wallet',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Choose an amount and continue with UPI.',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Enter amount',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                enabled: !_loading,
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  hintText: '100',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onChanged: (_) {
                  if (_errorMessage != null) {
                    setState(() {
                      _errorMessage = null;
                    });
                  }
                },
              ),

              const SizedBox(height: 14),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _amountButton(100),
                  _amountButton(200),
                  _amountButton(500),
                  _amountButton(1000),
                  _amountButton(2000),
                ],
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 14),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: theme.colorScheme.error.withValues(alpha: 0.10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: theme.colorScheme.error),

                      const SizedBox(width: 8),

                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 28),

              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _addMoney,
                  icon: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.account_balance),
                  label: Text(_loading ? 'Processing...' : 'Continue with UPI'),
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                'Payment verification is required before '
                'money is credited to your KREVZY Wallet.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _amountButton(int amount) {
    return OutlinedButton(
      onPressed: _loading ? null : () => _setAmount(amount),
      child: Text('₹$amount'),
    );
  }
}

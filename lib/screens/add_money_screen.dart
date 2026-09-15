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

  String _selectedPaymentMethod = 'upi';

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

    if (_selectedPaymentMethod != 'upi') {
      setState(() {
        _errorMessage = 'This payment method will be available soon.';
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
       * This creates only a pending top-up.
       * It DOES NOT increase wallet.balance.
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
        'Your wallet will be updated after verification.',
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

  void _selectPaymentMethod(String method) {
    if (_loading) {
      return;
    }

    setState(() {
      _selectedPaymentMethod = method;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Money')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildWalletHeader(theme, colorScheme),

              const SizedBox(height: 24),

              Text(
                'Enter amount',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: _amountController,
                enabled: !_loading,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  hintText: '100',
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
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

              const SizedBox(height: 28),

              Text(
                'Payment method',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 12),

              _paymentMethodTile(
                icon: Icons.account_balance_wallet_rounded,
                title: 'UPI',
                subtitle: 'Google Pay, PhonePe, Paytm and other UPI apps',
                method: 'upi',
                enabled: true,
              ),

              const SizedBox(height: 10),

              _paymentMethodTile(
                icon: Icons.credit_card_rounded,
                title: 'Cards',
                subtitle: 'Credit & debit cards — coming soon',
                method: 'card',
                enabled: false,
              ),

              const SizedBox(height: 10),

              _paymentMethodTile(
                icon: Icons.account_balance_rounded,
                title: 'Net Banking',
                subtitle: 'Internet banking — coming soon',
                method: 'netbanking',
                enabled: false,
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                _buildError(colorScheme),
              ],

              const SizedBox(height: 28),

              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _addMoney,
                  icon: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.lock_rounded),
                  label: Text(
                    _loading ? 'Opening payment...' : 'Continue to Payment',
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: colorScheme.primary.withValues(alpha: 0.07),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your wallet balance is updated only '
                        'after payment verification.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletHeader(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withValues(alpha: 0.15),
            colorScheme.secondary.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primary.withValues(alpha: 0.12),
            ),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              size: 34,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Add money to KREVZY Wallet',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Choose an amount and your preferred payment method.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentMethodTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String method,
    required bool enabled,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final selected = _selectedPaymentMethod == method;

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: InkWell(
        onTap: enabled ? () => _selectPaymentMethod(method) : null,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: selected
                ? colorScheme.primary.withValues(alpha: 0.09)
                : colorScheme.surfaceContainerHighest,
            border: Border.all(
              color: selected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primary.withValues(alpha: 0.10),
                ),
                child: Icon(icon, color: colorScheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (!enabled) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: colorScheme.surfaceContainerHighest,
                            ),
                            child: const Text(
                              'Soon',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? colorScheme.primary : colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: colorScheme.error.withValues(alpha: 0.10),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: colorScheme.error),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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

import 'package:flutter/foundation.dart';
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
  final UpiService _upiService = UpiService();

  bool _isProcessing = false;
  bool _isLoadingUpiApps = false;

  List<UpiApp> _upiApps = <UpiApp>[];

  final List<int> _quickAmounts = <int>[100, 200, 500, 1000, 2000];

  @override
  void initState() {
    super.initState();
    _loadUpiApps();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadUpiApps() async {
    if (kIsWeb || _isLoadingUpiApps) {
      return;
    }

    if (mounted) {
      setState(() {
        _isLoadingUpiApps = true;
      });
    }

    try {
      final List<UpiApp> apps = await _upiService.getInstalledApps();

      if (!mounted) {
        return;
      }

      setState(() {
        _upiApps = apps;
      });
    } catch (e, stackTrace) {
      debugPrint('KREVZY UPI app discovery error: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      setState(() {
        _upiApps = <UpiApp>[];
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingUpiApps = false;
        });
      }
    }
  }

  void _setAmount(int amount) {
    _amountController.text = amount.toString();

    _amountController.selection = TextSelection.fromPosition(
      TextPosition(offset: _amountController.text.length),
    );

    setState(() {});
  }

  double? _parseAmount() {
    final String text = _amountController.text.trim();

    if (text.isEmpty) {
      return null;
    }

    final double? amount = double.tryParse(text);

    if (amount == null || !amount.isFinite || amount <= 0) {
      return null;
    }

    return amount;
  }

  Future<void> _continueToPayment() async {
    if (_isProcessing) {
      return;
    }

    final double? amount = _parseAmount();

    if (amount == null) {
      _showMessage('Please enter a valid amount.');
      return;
    }

    if (amount < 10) {
      _showMessage('Minimum top-up amount is ₹10.');
      return;
    }

    if (amount > 100000) {
      _showMessage('Maximum top-up amount is ₹1,00,000.');
      return;
    }

    if (kIsWeb) {
      _showMessage('UPI payments are available on Android/iOS, not Web.');
      return;
    }

    if (_upiApps.isEmpty) {
      await _loadUpiApps();

      if (!mounted) {
        return;
      }

      if (_upiApps.isEmpty) {
        await _showNoUpiAppsDialog();
        return;
      }
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final String topUpId = await _walletService.createPendingTopUp(
        amount: amount,
        provider: 'upi',
      );

      if (!mounted) {
        return;
      }

      final UpiApp? selectedApp = await _selectUpiApp();

      if (!mounted) {
        return;
      }

      if (selectedApp == null) {
        await _showCancelledDialog(amount: amount, topUpId: topUpId);
        return;
      }

      // Replace this placeholder with the actual merchant/
      // payment-provider UPI ID before production.
      const String receiverUpiId = 'krevzy@upi';

      final UpiResponse? response = await _upiService.startTransaction(
        app: selectedApp,
        receiverUpiId: receiverUpiId,
        receiverName: 'KREVZY',
        amount: amount,
      );

      if (!mounted) {
        return;
      }

      final String? status = response?.status?.toLowerCase();

      if (status == 'success') {
        await _showPaymentResultDialog(
          title: 'Payment submitted',
          icon: Icons.check_circle_outline_rounded,
          amount: amount,
          topUpId: topUpId,
          message:
              'The UPI application reported a successful response. '
              'Your wallet will be credited only after payment '
              'verification.',
        );
      } else if (status == 'submitted') {
        await _showPaymentResultDialog(
          title: 'Payment submitted',
          icon: Icons.hourglass_top_rounded,
          amount: amount,
          topUpId: topUpId,
          message:
              'Your payment was submitted successfully. '
              'Wallet credit will happen only after payment '
              'verification.',
        );
      } else if (status == 'failure' || status == 'failed') {
        await _showPaymentResultDialog(
          title: 'Payment failed',
          icon: Icons.error_outline_rounded,
          amount: amount,
          topUpId: topUpId,
          message:
              'The UPI application reported that the payment '
              'failed. Your KREVZY Wallet has not been credited.',
        );
      } else if (response == null) {
        await _showPaymentResultDialog(
          title: 'Payment status unavailable',
          icon: Icons.help_outline_rounded,
          amount: amount,
          topUpId: topUpId,
          message:
              'The UPI response could not be confirmed. '
              'Your wallet has not been credited.',
        );
      } else {
        await _showPaymentResultDialog(
          title: 'Payment status pending',
          icon: Icons.hourglass_top_rounded,
          amount: amount,
          topUpId: topUpId,
          message:
              'The payment status is '
              '${response.status ?? 'unknown'}. '
              'Your wallet will remain unchanged until '
              'payment verification is completed.',
        );
      }
    } catch (e) {
      debugPrint('KREVZY Add Money Error: $e');

      if (!mounted) {
        return;
      }

      _showMessage(_friendlyErrorMessage(e));
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<UpiApp?> _selectUpiApp() async {
    if (_upiApps.isEmpty) {
      return null;
    }

    return showModalBottomSheet<UpiApp>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose UPI app',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Select an installed UPI app to continue.',
                  style: Theme.of(sheetContext).textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                ..._upiApps.map((app) {
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    leading: SizedBox(
                      width: 44,
                      height: 44,
                      child: app.iconWidget(40),
                    ),
                    title: Text(
                      app.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      app.packageName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.of(sheetContext).pop(app);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showNoUpiAppsDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined),
              SizedBox(width: 10),
              Expanded(child: Text('No UPI app found')),
            ],
          ),
          content: const Text(
            'No supported UPI application was found on '
            'this device. Install a UPI app and try again.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCancelledDialog({
    required double amount,
    required String topUpId,
  }) async {
    await _showPaymentResultDialog(
      title: 'Payment cancelled',
      icon: Icons.cancel_outlined,
      amount: amount,
      topUpId: topUpId,
      message:
          'You cancelled the UPI app selection. '
          'Your wallet has not been credited.',
    );
  }

  Future<void> _showPaymentResultDialog({
    required String title,
    required IconData icon,
    required double amount,
    required String topUpId,
    required String message,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Row(
            children: [
              Icon(icon),
              const SizedBox(width: 10),
              Expanded(child: Text(title)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Amount: ₹${amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 14),
              Text(message),
              const SizedBox(height: 16),
              const Text(
                'Top-up reference',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              SelectableText(
                topUpId,
                style: Theme.of(dialogContext).textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();

                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  String _friendlyErrorMessage(Object error) {
    final String message = error.toString().toLowerCase();

    if (message.contains('user is not logged in')) {
      return 'Please log in again and try.';
    }

    if (message.contains('permission-denied')) {
      return 'Payment request permission was denied by Firebase.';
    }

    if (message.contains('maximum top-up')) {
      return 'Maximum top-up amount is ₹1,00,000.';
    }

    if (message.contains('amount must be greater')) {
      return 'Please enter a valid amount.';
    }

    if (message.contains('network')) {
      return 'Network error. Please check your internet connection.';
    }

    return 'Unable to start the payment. Please try again.';
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Money')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 38,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Add money to your KREVZY Wallet',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Choose an amount and continue securely '
                      'with UPI.',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Enter amount',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amountController,
                enabled: !_isProcessing,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) {
                  setState(() {});
                },
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  hintText: '100',
                  labelText: 'Amount',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Quick amounts',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _quickAmounts.map((amount) {
                  return OutlinedButton(
                    onPressed: _isProcessing ? null : () => _setAmount(amount),
                    child: Text('₹$amount'),
                  );
                }).toList(),
              ),
              const SizedBox(height: 30),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.security_rounded),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your wallet balance is not changed by '
                        'this screen. After payment, the '
                        'transaction must be verified by the '
                        'trusted payment backend before wallet '
                        'credit.',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (!kIsWeb)
                Row(
                  children: [
                    if (_isLoadingUpiApps)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else if (_upiApps.isNotEmpty)
                      const Icon(Icons.check_circle_outline_rounded, size: 18)
                    else
                      const Icon(Icons.info_outline_rounded, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isLoadingUpiApps
                            ? 'Checking UPI apps...'
                            : _upiApps.isNotEmpty
                            ? '${_upiApps.length} UPI app'
                                  '${_upiApps.length == 1 ? '' : 's'} available'
                            : 'No UPI apps detected',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    if (!_isLoadingUpiApps && !_isProcessing)
                      IconButton(
                        tooltip: 'Refresh UPI apps',
                        onPressed: _loadUpiApps,
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                  ],
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: _isProcessing ? null : _continueToPayment,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.account_balance_wallet_rounded),
                  label: Text(
                    _isProcessing ? 'Processing...' : 'Continue to Payment',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Minimum ₹10 • Maximum ₹1,00,000',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Payments are subject to verification.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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

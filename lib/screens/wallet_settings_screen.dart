import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/wallet_service.dart';

class WalletSettingsScreen extends StatefulWidget {
  const WalletSettingsScreen({super.key});

  @override
  State<WalletSettingsScreen> createState() => _WalletSettingsScreenState();
}

class _WalletSettingsScreenState extends State<WalletSettingsScreen> {
  final WalletService _walletService = WalletService.instance;

  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF8F7FF),
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Wallet & Payments',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _walletService.paymentSetupStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _errorView(snapshot.error);
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.data();
          final bank = _asMap(data?['bank']);
          final upi = _asMap(data?['upi']);

          final bankStatus = _normalizeStatus(bank?['status']?.toString());
          final upiStatus = _normalizeStatus(upi?['status']?.toString());

          final paymentReady =
              bankStatus == 'verified' && upiStatus == 'verified';

          return RefreshIndicator(
            onRefresh: () async {
              await _walletService.getPaymentSetup();
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _introCard(context),
                const SizedBox(height: 16),

                _stepCard(
                  context,
                  step: 1,
                  icon: Icons.account_balance_outlined,
                  title: 'Add Bank Account',
                  subtitle: _bankSubtitle(bankStatus),
                  status: bankStatus,
                  onTap: _busy ? null : () => _showBankForm(bank),
                ),

                _connector(context),

                _stepCard(
                  context,
                  step: 2,
                  icon: Icons.verified_user_outlined,
                  title: 'Verify Bank Account',
                  subtitle: _bankVerificationSubtitle(bankStatus),
                  status: bankStatus == 'not_added' ? 'locked' : bankStatus,
                  onTap: null,
                ),

                _connector(context),

                _stepCard(
                  context,
                  step: 3,
                  icon: Icons.alternate_email_outlined,
                  title: 'Add UPI ID',
                  subtitle: _upiSubtitle(bankStatus, upiStatus),
                  status: bankStatus != 'verified' ? 'locked' : upiStatus,
                  onTap: bankStatus == 'verified' && !_busy
                      ? () => _showUpiForm(upi)
                      : null,
                ),

                _connector(context),

                _stepCard(
                  context,
                  step: 4,
                  icon: Icons.payments_outlined,
                  title: 'Payment',
                  subtitle: paymentReady
                      ? 'Your verified payment method is ready'
                      : 'Payment unlocks after bank and UPI verification',
                  status: paymentReady ? 'ready' : 'locked',
                  onTap: null,
                ),

                const SizedBox(height: 20),

                _liveStatusCard(
                  context,
                  bankStatus: bankStatus,
                  upiStatus: upiStatus,
                  paymentReady: paymentReady,
                ),

                const SizedBox(height: 16),

                _securityCard(context),

                if (_busy) ...[
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator()),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _errorView(Object? error) {
    final message = _friendlyFirestoreError(error);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: Color(0xFFD93025),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Unable to load payment setup',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => setState(() {}),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _introCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer.withValues(alpha: 0.45),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 30,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Secure Payment Setup',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Complete the steps in order: bank account → bank verification → UPI ID → payment.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepCard(
    BuildContext context, {
    required int step,
    required IconData icon,
    required String title,
    required String subtitle,
    required String status,
    required VoidCallback? onTap,
  }) {
    final normalized = _normalizeStatus(status);

    final isVerified = normalized == 'verified' || normalized == 'ready';
    final isPending = normalized == 'pending';
    final isFailed = normalized == 'failed';
    final iconColor = _statusColor(normalized, context);

    return Card(
      elevation: 0,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: _statusBackground(normalized, context),
          child: Icon(
            isFailed
                ? Icons.error_outline_rounded
                : isPending
                ? Icons.hourglass_top_rounded
                : isVerified
                ? Icons.verified_rounded
                : icon,
            color: iconColor,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                '$step. $title',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            _statusChip(context, normalized),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
        trailing: onTap == null ? null : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _statusChip(BuildContext context, String status) {
    final normalized = _normalizeStatus(status);

    final String label;
    final IconData icon;

    switch (normalized) {
      case 'verified':
      case 'ready':
        label = normalized == 'ready' ? 'Ready' : 'Verified';
        icon = Icons.verified_rounded;
        break;

      case 'pending':
        label = 'Pending';
        icon = Icons.hourglass_top_rounded;
        break;

      case 'failed':
        label = 'Failed';
        icon = Icons.error_outline_rounded;
        break;

      case 'locked':
        label = 'Locked';
        icon = Icons.lock_outline_rounded;
        break;

      default:
        label = 'Add';
        icon = Icons.add_circle_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: _statusBackground(normalized, context),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _statusColor(normalized, context)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _statusColor(normalized, context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _connector(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 35),
      child: Container(
        width: 2,
        height: 18,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }

  Widget _liveStatusCard(
    BuildContext context, {
    required String bankStatus,
    required String upiStatus,
    required bool paymentReady,
  }) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.sync_rounded, size: 20),
                SizedBox(width: 8),
                Text(
                  'Live Verification Status',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _liveRow(context, label: 'Bank account', status: bankStatus),
            const SizedBox(height: 10),
            _liveRow(
              context,
              label: 'UPI ID',
              status: bankStatus == 'verified' ? upiStatus : 'locked',
            ),
            const SizedBox(height: 10),
            _liveRow(
              context,
              label: 'Payments',
              status: paymentReady ? 'ready' : 'locked',
            ),
            const SizedBox(height: 12),
            Text(
              'This status updates automatically when the payment backend changes the Firestore verification status.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _liveRow(
    BuildContext context, {
    required String label,
    required String status,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        _statusChip(context, status),
      ],
    );
  }

  Widget _securityCard(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.security_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Bank and UPI verification must be completed by the trusted payment backend. '
                'The app does not mark accounts as verified itself.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return null;
  }

  String _normalizeStatus(String? value) {
    final status = value?.trim().toLowerCase();

    switch (status) {
      case 'verified':
      case 'pending':
      case 'failed':
      case 'locked':
      case 'not_added':
      case 'ready':
        return status!;
      default:
        return 'not_added';
    }
  }

  Color _statusColor(String status, BuildContext context) {
    switch (_normalizeStatus(status)) {
      case 'verified':
      case 'ready':
        return const Color(0xFF16803C);

      case 'pending':
        return const Color(0xFFB26A00);

      case 'failed':
        return const Color(0xFFD93025);

      case 'locked':
        return Theme.of(context).colorScheme.outline;

      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  Color _statusBackground(String status, BuildContext context) {
    switch (_normalizeStatus(status)) {
      case 'verified':
      case 'ready':
        return const Color(0xFFE8F7ED);

      case 'pending':
        return const Color(0xFFFFF4DE);

      case 'failed':
        return const Color(0xFFFFECEA);

      case 'locked':
        return Theme.of(context).colorScheme.surfaceContainerHighest;

      default:
        return Theme.of(context).colorScheme.primaryContainer
            .withValues(alpha: 0.45);
    }
  }

  String _bankSubtitle(String status) {
    switch (status) {
      case 'verified':
        return 'Bank account verified successfully';

      case 'pending':
        return 'Bank verification is pending';

      case 'failed':
        return 'Bank verification failed. You can submit again';

      case 'locked':
        return 'Bank account setup is locked';

      default:
        return 'Add your bank account to start payment setup';
    }
  }

  String _bankVerificationSubtitle(String status) {
    switch (status) {
      case 'verified':
        return 'Bank account is verified';

      case 'pending':
        return 'Waiting for trusted backend verification';

      case 'failed':
        return 'Verification failed. Please review and resubmit';

      default:
        return 'Add your bank account first';
    }
  }

  String _upiSubtitle(String bankStatus, String upiStatus) {
    if (bankStatus != 'verified') {
      return 'Available after bank verification';
    }

    switch (upiStatus) {
      case 'verified':
        return 'UPI ID verified successfully';

      case 'pending':
        return 'UPI verification is pending';

      case 'failed':
        return 'UPI verification failed. You can submit again';

      default:
        return 'Add your UPI ID';
    }
  }

  Future<void> _showBankForm(Map<String, dynamic>? existingBank) async {
    final holderController = TextEditingController(
      text: existingBank?['accountHolderName']?.toString() ?? '',
    );
    final bankController = TextEditingController(
      text: existingBank?['bankName']?.toString() ?? '',
    );
    final accountController = TextEditingController();
    final ifscController = TextEditingController(
      text: existingBank?['ifsc']?.toString() ?? '',
    );

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (sheetContext) {
          return SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Add Bank Account',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your bank account will be submitted as pending. '
                      'Verification must be completed by the trusted backend.',
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: holderController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Account holder name',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: bankController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Bank name',
                        prefixIcon: Icon(Icons.account_balance_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: accountController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Bank account number',
                        prefixIcon: Icon(Icons.numbers_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: ifscController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'IFSC code',
                        prefixIcon: Icon(Icons.code_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: _busy
                          ? null
                          : () async {
                              await _saveBank(
                                sheetContext,
                                holderController.text,
                                bankController.text,
                                accountController.text,
                                ifscController.text,
                              );
                            },
                      icon: const Icon(Icons.verified_outlined),
                      label: const Text('Submit for Verification'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } finally {
      holderController.dispose();
      bankController.dispose();
      accountController.dispose();
      ifscController.dispose();
    }
  }

  Future<void> _saveBank(
    BuildContext sheetContext,
    String holder,
    String bank,
    String account,
    String ifsc,
  ) async {
    if (holder.trim().isEmpty) {
      _showMessage('Name required', 'Enter the bank account holder name.');
      return;
    }

    if (bank.trim().isEmpty) {
      _showMessage('Bank required', 'Enter the bank name.');
      return;
    }

    if (account.trim().isEmpty) {
      _showMessage('Bank account required', 'Enter the bank account number.');
      return;
    }

    if (ifsc.trim().isEmpty) {
      _showMessage('IFSC required', 'Enter the IFSC code.');
      return;
    }

    setState(() => _busy = true);

    try {
      await _walletService.saveBankAccountForVerification(
        accountHolderName: holder,
        bankName: bank,
        accountNumber: account,
        ifsc: ifsc,
      );

      if (!sheetContext.mounted) return;
      Navigator.pop(sheetContext);

      if (!mounted) return;

      _showMessage(
        'Bank submitted',
        'Your bank account is now Pending verification. '
            'The status will update automatically when the trusted backend completes verification.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage('Unable to add bank', _friendlyError(e));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _showUpiForm(Map<String, dynamic>? existingUpi) async {
    final controller = TextEditingController(
      text: existingUpi?['upiId']?.toString() ?? '',
    );

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (sheetContext) {
          return SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Add UPI ID',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Only a verified bank account can add a UPI ID.',
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: controller,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'UPI ID',
                        hintText: 'example@upi',
                        prefixIcon: Icon(Icons.alternate_email),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: _busy
                          ? null
                          : () async {
                              setState(() => _busy = true);

                              try {
                                await _walletService.addUpiId(
                                  upiId: controller.text,
                                );

                                if (!sheetContext.mounted) {
                                  return;
                                }

                                Navigator.pop(sheetContext);

                                if (!mounted) return;

                                _showMessage(
                                  'UPI submitted',
                                  'Your UPI ID is now Pending verification. '
                                      'The status will update automatically.',
                                );
                              } catch (e) {
                                if (!mounted) return;

                                _showMessage(
                                  'Unable to add UPI',
                                  _friendlyError(e),
                                );
                              } finally {
                                if (mounted) {
                                  setState(() => _busy = false);
                                }
                              }
                            },
                      icon: const Icon(Icons.verified_outlined),
                      label: const Text('Submit for Verification'),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } finally {
      controller.dispose();
    }
  }

  String _friendlyError(Object error) {
    if (error is FirebaseException) {
      if (error.code == 'permission-denied') {
        return 'Firestore permission denied. Deploy the latest Firestore rules and make sure you are signed in.';
      }

      if (error.code == 'unauthenticated') {
        return 'Please sign in again.';
      }

      if (error.message != null && error.message!.trim().isNotEmpty) {
        return error.message!;
      }
    }

    if (error is ArgumentError) {
      return error.message?.toString() ?? 'Please check the entered details.';
    }

    if (error is StateError) {
      return error.message;
    }

    return 'Something went wrong. Please try again.';
  }

  String _friendlyFirestoreError(Object? error) {
    if (error is FirebaseException) {
      if (error.code == 'permission-denied') {
        return 'Permission denied while reading payment setup. '
            'Deploy the paymentMethods Firestore rules for the gapshap-app-9901 Firebase project.';
      }

      if (error.code == 'unauthenticated') {
        return 'Your login session is not available. Please sign in again.';
      }

      if (error.message != null && error.message!.trim().isNotEmpty) {
        return error.message!;
      }
    }

    return 'Please check your Firebase connection and Firestore rules.';
  }

  void _showMessage(String title, String message) {
    if (!mounted) return;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

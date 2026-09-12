import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PaymentsUpiScreen extends StatefulWidget {
  const PaymentsUpiScreen({super.key});

  @override
  State<PaymentsUpiScreen> createState() => _PaymentsUpiScreenState();
}

class _PaymentsUpiScreenState extends State<PaymentsUpiScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _upiController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  bool _hasUpiId = false;

  String? _savedUpiId;

  @override
  void initState() {
    super.initState();
    _loadUpiId();
  }

  @override
  void dispose() {
    _upiController.dispose();
    super.dispose();
  }

  Future<void> _loadUpiId() async {
    final user = _auth.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      return;
    }

    try {
      final snapshot = await _firestore.collection('users').doc(user.uid).get();

      if (!mounted) return;

      final data = snapshot.data();

      final value = _firstNonEmptyString([
        data?['upiId'],
        data?['upi_id'],
        data?['upiAddress'],
        data?['upi_address'],
        data?['upi'],
      ]);

      setState(() {
        _savedUpiId = value;
        _hasUpiId = value != null;
        _isLoading = false;
      });

      if (value != null) {
        _upiController.text = value;
      }
    } catch (e) {
      debugPrint('KREVZY UPI load error: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage(
        'Unable to load UPI',
        'We could not load your UPI ID. Please try again.',
      );
    }
  }

  String? _firstNonEmptyString(List<dynamic> values) {
    for (final value in values) {
      if (value is String) {
        final trimmed = value.trim();

        if (trimmed.isNotEmpty) {
          return trimmed;
        }
      }
    }

    return null;
  }

  bool _isValidUpiId(String value) {
    final upi = value.trim().toLowerCase();

    if (upi.isEmpty) {
      return false;
    }

    /*
     * Standard UPI IDs generally look like:
     *
     * name@bank
     * username@upi
     * mobile@ibl
     *
     * We intentionally allow letters, numbers, dot, underscore,
     * hyphen and @.
     */
    final regex = RegExp(
      r'^[a-z0-9][a-z0-9._-]{1,80}@[a-z0-9][a-z0-9._-]{1,30}$',
      caseSensitive: false,
    );

    return regex.hasMatch(upi);
  }

  Future<void> _saveUpiId() async {
    final user = _auth.currentUser;

    if (user == null) {
      _showMessage('Not signed in', 'Please sign in to add a UPI ID.');
      return;
    }

    final upiId = _upiController.text.trim().toLowerCase();

    if (!_isValidUpiId(upiId)) {
      _showMessage(
        'Invalid UPI ID',
        'Please enter a valid UPI ID such as name@bank.',
      );
      return;
    }

    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'upiId': upiId,
        'upiEnabled': true,
        'upiUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      setState(() {
        _savedUpiId = upiId;
        _hasUpiId = true;
        _isEditing = false;
        _isSaving = false;
      });

      FocusScope.of(context).unfocus();

      _showMessage(
        'UPI ID saved',
        'Your UPI ID has been added to your KREVZY account.',
      );
    } catch (e) {
      debugPrint('KREVZY UPI save error: $e');

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showMessage(
        'Unable to save UPI ID',
        'Please check your internet connection and try again.',
      );
    }
  }

  Future<void> _removeUpiId() async {
    final user = _auth.currentUser;

    if (user == null || !_hasUpiId) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remove UPI ID?'),
          content: const Text(
            'Your UPI ID will be removed from your KREVZY account. '
            'Other users will no longer be able to start a payment to you '
            'through KREVZY.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'upiId': FieldValue.delete(),
        'upiEnabled': false,
        'upiUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      setState(() {
        _savedUpiId = null;
        _hasUpiId = false;
        _isEditing = false;
        _isSaving = false;
        _upiController.clear();
      });

      _showMessage(
        'UPI ID removed',
        'Your UPI ID has been removed from KREVZY.',
      );
    } catch (e) {
      debugPrint('KREVZY UPI remove error: $e');

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showMessage('Unable to remove UPI ID', 'Please try again.');
    }
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _upiController.text = _savedUpiId ?? '';
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _upiController.text = _savedUpiId ?? '';
    });

    FocusScope.of(context).unfocus();
  }

  void _showMessage(String title, String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Payments & UPI',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildHeaderCard(),

                  const SizedBox(height: 24),

                  const Text(
                    'Your UPI ID',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  if (_hasUpiId && !_isEditing)
                    _buildSavedUpiCard()
                  else
                    _buildUpiForm(),

                  const SizedBox(height: 28),

                  _buildHowItWorksCard(),

                  const SizedBox(height: 24),

                  _buildSecurityCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.secondaryContainer,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Theme.of(context).colorScheme.onPrimaryContainer
                .withValues(alpha: 0.10),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              size: 30,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Payments on KREVZY',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your UPI ID so other KREVZY users can send '
            'payments to you from chat.',
            style: TextStyle(
              height: 1.45,
              color: Theme.of(context).colorScheme.onSurface
                  .withValues(alpha: 0.70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedUpiCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'UPI ID added',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _savedUpiId ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface
                            .withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.check_circle_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSaving ? null : _startEditing,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSaving ? null : _removeUpiId,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remove'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpiForm() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.45),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _upiController,
            enabled: !_isSaving,
            textInputAction: TextInputAction.done,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            enableSuggestions: false,
            onSubmitted: (_) => _saveUpiId(),
            decoration: const InputDecoration(
              labelText: 'UPI ID',
              hintText: 'example@bank',
              prefixIcon: Icon(Icons.account_balance_wallet_outlined),
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 10),

          Text(
            'Example: name@upi, username@okaxis, mobile@ibl',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface
                  .withValues(alpha: 0.55),
            ),
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              if (_hasUpiId && _isEditing) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : _cancelEditing,
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _saveUpiId,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    _isSaving
                        ? 'Saving...'
                        : _hasUpiId
                        ? 'Update UPI ID'
                        : 'Add UPI ID',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksCard() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline),
                SizedBox(width: 10),
                Text(
                  'How payments work',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _infoRow(
              Icons.looks_one_outlined,
              'Add your UPI ID',
              'Save the UPI ID connected to your bank account.',
            ),
            _infoRow(
              Icons.looks_two_outlined,
              'Open a KREVZY chat',
              'Tap the payment option in a chat.',
            ),
            _infoRow(
              Icons.looks_3_outlined,
              'Choose a UPI app',
              'KREVZY opens a supported UPI app on Android.',
            ),
            _infoRow(
              Icons.looks_4_outlined,
              'Complete the payment',
              'Review the payment in your UPI app before confirming.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: Theme.of(context).colorScheme.onSurface
                        .withValues(alpha: 0.62),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.35),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_user_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your UPI ID is stored with your KREVZY account. '
              'KREVZY does not ask for your UPI PIN. Payment authorization '
              'is handled by your selected UPI app.',
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: Theme.of(context).colorScheme.onSurface
                    .withValues(alpha: 0.68),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../services/app_lock_service.dart';
import '../services/biometric_service.dart';

class AppLockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;

  const AppLockScreen({super.key, required this.onUnlocked});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final TextEditingController _pinController = TextEditingController();

  bool _isChecking = false;
  bool _isBiometricChecking = false;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  bool _biometricAttempted = false;

  String _biometricLabel = 'Biometric';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupBiometric();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _setupBiometric() async {
    final enabled = await AppLockService.isBiometricEnabled();

    if (!mounted) return;

    if (!enabled) {
      setState(() {
        _biometricEnabled = false;
      });
      return;
    }

    final available = await BiometricService.isAvailable();

    if (!mounted) return;

    final label = available
        ? await BiometricService.getBiometricLabel()
        : 'Biometric';

    if (!mounted) return;

    setState(() {
      _biometricEnabled = enabled;
      _biometricAvailable = available;
      _biometricLabel = label;
    });

    if (enabled && available && !_biometricAttempted) {
      _biometricAttempted = true;

      await Future<void>.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;

      await _unlockWithBiometric();
    }
  }

  Future<void> _unlockWithBiometric() async {
    if (_isBiometricChecking) return;

    setState(() {
      _isBiometricChecking = true;
      _errorMessage = null;
    });

    final authenticated = await BiometricService.authenticate();

    if (!mounted) return;

    setState(() {
      _isBiometricChecking = false;
    });

    if (authenticated) {
      widget.onUnlocked();
      return;
    }

    setState(() {
      _errorMessage =
          'Biometric authentication failed or was cancelled. '
          'Use your App Lock PIN.';
    });
  }

  Future<void> _unlockWithPin() async {
    final pin = _pinController.text.trim();

    if (!RegExp(r'^\d{4,6}$').hasMatch(pin)) {
      setState(() {
        _errorMessage = 'Enter your 4–6 digit App Lock PIN.';
      });
      return;
    }

    setState(() {
      _isChecking = true;
      _errorMessage = null;
    });

    final isCorrect = await AppLockService.verifyPin(pin);

    if (!mounted) return;

    setState(() {
      _isChecking = false;
    });

    if (isCorrect) {
      widget.onUnlocked();
      return;
    }

    setState(() {
      _errorMessage = 'Incorrect PIN. Please try again.';
    });

    _pinController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_rounded,
                      size: 44,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),

                  const SizedBox(height: 28),

                  const Text(
                    'KREVZY Locked',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    'Unlock KREVZY using your biometric '
                    'or App Lock PIN.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),

                  const SizedBox(height: 32),

                  if (_biometricEnabled && _biometricAvailable) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: _isBiometricChecking
                            ? null
                            : _unlockWithBiometric,
                        icon: _isBiometricChecking
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                _biometricLabel == 'Face ID'
                                    ? Icons.face_rounded
                                    : Icons.fingerprint_rounded,
                                size: 26,
                              ),
                        label: Text(
                          _isBiometricChecking
                              ? 'Checking...'
                              : 'Use $_biometricLabel',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                      ],
                    ),

                    const SizedBox(height: 20),
                  ],

                  TextField(
                    controller: _pinController,
                    autofocus: !(_biometricEnabled && _biometricAvailable),
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    onSubmitted: (_) => _unlockWithPin(),
                    decoration: InputDecoration(
                      labelText: 'App Lock PIN',
                      hintText: '••••',
                      counterText: '',
                      prefixIcon: const Icon(Icons.pin_outlined),
                      errorText: _errorMessage,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _isChecking ? null : _unlockWithPin,
                      child: _isChecking
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Unlock with PIN',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  if (_biometricEnabled && _biometricAvailable) ...[
                    const SizedBox(height: 14),

                    TextButton.icon(
                      onPressed: _isBiometricChecking
                          ? null
                          : _unlockWithBiometric,
                      icon: Icon(
                        _biometricLabel == 'Face ID'
                            ? Icons.face_rounded
                            : Icons.fingerprint_rounded,
                      ),
                      label: Text('Try $_biometricLabel Again'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

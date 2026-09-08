import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/app_lock_service.dart';
import '../services/biometric_service.dart';
import '../services/session_service.dart';
import 'customization_screen.dart';
import 'blocked_accounts_screen.dart';
import 'krevzy_preferences_screen.dart';
import 'account_center_screen.dart';
import 'email_settings_screen.dart';
import 'data_media_quality_screen.dart';
import 'storage_management_screen.dart';
import 'notification_settings_screen.dart';
import 'account_privacy_screen.dart';
import 'active_sessions_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _appLockEnabled = false;
  bool _biometricEnabled = false;
  bool _chatLockEnabled = true;
  bool _notificationsEnabled = true;
  bool _messageNotifications = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _loadAppLockState();
  }

  Future<void> _loadAppLockState() async {
    final enabled = await AppLockService.isEnabled();
    final biometricEnabled = await AppLockService.isBiometricEnabled();

    if (!mounted) return;

    setState(() {
      _appLockEnabled = enabled;
      _biometricEnabled = enabled && biometricEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        children: [
          _sectionTitle('Account'),

          _SettingsTile(
            icon: Icons.person_outline,
            title: 'Account',
            subtitle: 'Personal information and account details',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountCenterScreen()));
            },
          ),

          _SettingsTile(
            icon: Icons.lock_outline,
            title: 'Password and security',
            subtitle: 'Manage your password and security',
            onTap: _showPasswordSecurity,
          ),

          _SettingsTile(
            icon: Icons.email_outlined,
            title: 'Email',
            subtitle:
                FirebaseAuth.instance.currentUser?.email ??
                'No email available',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const EmailSettingsScreen()));
            },
          ),

          _sectionTitle('Privacy & Security'),

          _SettingsTile(
            icon: Icons.tune_outlined,
            title: 'KREVZY preferences',
            subtitle: 'Activity, privacy, interactions, sounds, language & data',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const KrevzyPreferencesScreen()));
            },
          ),


          _SettingsSwitchTile(
            icon: Icons.phonelink_lock_outlined,
            title: 'App Lock',
            subtitle: _appLockEnabled
                ? 'KREVZY will require a PIN to open'
                : 'Protect the entire KREVZY app',
            value: _appLockEnabled,
            onChanged: (value) {
              if (value) {
                _showEnableAppLockDialog();
              } else {
                _showDisableAppLockDialog();
              }
            },
          ),

          if (_appLockEnabled)
            _SettingsTile(
              icon: Icons.password_outlined,
              title: 'Change App Lock PIN',
              subtitle: 'Change your current App Lock PIN',
              onTap: _showChangeAppLockPinDialog,
            ),

          if (_appLockEnabled)
            _SettingsSwitchTile(
              icon: Icons.fingerprint,
              title: 'Biometric App Lock',
              subtitle: _biometricEnabled
                  ? 'Use Fingerprint or Face ID to unlock'
                  : 'Use Fingerprint or Face ID to unlock Gapshap',
              value: _biometricEnabled,
              onChanged: _toggleBiometric,
            ),

          _SettingsSwitchTile(
            icon: Icons.chat_outlined,
            title: 'Chat Lock',
            subtitle: _chatLockEnabled
                ? 'Chat Lock is available'
                : 'Chat Lock is disabled',
            value: _chatLockEnabled,
            onChanged: (value) {
              setState(() {
                _chatLockEnabled = value;
              });

              if (value) {
                _showMessage(
                  'Chat Lock enabled',
                  'You can lock individual chats using the 3-dot menu inside a chat.',
                );
              }
            },
          ),

          _SettingsTile(
            icon: Icons.visibility_outlined,
            title: 'Privacy',
            subtitle: 'Last seen, online status, profile and more',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountPrivacyScreen())),
          ),

          _SettingsTile(
            icon: Icons.block_outlined,
            title: 'Blocked accounts',
            subtitle: 'Manage accounts you have blocked',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const BlockedAccountsScreen()));
            },
          ),

          _sectionTitle('Notifications'),

          _SettingsTile(
            icon: Icons.tune_outlined,
            title: 'Notification settings',
            subtitle: 'Choose message, sound and vibration preferences',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationSettingsScreen())),
          ),

          _SettingsSwitchTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: _notificationsEnabled
                ? 'Notifications are enabled'
                : 'Notifications are disabled',
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;

                if (!value) {
                  _messageNotifications = false;
                }
              });
            },
          ),

          _SettingsSwitchTile(
            icon: Icons.chat_bubble_outline,
            title: 'Message notifications',
            subtitle: 'Notifications for new messages',
            value: _messageNotifications,
            enabled: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _messageNotifications = value;
              });
            },
          ),

          _SettingsSwitchTile(
            icon: Icons.volume_up_outlined,
            title: 'Notification sound',
            subtitle: 'Play sound for notifications',
            value: _soundEnabled,
            enabled: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _soundEnabled = value;
              });
            },
          ),

          _SettingsSwitchTile(
            icon: Icons.vibration_outlined,
            title: 'Vibration',
            subtitle: 'Vibrate for notifications',
            value: _vibrationEnabled,
            enabled: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _vibrationEnabled = value;
              });
            },
          ),

          _sectionTitle('Appearance'),

          _SettingsTile(
            icon: Icons.palette_outlined,
            title: 'Appearance',
            subtitle: 'KREVZY gradient, app photo, chat & composer backgrounds',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomizationScreen()));
            },
          ),

          _sectionTitle('Data & Storage'),

          _SettingsTile(
            icon: Icons.data_usage_outlined,
            title: 'Data usage',
            subtitle: 'Control media and network usage',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DataMediaQualityScreen()));
            },
          ),

          _SettingsTile(
            icon: Icons.storage_outlined,
            title: 'Storage',
            subtitle: 'Manage cached media and storage',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StorageManagementScreen())),
          ),

          _sectionTitle('Help'),

          _SettingsTile(
            icon: Icons.help_outline,
            title: 'Help Center',
            subtitle: 'Get help with KREVZY',
            onTap: () {
              _showComingSoon('Help Center');
            },
          ),

          _SettingsTile(
            icon: Icons.report_problem_outlined,
            title: 'Report a problem',
            subtitle: 'Tell us about an issue',
            onTap: _showReportDialog,
          ),

          _SettingsTile(
            icon: Icons.feedback_outlined,
            title: 'Feedback',
            subtitle: 'Share your feedback with us',
            onTap: () {
              _showComingSoon('Feedback');
            },
          ),

          _sectionTitle('About'),

          _SettingsTile(
            icon: Icons.info_outline,
            title: 'About KREVZY',
            subtitle: 'Version 1.0.0',
            onTap: _showAboutDialog,
          ),

          _SettingsTile(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            subtitle: 'Read KREVZY terms',
            onTap: () {
              _showComingSoon('Terms of Service');
            },
          ),

          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle: 'Read KREVZY privacy policy',
            onTap: () {
              _showComingSoon('Privacy Policy');
            },
          ),

          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: _isLoggingOut ? null : _showLogoutDialog,
              icon: _isLoggingOut
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.logout),
              label: Text(
                _isLoggingOut ? 'Logging out...' : 'Log out',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ),

          const SizedBox(height: 30),

          Center(
            child: Text(
              'KREVZY',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface
                    .withValues(alpha: 0.45),
              ),
            ),
          ),

          const SizedBox(height: 6),

          Center(
            child: Text(
              'Connect • Share • Chat',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface
                    .withValues(alpha: 0.4),
              ),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Future<void> _toggleBiometric(bool value) async {
    if (!value) {
      await AppLockService.setBiometricEnabled(false);

      if (!mounted) return;

      setState(() {
        _biometricEnabled = false;
      });

      _showMessage(
        'Biometric App Lock disabled',
        'You can still unlock Gapshap using your App Lock PIN.',
      );

      return;
    }

    final available = await BiometricService.isAvailable();

    if (!mounted) return;

    if (!available) {
      _showMessage(
        'Biometric authentication unavailable',
        'No supported Fingerprint or Face authentication is available on this device. '
            'Make sure a biometric method is set up in your device security settings.',
      );
      return;
    }

    final authenticated = await BiometricService.authenticate();

    if (!mounted) return;

    if (!authenticated) {
      _showMessage(
        'Biometric verification cancelled',
        'Biometric App Lock was not enabled.',
      );
      return;
    }

    await AppLockService.setBiometricEnabled(true);

    if (!mounted) return;

    setState(() {
      _biometricEnabled = true;
    });

    final label = await BiometricService.getBiometricLabel();

    if (!mounted) return;

    _showMessage(
      'Biometric App Lock enabled',
      'You can now unlock Gapshap using $label or your App Lock PIN.',
    );
  }

  void _showEnableAppLockDialog() {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.phonelink_lock_outlined),
              SizedBox(width: 10),
              Text('Enable App Lock'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Create a PIN to protect the entire Gapshap app.'),
                const SizedBox(height: 18),
                TextField(
                  controller: pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'App Lock PIN',
                    hintText: '4–6 digits',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: confirmController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Confirm PIN',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_reset_outlined),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final pin = pinController.text.trim();
                final confirm = confirmController.text.trim();

                if (!RegExp(r'^\d{4,6}$').hasMatch(pin)) {
                  _showMessage(
                    'Invalid PIN',
                    'PIN must contain 4 to 6 digits.',
                  );
                  return;
                }

                if (pin != confirm) {
                  _showMessage(
                    'PIN does not match',
                    'Please enter the same PIN in both fields.',
                  );
                  return;
                }

                await AppLockService.enable(pin);

                if (!context.mounted) return;

                setState(() {
                  _appLockEnabled = true;
                  _biometricEnabled = false;
                });

                Navigator.pop(dialogContext);

                _showMessage(
                  'App Lock enabled',
                  'Your App Lock PIN has been created.',
                );
              },
              child: const Text('Enable'),
            ),
          ],
        );
      },
    );
  }

  void _showDisableAppLockDialog() {
    final pinController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.lock_open_outlined),
              SizedBox(width: 10),
              Text('Disable App Lock'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter your current App Lock PIN to disable App Lock.',
              ),
              const SizedBox(height: 18),
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Current PIN',
                  hintText: '4–6 digits',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                if (mounted) {
                  setState(() {
                    _appLockEnabled = true;
                  });
                }
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final pin = pinController.text.trim();

                if (!RegExp(r'^\d{4,6}$').hasMatch(pin)) {
                  _showMessage(
                    'Invalid PIN',
                    'Enter your 4 to 6 digit App Lock PIN.',
                  );
                  return;
                }

                final valid = await AppLockService.verifyPin(pin);

                if (!valid) {
                  if (!context.mounted) return;

                  _showMessage(
                    'Incorrect PIN',
                    'The App Lock PIN is incorrect.',
                  );
                  return;
                }

                await AppLockService.disable();

                if (!context.mounted) return;

                setState(() {
                  _appLockEnabled = false;
                  _biometricEnabled = false;
                });

                Navigator.pop(dialogContext);

                _showMessage(
                  'App Lock disabled',
                  'App Lock has been turned off.',
                );
              },
              child: const Text('Disable'),
            ),
          ],
        );
      },
    );
  }

  void _showChangeAppLockPinDialog() {
    final currentPinController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.password_outlined),
              SizedBox(width: 10),
              Text('Change App Lock PIN'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Enter your current PIN and create a new PIN.'),
                const SizedBox(height: 18),
                TextField(
                  controller: currentPinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Current PIN',
                    hintText: '4–6 digits',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: newPinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'New PIN',
                    hintText: '4–6 digits',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.password_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: confirmPinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New PIN',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_reset_outlined),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final currentPin = currentPinController.text.trim();
                final newPin = newPinController.text.trim();
                final confirmPin = confirmPinController.text.trim();

                final pinRegex = RegExp(r'^\d{4,6}$');

                if (!pinRegex.hasMatch(currentPin)) {
                  _showMessage(
                    'Invalid PIN',
                    'Enter your current 4 to 6 digit PIN.',
                  );
                  return;
                }

                if (!pinRegex.hasMatch(newPin)) {
                  _showMessage(
                    'Invalid new PIN',
                    'New PIN must contain 4 to 6 digits.',
                  );
                  return;
                }

                if (!pinRegex.hasMatch(confirmPin)) {
                  _showMessage(
                    'Invalid confirmation',
                    'Confirm PIN must contain 4 to 6 digits.',
                  );
                  return;
                }

                if (newPin != confirmPin) {
                  _showMessage(
                    'PIN does not match',
                    'New PIN and confirmation must be the same.',
                  );
                  return;
                }

                if (currentPin == newPin) {
                  _showMessage(
                    'Choose a different PIN',
                    'New PIN must be different from your current PIN.',
                  );
                  return;
                }

                final valid = await AppLockService.verifyPin(currentPin);

                if (!valid) {
                  if (!context.mounted) return;

                  _showMessage(
                    'Incorrect PIN',
                    'Your current App Lock PIN is incorrect.',
                  );
                  return;
                }

                await AppLockService.changePin(newPin);

                if (!context.mounted) return;

                Navigator.pop(dialogContext);

                _showMessage(
                  'PIN changed',
                  'Your App Lock PIN has been changed successfully.',
                );
              },
              child: const Text('Change PIN'),
            ),
          ],
        );
      },
    );
  }

  void _showPasswordSecurity() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Password & Security',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.password_outlined),
                title: const Text('Change password'),
                subtitle: const Text('Update your Gapshap password'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _changePassword();
                },
              ),
              ListTile(
                leading: const Icon(Icons.devices_outlined),
                title: const Text('Where you are logged in'),
                subtitle: const Text('Manage active sessions'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ActiveSessionsScreen()));
                },
              ),
              const SizedBox(height: 15),
            ],
          ),
        );
      },
    );
  }

  Future<void> _changePassword() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user?.email == null) {
      _showMessage(
        'Unable to change password',
        'No email is associated with this account.',
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);

      if (!context.mounted) return;

      _showMessage(
        'Password reset email sent',
        'Check your email to create a new password.',
      );
    } catch (e) {
      debugPrint('Password reset error: $e');

      if (!context.mounted) return;

      _showMessage('Error', 'Unable to send password reset email.');
    }
  }

  void _showPrivacySettings() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        bool showOnline = true;
        bool showLastSeen = true;
        bool readReceipts = true;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Privacy',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('Online status'),
                    subtitle: const Text(
                      'Allow others to see when you are online',
                    ),
                    value: showOnline,
                    onChanged: (value) {
                      setSheetState(() {
                        showOnline = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Last seen'),
                    subtitle: const Text('Show your last active time'),
                    value: showLastSeen,
                    onChanged: (value) {
                      setSheetState(() {
                        showLastSeen = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Read receipts'),
                    subtitle: const Text('Show when messages are read'),
                    value: readReceipts,
                    onChanged: (value) {
                      setSheetState(() {
                        readReceipts = value;
                      });
                    },
                  ),
                  const SizedBox(height: 15),
                ],
              ),
            );
          },
        );
      },
    );
  }



  void _showStorageDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.storage_outlined),
              SizedBox(width: 10),
              Text('Storage'),
            ],
          ),
          content: const Text(
            'Storage management will allow you to view cached photos, '
            'videos and other Gapshap media.',
          ),
          actions: [
            TextButton(
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

  void _showReportDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Report a problem'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Describe the problem...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                controller.dispose();
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final report = controller.text.trim();

                controller.dispose();
                Navigator.pop(dialogContext);

                _showMessage(
                  'Thank you',
                  report.isEmpty
                      ? 'Your report has been received.'
                      : 'Your report has been received.',
                );
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'KREVZY',
      applicationVersion: '1.0.0',
      applicationIcon: const CircleAvatar(
        child: Icon(Icons.chat_bubble_outline),
      ),
      children: const [
        SizedBox(height: 10),
        Text('Connect • Share • Chat'),
        SizedBox(height: 10),
        Text(
          'Gapshap is a social communication app focused on '
          'sharing, conversations and private chats.',
        ),
      ],
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Log out?'),
          content: const Text('Are you sure you want to log out of Gapshap?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                if (!context.mounted) return;

                setState(() {
                  _isLoggingOut = true;
                });

                try {
                  await SessionService.endSession();
                  await FirebaseAuth.instance.signOut();
                } catch (e) {
                  debugPrint('Logout Error: $e');

                  if (!context.mounted) return;

                  setState(() {
                    _isLoggingOut = false;
                  });

                  _showMessage(
                    'Logout failed',
                    'Unable to logout completely. Please try again.',
                  );
                }
              },
              child: const Text('Log out'),
            ),
          ],
        );
      },
    );
  }

  void _showComingSoon(String feature) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(feature),
          content: Text(
            '$feature will be available in a future Gapshap update.',
          ),
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
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
      leading: CircleAvatar(
        radius: 21,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Icon(icon, size: 21),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right, size: 22),
      onTap: onTap,
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
      leading: CircleAvatar(
        radius: 21,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Icon(icon, size: 21),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: Switch(value: value, onChanged: enabled ? onChanged : null),
    );
  }
}

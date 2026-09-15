import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SecurityCenterScreen extends StatefulWidget {
  const SecurityCenterScreen({super.key});

  @override
  State<SecurityCenterScreen> createState() => _SecurityCenterScreenState();
}

class _SecurityCenterScreenState extends State<SecurityCenterScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _loading = false;

  User? get _user => _auth.currentUser;

  Future<void> _sendPasswordReset() async {
    final user = _user;

    if (user == null || user.email == null) {
      _showMessage(
        'No email address is linked to this account.',
        isError: true,
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await _auth.sendPasswordResetEmail(email: user.email!);

      if (!mounted) return;

      _showMessage('Password reset email sent to ${user.email}.');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      _showMessage(_authErrorMessage(e), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _sendEmailVerification() async {
    final user = _user;

    if (user == null) {
      return;
    }

    if (user.emailVerified) {
      _showMessage('Your email is already verified.');
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await user.sendEmailVerification();

      if (!mounted) return;

      _showMessage('Verification email sent. Check your inbox.');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      _showMessage(_authErrorMessage(e), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _refreshUser() async {
    final user = _user;

    if (user == null) {
      return;
    }

    await user.reload();

    if (!mounted) return;

    setState(() {});

    _showMessage('Security status refreshed.');
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout?'),
          content: const Text('Are you sure you want to logout from KREVZY?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _loading = true;
    });

    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      _showMessage(_authErrorMessage(e), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _deleteAccount() async {
    final user = _user;

    if (user == null) {
      return;
    }

    final errorColor = Theme.of(context).colorScheme.error;

    final onErrorColor = Theme.of(context).colorScheme.onError;

    final errorContainerColor = Theme.of(context).colorScheme.errorContainer;

    final onErrorContainerColor = Theme.of(context)
        .colorScheme
        .onErrorContainer;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete account?'),
          content: const Text(
            'This will permanently delete your KREVZY '
            'authentication account. This action cannot '
            'be undone.\n\n'
            'Please make sure you really want to continue.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: errorColor,
                foregroundColor: onErrorColor,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Delete Account'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    if (!mounted) return;

    final passwordController = TextEditingController();

    final password = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        bool obscure = true;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Confirm your password'),
              content: TextField(
                controller: passwordController,
                obscureText: obscure,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setDialogState(() {
                        obscure = !obscure;
                      });
                    },
                    icon: Icon(
                      obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: errorColor,
                    foregroundColor: onErrorColor,
                  ),
                  onPressed: () {
                    final value = passwordController.text.trim();

                    if (value.isEmpty) {
                      return;
                    }

                    Navigator.of(dialogContext).pop(value);
                  },
                  child: const Text('Continue'),
                ),
              ],
            );
          },
        );
      },
    );

    passwordController.dispose();

    if (password == null || password.isEmpty) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _loading = true;
    });

    try {
      final email = user.email;

      if (email == null || email.isEmpty) {
        throw FirebaseAuthException(
          code: 'missing-email',
          message: 'No email address is available for re-authentication.',
        );
      }

      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);

      await _firestore.collection('users').doc(user.uid).delete();

      await user.delete();

      if (!mounted) return;

      _showMessage('Account deleted successfully.');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      _showMessage(_authErrorMessage(e), isError: true);
    } on FirebaseException catch (e) {
      if (!mounted) return;

      _showMessage(e.message ?? 'Account deletion failed.', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }

    // Keep these variables referenced so the
    // captured security colors remain intentional.
    errorContainerColor;
    onErrorContainerColor;
  }

  String _authErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect password. Please try again.';

      case 'user-not-found':
        return 'No account was found for this email.';

      case 'invalid-email':
        return 'The email address is invalid.';

      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';

      case 'requires-recent-login':
        return 'For security, please login again and retry.';

      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';

      case 'email-already-in-use':
        return 'This email is already in use.';

      case 'missing-email':
        return 'No email address is linked to this account.';

      default:
        return error.message ?? 'Something went wrong. Please try again.';
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    final backgroundColor = isError
        ? Theme.of(context).colorScheme.error
        : null;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), backgroundColor: backgroundColor),
      );
  }

  Widget _securityCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle),
        ),
        trailing: trailing,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;

    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F7FF),
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          title: const Text('Security Center'),
        ),
        body: const Center(child: Text('Please login to manage security.')),
      );
    }

    final email = user.email ?? 'No email';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F7FF),
        surfaceTintColor: const Color(0xFFF8F7FF),
        title: const Text(
          'Security Center',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refreshUser,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 34,
                          child: Icon(
                            Icons.shield_rounded,
                            size: 38,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Security Center',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Manage your KREVZY account security.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Account Security',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _securityCard(
                  context: context,
                  icon: Icons.email_outlined,
                  title: 'Email Address',
                  subtitle: email,
                  trailing: user.emailVerified
                      ? const Icon(Icons.verified_rounded)
                      : TextButton(
                          onPressed: _loading ? null : _sendEmailVerification,
                          child: const Text('Verify'),
                        ),
                ),
                _securityCard(
                  context: context,
                  icon: Icons.lock_reset_rounded,
                  title: 'Password',
                  subtitle: 'Send a secure password reset link.',
                  trailing: IconButton(
                    tooltip: 'Reset password',
                    onPressed: _loading ? null : _sendPasswordReset,
                    icon: const Icon(Icons.arrow_forward_ios_rounded),
                  ),
                ),
                _securityCard(
                  context: context,
                  icon: Icons.security_rounded,
                  title: 'Security Status',
                  subtitle: user.emailVerified
                      ? 'Email verified • Account protected'
                      : 'Email verification is pending',
                  trailing: Icon(
                    user.emailVerified
                        ? Icons.check_circle_rounded
                        : Icons.warning_amber_rounded,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Account Actions',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.logout_rounded),
                    ),
                    title: const Text(
                      'Logout',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text('Sign out from this device.'),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded),
                    onTap: _loading ? null : _logout,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .errorContainer,
                      child: Icon(
                        Icons.delete_forever_rounded,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                    title: Text(
                      'Delete Account',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    subtitle: const Text(
                      'Permanently delete your KREVZY account.',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded),
                    onTap: _loading ? null : _deleteAccount,
                  ),
                ),
                const SizedBox(height: 28),
                Center(
                  child: Text(
                    'KREVZY Security',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          if (_loading)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x33000000),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _sending = false;
  bool _checking = false;
  String? _status;

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _sendVerificationEmail(silent: true);
  }

  Future<void> _sendVerificationEmail({bool silent = false}) async {
    final user = _user;
    if (user == null) return;
    if (_sending) return;

    setState(() => _sending = true);
    try {
      await user.sendEmailVerification().timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw FirebaseAuthException(
          code: 'verification-email-timeout',
          message: 'Verification email request timed out.',
        ),
      );
      if (!mounted) return;
      setState(
        () => _status =
            'Verification email sent to ${user.email}. Check Spam/Junk/Promotions too.',
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('VERIFICATION EMAIL ERROR: ${e.code} | ${e.message}');
      if (!mounted) return;
      setState(() => _status = _authMessage(e));
    } catch (e) {
      debugPrint('VERIFICATION EMAIL ERROR: $e');
      if (!mounted) return;
      setState(() => _status = 'Could not send verification email: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _authMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'too-many-requests':
        return 'Too many requests. Thodi der baad Resend try karo.';
      case 'network-request-failed':
        return 'Internet connection check karo.';
      case 'user-disabled':
        return 'This account is disabled.';
      case 'verification-email-timeout':
        return 'Firebase response timeout. Internet check karke Resend try karo.';
      default:
        return 'Firebase Error: ${e.code}\n${e.message ?? 'Unknown error'}';
    }
  }

  Future<void> _checkVerification() async {
    final user = _user;
    if (user == null) return;
    if (_checking) return;

    setState(() => _checking = true);
    try {
      await user.reload();
      final refreshed = FirebaseAuth.instance.currentUser;
      if (refreshed == null) return;

      debugPrint(
        'VERIFICATION CHECK: emailVerified=${refreshed.emailVerified}',
      );

      if (!refreshed.emailVerified) {
        if (mounted) {
          setState(
            () => _status = 'Email abhi verify nahi hua. Pehle verification link open karo.',
          );
        }
        return;
      }

      // Force a fresh ID token so Firestore security rules see the
      // newly updated email_verified claim immediately.
      await refreshed.getIdToken(true);
      await _createProfileAfterVerification(refreshed);
    } on FirebaseAuthException catch (e) {
      debugPrint('VERIFICATION CHECK AUTH ERROR: ${e.code} | ${e.message}');
      if (mounted) setState(() => _status = _authMessage(e));
    } on FirebaseException catch (e) {
      debugPrint('VERIFICATION CHECK FIREBASE ERROR: ${e.code} | ${e.message}');
      if (mounted) {
        setState(
          () => _status = 'Firebase Error: ${e.code}\n${e.message ?? ''}',
        );
      }
    } catch (e) {
      debugPrint('VERIFICATION CHECK ERROR: $e');
      if (mounted) setState(() => _status = 'Verification check failed: $e');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _createProfileAfterVerification(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final name =
        prefs.getString('pending_signup_name') ?? user.displayName ?? '';
    final username = prefs.getString('pending_signup_username') ?? '';
    final email = prefs.getString('pending_signup_email') ?? user.email ?? '';

    if (username.isEmpty || name.isEmpty || email.isEmpty) {
      // Existing verified accounts can still enter the app without pending signup data.
      return;
    }

    final firestore = FirebaseFirestore.instance;
    final profileRef = firestore.collection('users').doc(user.uid);
    final existing = await profileRef.get();

    if (!existing.exists) {
      final usernameQuery = await firestore
          .collection('users')
          .where('usernameLowercase', isEqualTo: username)
          .limit(1)
          .get();

      if (usernameQuery.docs.any((doc) => doc.id != user.uid)) {
        if (mounted) {
          setState(
            () => _status =
                'Username @$username is already taken. Logout karke another username se account create karo.',
          );
        }
        return;
      }

      await profileRef.set({
        'uid': user.uid,
        'name': name,
        'nameLowercase': name.toLowerCase(),
        'username': username,
        'usernameLowercase': username,
        'email': email,
        'bio': '',
        'photoUrl': '',
        'postsCount': 0,
        'followersCount': 0,
        'followingCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await prefs.remove('pending_signup_name');
    await prefs.remove('pending_signup_username');
    await prefs.remove('pending_signup_email');

    if (!mounted) return;
    setState(() => _status = 'Email verified successfully. Profile created.');
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final email = _user?.email ?? '';
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  const Icon(Icons.mark_email_read_outlined, size: 88),
                  const SizedBox(height: 20),
                  Text(
                    'Verify your email',
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'We sent a verification link to:\n$email',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Inbox ke saath Spam, Junk aur Promotions folder bhi check karo. Link open karne ke baad yahan “I Verified My Email” press karo.',
                      ),
                    ),
                  ),
                  if (_status != null) ...[
                    const SizedBox(height: 16),
                    Text(_status!, textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: _checking ? null : _checkVerification,
                      icon: _checking
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.verified_outlined),
                      label: Text(
                        _checking ? 'Checking...' : 'I Verified My Email',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _sending
                          ? null
                          : () => _sendVerificationEmail(),
                      icon: _sending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      label: Text(
                        _sending ? 'Sending...' : 'Resend Verification Email',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Use another account'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

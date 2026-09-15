import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isSendingReset = false;
  bool _obscurePassword = true;

  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // LOGIN
  // ------------------------------------------------------------

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final String email = _emailController.text.trim();
    final String password = _passwordController.text;

    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = credential.user;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'login-failed',
          message: 'Unable to sign in. Please try again.',
        );
      }

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // ----------------------------------------------------------
      // SUCCESS
      // ----------------------------------------------------------

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = _firebaseLoginError(e);
      });

      debugPrint('Login Error Code: ${e.code}');
      debugPrint('Login Error Message: ${e.message}');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Something went wrong. Please try again.';
      });

      debugPrint('Login Unknown Error: $e');
    }
  }

  // ------------------------------------------------------------
  // FIREBASE ERROR HANDLER
  // ------------------------------------------------------------

  String _firebaseLoginError(FirebaseAuthException e) {
    switch (e.code.toLowerCase()) {
      case 'invalid-credential':
        return 'Incorrect email or password. Please check your details and try again.';

      case 'wrong-password':
        return 'Incorrect password. Please try again or use Forgot Password.';

      case 'user-not-found':
        return 'No account was found with this email address. Please sign up first.';

      case 'invalid-email':
        return 'Please enter a valid email address.';

      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';

      case 'too-many-requests':
        return 'Too many unsuccessful attempts. Please wait a while and try again.';

      case 'operation-not-allowed':
        return 'Email and password sign-in is currently disabled in Firebase.';

      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';

      case 'internal-error':
        return 'Firebase encountered an internal error. Please try again.';

      case 'requires-recent-login':
        return 'Please sign in again to continue.';

      case 'login-failed':
        return e.message ?? 'Unable to sign in. Please try again.';

      default:
        return e.message?.isNotEmpty == true
            ? e.message!
            : 'Unable to sign in. Please check your email and password.';
    }
  }

  // ------------------------------------------------------------
  // FORGOT PASSWORD
  // ------------------------------------------------------------

  Future<void> _forgotPassword() async {
    FocusScope.of(context).unfocus();

    final String email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Enter your email address first.';
        _successMessage = null;
      });
      return;
    }

    if (!_isValidEmail(email)) {
      setState(() {
        _errorMessage = 'Please enter a valid email address.';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isSendingReset = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await _auth.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      setState(() {
        _isSendingReset = false;
        _successMessage = 'Password reset email sent. Please check your inbox.';
      });

      await _showMessageDialog(
        title: 'Check your email',
        message: 'We sent a password reset link to:\n\n$email',
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _isSendingReset = false;
        _errorMessage = _firebaseResetError(e);
      });

      debugPrint('Password Reset Error Code: ${e.code}');
      debugPrint('Password Reset Error Message: ${e.message}');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSendingReset = false;
        _errorMessage = 'Unable to send the reset email. Please try again.';
      });

      debugPrint('Password Reset Unknown Error: $e');
    }
  }

  String _firebaseResetError(FirebaseAuthException e) {
    switch (e.code.toLowerCase()) {
      case 'invalid-email':
        return 'Please enter a valid email address.';

      case 'user-not-found':
        return 'No account was found with this email address.';

      case 'too-many-requests':
        return 'Too many requests. Please wait and try again later.';

      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';

      case 'operation-not-allowed':
        return 'Password reset is not enabled for this Firebase project.';

      default:
        return e.message?.isNotEmpty == true
            ? e.message!
            : 'Unable to send password reset email.';
    }
  }

  // ------------------------------------------------------------
  // VALIDATION
  // ------------------------------------------------------------

  bool _isValidEmail(String value) {
    final RegExp emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    return emailRegex.hasMatch(value);
  }

  String? _validateEmail(String? value) {
    final String email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Email is required';
    }

    if (!_isValidEmail(email)) {
      return 'Enter a valid email address';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final String password = value ?? '';

    if (password.isEmpty) {
      return 'Password is required';
    }

    if (password.length < 6) {
      return 'Password must contain at least 6 characters';
    }

    return null;
  }

  // ------------------------------------------------------------
  // DIALOG
  // ------------------------------------------------------------

  Future<void> _showMessageDialog({
    required String title,
    required String message,
  }) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------
  // SIGN UP
  // ------------------------------------------------------------

  void _openSignUp() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const SignupScreen()));
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 470),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ------------------------------------------------
                    // LOGO
                    // ------------------------------------------------

                    _buildLogo(),

                    const SizedBox(height: 28),

                    const Text(
                      'Welcome back',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF20202A),
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Log in to continue to Krevzy',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: Color(0xFF666472)),
                    ),

                    const SizedBox(height: 30),

                    // ------------------------------------------------
                    // ERROR
                    // ------------------------------------------------
                    if (_errorMessage != null) _buildErrorBox(_errorMessage!),

                    if (_successMessage != null)
                      _buildSuccessBox(_successMessage!),

                    if (_errorMessage != null || _successMessage != null)
                      const SizedBox(height: 16),

                    // ------------------------------------------------
                    // EMAIL
                    // ------------------------------------------------
                    const Text(
                      'Email',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF30303A),
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      enabled: !_isLoading && !_isSendingReset,
                      validator: _validateEmail,
                      decoration: _inputDecoration(
                        hint: 'Enter your email',
                        icon: Icons.email_outlined,
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ------------------------------------------------
                    // PASSWORD
                    // ------------------------------------------------
                    const Text(
                      'Password',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF30303A),
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      enabled: !_isLoading && !_isSendingReset,
                      validator: _validatePassword,
                      onFieldSubmitted: (_) {
                        if (!_isLoading) {
                          _login();
                        }
                      },
                      decoration:
                          _inputDecoration(
                            hint: 'Enter your password',
                            icon: Icons.lock_outline,
                          ).copyWith(
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword
                                  ? 'Show password'
                                  : 'Hide password',
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                    ),

                    const SizedBox(height: 8),

                    // ------------------------------------------------
                    // FORGOT PASSWORD
                    // ------------------------------------------------
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isSendingReset || _isLoading
                            ? null
                            : _forgotPassword,
                        child: _isSendingReset
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Forgot password?',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF625B9B),
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ------------------------------------------------
                    // LOGIN BUTTON
                    // ------------------------------------------------
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading || _isSendingReset
                            ? null
                            : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF625B9B),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFB9B5D0),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Log In',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 26),

                    // ------------------------------------------------
                    // DIVIDER
                    // ------------------------------------------------
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              color: Color(0xFF777580),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ------------------------------------------------
                    // SIGN UP
                    // ------------------------------------------------
                    OutlinedButton(
                      onPressed: _isLoading ? null : _openSignUp,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        foregroundColor: const Color(0xFF625B9B),
                        side: const BorderSide(
                          color: Color(0xFF625B9B),
                          width: 1.3,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Create New Account',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    const Text(
                      'By continuing, you agree to the Krevzy Terms of Service and Privacy Policy.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.5,
                        color: Color(0xFF85828F),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // LOGO
  // ------------------------------------------------------------

  Widget _buildLogo() {
    return Center(
      child: Container(
        width: 82,
        height: 82,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF8B84C7), Color(0xFF625B9B)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF625B9B).withValues(alpha: 0.18),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'K',
            style: TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // INPUT DECORATION
  // ------------------------------------------------------------

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF77728F)),
      filled: true,
      fillColor: const Color(0xFFF0EEFF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF625B9B), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  // ------------------------------------------------------------
  // ERROR BOX
  // ------------------------------------------------------------

  Widget _buildErrorBox(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD0D0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFD64545), size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF9B3030),
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            onPressed: () {
              setState(() {
                _errorMessage = null;
              });
            },
            icon: const Icon(Icons.close, size: 18, color: Color(0xFF9B3030)),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // SUCCESS BOX
  // ------------------------------------------------------------

  Widget _buildSuccessBox(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFFAF2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCBEAD2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: Color(0xFF2E8B57),
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF246B42),
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

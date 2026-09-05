import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/session_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Start Gapshap session.
      await SessionService.startSession();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'Login Error Code: ${e.code}',
      );

      debugPrint(
        'Login Error Message: ${e.message}',
      );

      if (!mounted) return;

      String message =
          'Login failed. Please try again.';

      switch (e.code) {
        case 'invalid-credential':
          message =
              'Email ya password galat hai.';
          break;

        case 'invalid-email':
          message =
              'Please enter a valid email address.';
          break;

        case 'user-not-found':
          message =
              'Is email se koi account nahi mila.';
          break;

        case 'wrong-password':
          message =
              'Password galat hai.';
          break;

        case 'user-disabled':
          message =
              'Ye account disabled hai.';
          break;

        case 'too-many-requests':
          message =
              'Too many attempts. Thodi der baad try karo.';
          break;

        case 'network-request-failed':
          message =
              'Internet connection check karo.';
          break;

        default:
          message =
              'Firebase Error: ${e.code}\n'
              '${e.message ?? "Unknown error"}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      debugPrint(
        'Unexpected login error: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Something went wrong: $e',
          ),
        ),
      );
    }

    if (!mounted) return;

    setState(() {
      _loading = false;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 450,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.chat_bubble_rounded,
                      size: 70,
                      color: Color(0xFF7C3AED),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Welcome Back 👋',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Login to your Gapshap account',
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 35),

                    TextFormField(
                      controller: _emailController,
                      keyboardType:
                          TextInputType.emailAddress,
                      textInputAction:
                          TextInputAction.next,
                      decoration:
                          const InputDecoration(
                        labelText: 'Email',
                        hintText:
                            'Enter your email',
                        prefixIcon: Icon(
                          Icons.email_outlined,
                        ),
                        border:
                            OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Email enter karo';
                        }

                        if (!value.contains('@')) {
                          return 'Valid email enter karo';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 18),

                    TextFormField(
                      controller:
                          _passwordController,
                      obscureText:
                          _obscurePassword,
                      textInputAction:
                          TextInputAction.done,
                      onFieldSubmitted: (_) {
                        if (!_loading) {
                          _login();
                        }
                      },
                      decoration:
                          InputDecoration(
                        labelText: 'Password',
                        hintText:
                            'Enter your password',
                        prefixIcon:
                            const Icon(
                          Icons.lock_outline,
                        ),
                        suffixIcon:
                            IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword =
                                  !_obscurePassword;
                            });
                          },
                        ),
                        border:
                            const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty) {
                          return 'Password enter karo';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 10),

                    Align(
                      alignment:
                          Alignment.centerRight,
                      child: TextButton(
                        onPressed: _loading
                            ? null
                            : () {
                                ScaffoldMessenger
                                    .of(context)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Forgot Password next step mein add karenge.',
                                    ),
                                  ),
                                );
                              },
                        child: const Text(
                          'Forgot Password?',
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed:
                            _loading ? null : _login,
                        child: _loading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Login',
                                style:
                                    TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    Row(
                      children: [
                        const Expanded(
                          child: Divider(),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              color:
                                  Colors.grey.shade600,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Divider(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    OutlinedButton.icon(
                      onPressed: _loading
                          ? null
                          : () {
                              ScaffoldMessenger
                                  .of(context)
                                  .showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Google Login next step mein add karenge.',
                                  ),
                                ),
                              );
                            },
                      icon: const Icon(
                        Icons.login,
                      ),
                      label: const Text(
                        'Continue with Google',
                      ),
                    ),

                    const SizedBox(height: 25),

                    // FIX:
                    // Flexible prevents the Row from overflowing
                    // on narrow screens.
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            'New to Gapshap? ',
                            textAlign: TextAlign.end,
                            overflow:
                                TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          onPressed: _loading
                              ? null
                              : () {
                                  Navigator.pop(
                                    context,
                                  );
                                },
                          child: const Text(
                            'Create Account',
                          ),
                        ),
                      ],
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
}
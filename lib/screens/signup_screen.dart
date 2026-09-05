import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/session_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _agreeToTerms = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ============================================================
  // CREATE ACCOUNT
  // ============================================================

  Future<void> createAccount() async {
    if (_isLoading) {
      return;
    }

    final form = _formKey.currentState;

    if (form == null || !form.validate()) {
      return;
    }

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the Terms & Privacy Policy'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    User? createdUser;

    try {
      final name = _nameController.text.trim();

      final username = _usernameController.text.trim().toLowerCase();

      final email = _emailController.text.trim();

      final password = _passwordController.text;

      final nameLowercase = name.toLowerCase();

      final usernameLowercase = username;

      debugPrint('SIGNUP STARTED');

      // ========================================================
      // STEP 1: CREATE FIREBASE AUTH ACCOUNT
      // ========================================================

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      createdUser = userCredential.user;

      if (createdUser == null) {
        throw Exception('Unable to create user account.');
      }

      debugPrint('AUTH ACCOUNT CREATED: ${createdUser.uid}');

      // ========================================================
      // STEP 2: CHECK USERNAME
      // ========================================================

      final usernameQuery = await _firestore
          .collection('users')
          .where('usernameLowercase', isEqualTo: usernameLowercase)
          .limit(1)
          .get();

      if (usernameQuery.docs.isNotEmpty) {
        await createdUser.delete();
        createdUser = null;

        if (!mounted) {
          return;
        }

        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This username is already taken.')),
        );

        return;
      }

      // ========================================================
      // STEP 3: SAVE DISPLAY NAME IN FIREBASE AUTH
      // ========================================================

      await createdUser.updateDisplayName(name);

      debugPrint('AUTH DISPLAY NAME UPDATED');

      // ========================================================
      // STEP 4: SAVE USER PROFILE IN FIRESTORE
      // ========================================================

      await _firestore.collection('users').doc(createdUser.uid).set({
        'uid': createdUser.uid,
        'name': name,
        'nameLowercase': nameLowercase,
        'username': username,
        'usernameLowercase': usernameLowercase,
        'email': email,
        'bio': '',
        'photoUrl': '',
        'postsCount': 0,
        'followersCount': 0,
        'followingCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('FIRESTORE PROFILE CREATED');

      // ========================================================
      // STEP 5: RELOAD USER
      // ========================================================

      await createdUser.reload();

      debugPrint('FIREBASE USER RELOADED');

      // ========================================================
      // STEP 6: START GAPSHAP SESSION
      // ========================================================

      await SessionService.startSession();

      debugPrint('GAPSHAP SESSION STARTED');

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully!'),
          duration: Duration(seconds: 2),
        ),
      );

      // IMPORTANT:
      // Do NOT call Navigator.pop() here.
      //
      // FirebaseAuth.authStateChanges() in AuthGate will
      // automatically detect the newly signed-in user and
      // show HomeScreen.
      debugPrint('SIGNUP COMPLETE - AUTH GATE WILL OPEN HOME');
    }
    // ============================================================
    // FIREBASE AUTH ERROR
    // ============================================================
    on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error: ${e.code}');

      debugPrint('Firebase Auth Message: ${e.message}');

      if (!mounted) {
        return;
      }

      String message;

      switch (e.code) {
        case 'email-already-in-use':
          message = 'This email is already registered.';
          break;

        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;

        case 'weak-password':
          message = 'Password is too weak. Use at least 6 characters.';
          break;

        case 'operation-not-allowed':
          message = 'Email/Password login is not enabled in Firebase.';
          break;

        case 'network-request-failed':
          message = 'Network error. Please check your internet.';
          break;

        case 'too-many-requests':
          message = 'Too many attempts. Please try again later.';
          break;

        case 'user-disabled':
          message = 'This account has been disabled.';
          break;

        default:
          message =
              'Firebase Error: ${e.code}\n'
              '${e.message ?? "Unknown error"}';
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 6)),
      );
    }
    // ============================================================
    // FIRESTORE ERROR
    // ============================================================
    on FirebaseException catch (e) {
      debugPrint('Firestore/Firebase Error: ${e.code}');

      debugPrint('Firestore/Firebase Message: ${e.message}');

      // Roll back Firebase Auth account if Firestore profile
      // could not be created.
      if (createdUser != null) {
        try {
          await createdUser.delete();

          debugPrint('AUTH ACCOUNT ROLLBACK SUCCESSFUL');
        } catch (rollbackError) {
          debugPrint(
            'AUTH ACCOUNT ROLLBACK FAILED: '
            '$rollbackError',
          );
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to save profile.\n'
            'Firebase Error: ${e.code}',
          ),
          duration: const Duration(seconds: 6),
        ),
      );
    }
    // ============================================================
    // GENERAL ERROR
    // ============================================================
    catch (e) {
      debugPrint('Signup Error: $e');

      if (createdUser != null) {
        try {
          await createdUser.delete();

          debugPrint('AUTH ACCOUNT ROLLBACK SUCCESSFUL');
        } catch (rollbackError) {
          debugPrint(
            'AUTH ACCOUNT ROLLBACK FAILED: '
            '$rollbackError',
          );
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Something went wrong:\n$e'),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account'), centerTitle: true),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ==================================================
                    // LOGO
                    // ==================================================

                    const Icon(
                      Icons.chat_bubble_rounded,
                      size: 70,
                      color: Color(0xFF7C3AED),
                    ),

                    const SizedBox(height: 16),

                    // ==================================================
                    // TITLE
                    // ==================================================
                    const Text(
                      'Join Gapshap',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Create your account and start chatting',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 15),
                    ),

                    const SizedBox(height: 32),

                    // ==================================================
                    // FULL NAME
                    // ==================================================
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        hintText: 'Enter your full name',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }

                        if (value.trim().length < 2) {
                          return 'Name is too short';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // ==================================================
                    // USERNAME
                    // ==================================================
                    TextFormField(
                      controller: _usernameController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        hintText: 'Choose a username',
                        prefixIcon: const Icon(Icons.alternate_email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a username';
                        }

                        final username = value.trim().toLowerCase();

                        if (username.length < 3) {
                          return 'Username must be at least 3 characters';
                        }

                        final regex = RegExp(r'^[a-z0-9._]+$');

                        if (!regex.hasMatch(username)) {
                          return 'Use only letters, numbers, . and _';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // ==================================================
                    // EMAIL
                    // ==================================================
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter your email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }

                        final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

                        if (!regex.hasMatch(value.trim())) {
                          return 'Please enter a valid email';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // ==================================================
                    // PASSWORD
                    // ==================================================
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Create a password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }

                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // ==================================================
                    // CONFIRM PASSWORD
                    // ==================================================
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) {
                        if (!_isLoading) {
                          createAccount();
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        hintText: 'Enter password again',
                        prefixIcon: const Icon(Icons.lock_reset_outlined),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }

                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // ==================================================
                    // TERMS
                    // ==================================================
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _agreeToTerms,
                          onChanged: _isLoading
                              ? null
                              : (value) {
                                  setState(() {
                                    _agreeToTerms = value ?? false;
                                  });
                                },
                        ),
                        const Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: Text(
                              'I agree to the Terms of Service and Privacy Policy',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ==================================================
                    // CREATE ACCOUNT BUTTON
                    // ==================================================
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : createAccount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ==================================================
                    // LOGIN
                    // ==================================================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(color: Colors.grey),
                        ),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  Navigator.pop(context);
                                },
                          child: const Text(
                            'Login',
                            style: TextStyle(fontWeight: FontWeight.bold),
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

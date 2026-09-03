import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/app_lock_screen.dart';
import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/app_lock_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const GapshapApp());
}

// ============================================================
// GAPSHAP APP
// ============================================================

class GapshapApp extends StatelessWidget {
  const GapshapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gapshap',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7C3AED)),
      ),
      home: const AppGate(),
    );
  }
}

// ============================================================
// APP GATE
// ============================================================

class AppGate extends StatefulWidget {
  const AppGate({super.key});

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> with WidgetsBindingObserver {
  StreamSubscription<User?>? _authSubscription;

  bool _isLoading = true;
  bool _appLockEnabled = false;
  bool _isUnlocked = false;

  AppLifecycleState? _lastLifecycleState;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _listenToAuthState();
  }

  // ==========================================================
  // FIREBASE AUTH STATE
  // ==========================================================

  void _listenToAuthState() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      _handleAuthStateChanged,
    );
  }

  Future<void> _handleAuthStateChanged(User? user) async {
    if (user == null) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _appLockEnabled = false;
        _isUnlocked = false;
      });

      return;
    }

    await _loadUserAppState(user);
  }

  // ==========================================================
  // LOAD USER APP STATE
  // ==========================================================

  Future<void> _loadUserAppState(User user) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    final enabled = await AppLockService.isEnabled();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _appLockEnabled = enabled;

      // If App Lock is enabled, require unlock.
      // Otherwise go directly to Home.
      _isUnlocked = !enabled;
    });
  }

  // ==========================================================
  // APP LIFECYCLE
  // ==========================================================

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    final previousState = _lastLifecycleState;

    _lastLifecycleState = state;

    if (state == AppLifecycleState.resumed &&
        previousState != null &&
        previousState != AppLifecycleState.resumed) {
      _lockOnResume();
    }
  }

  // ==========================================================
  // LOCK WHEN APP RESUMES
  // ==========================================================

  Future<void> _lockOnResume() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    // Don't unnecessarily lock while AppGate is loading.
    if (_isLoading) {
      return;
    }

    final enabled = await AppLockService.isEnabled();

    if (!mounted) return;

    if (enabled) {
      setState(() {
        _appLockEnabled = true;
        _isUnlocked = false;
      });
    }
  }

  // ==========================================================
  // APP UNLOCKED
  // ==========================================================

  void _handleUnlocked() {
    if (!mounted) return;

    setState(() {
      _isUnlocked = true;
    });
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _authSubscription?.cancel();

    super.dispose();
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    // --------------------------------------------------------
    // Loading
    // --------------------------------------------------------

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // --------------------------------------------------------
    // Firebase Auth User
    // --------------------------------------------------------

    final user = FirebaseAuth.instance.currentUser;

    // --------------------------------------------------------
    // Not logged in
    // --------------------------------------------------------

    if (user == null) {
      return const WelcomeScreen();
    }

    // --------------------------------------------------------
    // App Lock
    // --------------------------------------------------------

    if (_appLockEnabled && !_isUnlocked) {
      return AppLockScreen(onUnlocked: _handleUnlocked);
    }

    // --------------------------------------------------------
    // Logged in + unlocked
    // --------------------------------------------------------

    return const HomeScreen();
  }
}

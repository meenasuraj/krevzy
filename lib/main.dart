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

class AppGate extends StatefulWidget {
  const AppGate({super.key});

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> with WidgetsBindingObserver {
  bool _isLoading = true;
  bool _appLockEnabled = false;
  bool _isUnlocked = false;

  AppLifecycleState? _lastLifecycleState;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _checkAppState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkAppState() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _appLockEnabled = false;
        _isUnlocked = false;
      });

      return;
    }

    final enabled = await AppLockService.isEnabled();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _appLockEnabled = enabled;
      _isUnlocked = !enabled;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    final previousState = _lastLifecycleState;
    _lastLifecycleState = state;

    // App background / inactive hone ke baad
    // foreground mein aane par App Lock lagao.
    if (state == AppLifecycleState.resumed &&
        previousState != null &&
        previousState != AppLifecycleState.resumed) {
      _lockOnResume();
    }
  }

  Future<void> _lockOnResume() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
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

  void _handleUnlocked() {
    if (!mounted) return;

    setState(() {
      _isUnlocked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const WelcomeScreen();
    }

    if (_appLockEnabled && !_isUnlocked) {
      return AppLockScreen(onUnlocked: _handleUnlocked);
    }

    return const HomeScreen();
  }
}

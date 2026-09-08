import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/connectivity_service.dart';
import 'services/session_service.dart';
import 'widgets/krevzy_app_background.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await ConnectivityService.initialize();

  runApp(
    const GapshapApp(),
  );
}

class GapshapApp extends StatefulWidget {
  const GapshapApp({super.key});
  @override State<GapshapApp> createState() => _GapshapAppState();
}

class _GapshapAppState extends State<GapshapApp> with WidgetsBindingObserver {
  @override void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) { SessionService.ensureSession(); }
    });
  }
  @override void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  @override void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      SessionService.ensureSession();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      SessionService.markOffline();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KREVZY',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.transparent,
        canvasColor: Colors.transparent,

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.light,
        ).copyWith(
          surface: Colors.transparent,
          surfaceContainerHighest: const Color(0xB8FFFFFF),
        ),
      ),

      home: const ConnectivityWrapper(),
    );
  }
}

/// Handles connectivity and authentication before
/// showing the actual KREVZY application.
class ConnectivityWrapper extends StatelessWidget {
  const ConnectivityWrapper({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: ConnectivityService.statusStream,
      initialData: ConnectivityService.isOnline,
      builder: (context, connectivitySnapshot) {
        final isOnline = connectivitySnapshot.data ?? true;

        return Stack(
          fit: StackFit.expand,
          children: [
            KrevzyAppBackgroundHost(
              child: StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, authSnapshot) {
                  if (authSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Scaffold(
                      backgroundColor: Colors.transparent,
                      body: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (authSnapshot.data == null) {
                    return const LoginScreen();
                  }

                  return const HomeScreen();
                },
              ),
            ),

            if (!isOnline)
              const Positioned(
                left: 12,
                right: 12,
                bottom: 16,
                child: _OfflineBanner(),
              ),
          ],
        );
      },
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.8),
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 18,
              offset: const Offset(0, 8),
              color: Colors.black.withValues(alpha: 0.08),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 22,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'You are offline. Some features may be unavailable.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
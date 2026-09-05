import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/connectivity_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options:
        DefaultFirebaseOptions.currentPlatform,
  );

  await ConnectivityService.initialize();

  runApp(
    const GapshapApp(),
  );
}

class GapshapApp extends StatelessWidget {
  const GapshapApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GAPSHAP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      home: const ConnectivityWrapper(),
    );
  }
}

class ConnectivityWrapper
    extends StatelessWidget {
  const ConnectivityWrapper({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const AuthGate(),

        StreamBuilder<bool>(
          stream:
              ConnectivityService.statusStream,
          initialData:
              ConnectivityService.isOnline,
          builder:
              (context, snapshot) {
            final isOnline =
                snapshot.data ?? true;

            if (isOnline) {
              return const SizedBox.shrink();
            }

            return const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child:
                  OfflineBanner(),
            );
          },
        ),
      ],
    );
  }
}

class OfflineBanner
    extends StatelessWidget {
  const OfflineBanner({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.red.shade700,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.wifi_off,
                color: Colors.white,
                size: 21,
              ),
              const SizedBox(
                width: 10,
              ),
              const Expanded(
                child: Text(
                  'No internet connection',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
              Text(
                'Offline',
                style: TextStyle(
                  color:
                      Colors.white.withValues(
                    alpha: 0.85,
                  ),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthGate
    extends StatelessWidget {
  const AuthGate({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream:
          FirebaseAuth.instance
              .authStateChanges(),
      builder:
          (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child:
                  CircularProgressIndicator(),
            ),
          );
        }

        final user =
            snapshot.data;

        if (user != null) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
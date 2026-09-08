import 'package:flutter/material.dart';
import '../../../core/config/app_config.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.forum_rounded, size: 72),
                const SizedBox(height: 20),
                Text(AppConfig.appName,
                    style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 8),
                Text(AppConfig.tagline, textAlign: TextAlign.center),
                const SizedBox(height: 32),
                FilledButton(onPressed: () {},
                    child: const Text('Create Account')),
                const SizedBox(height: 12),
                OutlinedButton(onPressed: () {},
                    child: const Text('Login')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

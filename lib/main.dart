import 'package:flutter/material.dart';
import 'utils/app_theme_data.dart';
import 'screens/main_navigation.dart';

void main() {
  runApp(const SecurityTechCreatorApp());
}

class SecurityTechCreatorApp extends StatelessWidget {
  const SecurityTechCreatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = AppThemeNotifier.instance;

    return AnimatedBuilder(
      animation: themeNotifier,
      builder: (context, child) {
        return MaterialApp(
          title: 'Security Tech & Creator Studio',
          debugShowCheckedModeBanner: false,
          themeMode: themeNotifier.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: themeNotifier.primaryColor,
              brightness: Brightness.light,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: themeNotifier.primaryColor,
              brightness: Brightness.dark,
            ),
          ),
          home: const MainNavigation(),
        );
      },
    );
  }
}
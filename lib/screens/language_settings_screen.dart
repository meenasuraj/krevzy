import 'package:flutter/material.dart';
import '../utils/app_theme_data.dart';

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  final List<Map<String, String>> _languages = const [
    {'name': 'English', 'native': 'English', 'code': 'English (EN)'},
    {'name': 'Hindi', 'native': 'हिन्दी', 'code': 'Hindi (HI)'},
    {'name': 'Marathi', 'native': 'मराठी', 'code': 'Marathi (MR)'},
    {'name': 'Gujarati', 'native': 'ગુજરાતી', 'code': 'Gujarati (GU)'},
    {'name': 'Punjabi', 'native': 'ਪੰਜਾਬੀ', 'code': 'Punjabi (PA)'},
    {'name': 'Bengali', 'native': 'বাংলা', 'code': 'Bengali (BN)'},
  ];

  @override
  Widget build(BuildContext context) {
    final themeNotifier = AppThemeNotifier.instance;

    return AnimatedBuilder(
      animation: themeNotifier,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: themeNotifier.isDarkMode ? const Color(0xFF181818) : Colors.grey[100],
          appBar: AppBar(
            title: const Text('App Language', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: themeNotifier.primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: _languages.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final lang = _languages[index];
              final String code = lang['code']!;
              final bool isSelected = themeNotifier.currentLanguage == code;

              return Container(
                decoration: BoxDecoration(
                  color: themeNotifier.isDarkMode ? const Color(0xFF242424) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? themeNotifier.primaryColor : Colors.transparent,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(
                    lang['name']!,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: themeNotifier.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    lang['native']!,
                    style: TextStyle(
                      fontSize: 13,
                      color: themeNotifier.isDarkMode ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: themeNotifier.primaryColor, size: 22)
                      : const Icon(Icons.radio_button_unchecked, color: Colors.grey, size: 20),
                  onTap: () {
                    themeNotifier.setLanguage(code);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Language changed to ${lang['name']}')),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}
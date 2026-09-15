import 'package:flutter/material.dart';

class AppThemeNotifier extends ChangeNotifier {
  static final AppThemeNotifier instance = AppThemeNotifier._internal();
  AppThemeNotifier._internal();

  bool _isDarkMode = true;
  Color _primaryColor = const Color(0xFF1E88E5);
  String _currentLanguage = 'English';
  Color _chatBackgroundColor = const Color(0xFF121212);

  bool get isDarkMode => _isDarkMode;
  Color get primaryColor => _primaryColor;
  String get currentLanguage => _currentLanguage;
  Color get chatBackgroundColor => _chatBackgroundColor;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void toggleDarkMode(bool value) {
    _isDarkMode = value;
    notifyListeners();
  }

  void setThemeMode(bool isDark) {
    _isDarkMode = isDark;
    notifyListeners();
  }

  void setPrimaryColor(Color color) {
    _primaryColor = color;
    notifyListeners();
  }

  void setLanguage(String language) {
    _currentLanguage = language;
    notifyListeners();
  }

  void setChatBackground(Color color) {
    _chatBackgroundColor = color;
    notifyListeners();
  }
}
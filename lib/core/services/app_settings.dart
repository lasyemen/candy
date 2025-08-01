import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  static const String _themeKey = 'selected_theme';

  String _currentLanguage = 'ar';
  ThemeMode _currentTheme = ThemeMode.light;

  String get currentLanguage => _currentLanguage;
  ThemeMode get currentTheme => _currentTheme;

  AppSettings() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString(_languageKey) ?? 'ar';
    final themeString = prefs.getString(_themeKey) ?? 'light';
    _currentTheme = _getThemeModeFromString(themeString);
    notifyListeners();
  }

  Future<void> setLanguage(String language) async {
    if (_currentLanguage != language) {
      _currentLanguage = language;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, language);
      notifyListeners();
    }
  }

  Future<void> setTheme(ThemeMode theme) async {
    if (_currentTheme != theme) {
      _currentTheme = theme;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, _getStringFromThemeMode(theme));
      notifyListeners();
    }
  }

  ThemeMode _getThemeModeFromString(String themeString) {
    switch (themeString) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }

  String _getStringFromThemeMode(ThemeMode theme) {
    switch (theme) {
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.light:
        return 'light';
      case ThemeMode.system:
        return 'system';
    }
  }

  bool get isDarkMode {
    return _currentTheme == ThemeMode.dark;
  }

  bool get isLightMode {
    return _currentTheme == ThemeMode.light;
  }

  bool get isSystemMode {
    return _currentTheme == ThemeMode.system;
  }
}

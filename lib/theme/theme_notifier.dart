import 'package:couplers/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier with ChangeNotifier {
  ThemeData _currentTheme;
  bool _isDarkMode;
  bool _isManualTheme;

  static const String _themePreferenceKey = "theme_preference";

  ThemeNotifier(this._currentTheme, this._isDarkMode) : _isManualTheme = false;

  ThemeData get currentTheme => _currentTheme;
  bool get isDarkMode => _isDarkMode;
  bool get isManualTheme => _isManualTheme;

  // Method to manually change the theme
  void switchTheme() async {
    _isManualTheme = true;
    if (_isDarkMode) {
      _currentTheme = AppTheme.lightTheme();
      _isDarkMode = false;
    } else {
      _currentTheme = AppTheme.darkTheme();
      _isDarkMode = true;
    }
    notifyListeners();
    await _saveThemePreference();
  }

  // Method to apply the light theme
  void setLightTheme() async {
    _isManualTheme = true;
    _currentTheme = AppTheme.lightTheme();
    _isDarkMode = false;
    notifyListeners();
    await _saveThemePreference();
  }

  // Method to apply the dark theme
  void setDarkTheme() async {
    _isManualTheme = true;
    _currentTheme = AppTheme.darkTheme();
    _isDarkMode = true;
    notifyListeners();
    await _saveThemePreference();
  }

  // Method for saving the theme in SharedPreferences
  Future<void> _saveThemePreference() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(_themePreferenceKey, _isDarkMode);
  }

  // Method to load the theme saved by SharedPreferences
  static Future<ThemeNotifier> loadThemeFromPreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool isDarkMode = prefs.getBool(_themePreferenceKey) ?? false;
    final ThemeData initialTheme =
        isDarkMode ? AppTheme.darkTheme() : AppTheme.lightTheme();
    return ThemeNotifier(initialTheme, isDarkMode);
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { light, dark, system }

/// ThemeProvider manages the theme status (Light, Dark, System)
/// and saves the user preference locally.
class ThemeProvider extends ChangeNotifier {
  static const String _themePrefKey = 'user_theme_pref';
  
  AppThemeMode _themeMode = AppThemeMode.system;

  AppThemeMode get themeMode => _themeMode;

  ThemeMode get sdkThemeMode {
    switch (_themeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  ThemeProvider() {
    _loadThemePreference();
  }

  /// Load user preference on startup
  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_themePrefKey);
      if (savedMode != null) {
        _themeMode = AppThemeMode.values.firstWhere(
          (e) => e.name == savedMode,
          orElse: () => AppThemeMode.system,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading theme preference: $e');
    }
  }

  /// Change theme and persist setting
  Future<void> setThemeMode(AppThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themePrefKey, mode.name);
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
  }

  void toggleTheme() {
    if (isDarkMode) {
      setThemeMode(AppThemeMode.light);
    } else {
      setThemeMode(AppThemeMode.dark);
    }
  }

  bool get isDarkMode {
    if (_themeMode == AppThemeMode.system) {
      final window = WidgetsBinding.instance.platformDispatcher;
      return window.platformBrightness == Brightness.dark;
    }
    return _themeMode == AppThemeMode.dark;
  }
}

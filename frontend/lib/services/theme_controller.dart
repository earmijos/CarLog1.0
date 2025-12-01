import 'package:flutter/material.dart';
import 'api_service.dart';

/// Global theme controller that manages app-wide theme state
class ThemeController extends ChangeNotifier {
  static final ThemeController _instance = ThemeController._internal();
  factory ThemeController() => _instance;
  ThemeController._internal();

  final ApiService _apiService = ApiService();
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  /// Initialize theme from saved settings
  Future<void> initialize() async {
    try {
      final settings = await _apiService.getSettings();
      _themeMode = _parseThemeMode(settings.theme);
      notifyListeners();
    } catch (e) {
      // Default to system theme if settings fail to load
      _themeMode = ThemeMode.system;
    }
  }

  /// Set theme mode and persist to backend
  Future<void> setThemeMode(String themeString) async {
    final newMode = _parseThemeMode(themeString);
    if (_themeMode != newMode) {
      _themeMode = newMode;
      notifyListeners();
      
      // Persist to backend
      try {
        await _apiService.setSetting('theme', themeString);
      } catch (e) {
        // Silently fail - theme still changes locally
      }
    }
  }

  ThemeMode _parseThemeMode(String? theme) {
    switch (theme?.toLowerCase()) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  String get themeModeString {
    switch (_themeMode) {
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.light:
        return 'light';
      case ThemeMode.system:
        return 'system';
    }
  }
}


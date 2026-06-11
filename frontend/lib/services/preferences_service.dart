import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _themeModeKey = 'theme_mode';
  static const String _fontSizeKey = 'font_size';

  static const double defaultFontSize = 16.0;

  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  static Future<PreferencesService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return PreferencesService(prefs);
  }

  ThemeMode getThemeMode() {
    final value = _prefs.getString(_themeModeKey) ?? 'system';
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _prefs.setString(_themeModeKey, value);
  }

  double getFontSize() {
    return _prefs.getDouble(_fontSizeKey) ?? defaultFontSize;
  }

  Future<void> setFontSize(double size) async {
    await _prefs.setDouble(_fontSizeKey, size);
  }
}

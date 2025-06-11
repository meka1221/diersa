import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/theme_settings.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_settings';
  late ThemeSettings _settings;
  late SharedPreferences _prefs;

  ThemeProvider() {
    _loadSettings();
  }

  ThemeSettings get settings => _settings;

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    final String? themeJson = _prefs.getString(_themeKey);
    if (themeJson != null) {
      _settings = ThemeSettings.fromJson(json.decode(themeJson));
    } else {
      _settings = ThemeSettings.defaultSettings;
    }
    notifyListeners();
  }

  Future<void> updateSettings(ThemeSettings newSettings) async {
    _settings = newSettings;
    await _prefs.setString(_themeKey, json.encode(_settings.toJson()));
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _settings = _settings.copyWith(isDarkMode: !_settings.isDarkMode);
    await _prefs.setString(_themeKey, json.encode(_settings.toJson()));
    notifyListeners();
  }

  Future<void> updatePrimaryColor(Color color) async {
    _settings = _settings.copyWith(primaryColor: color);
    await _prefs.setString(_themeKey, json.encode(_settings.toJson()));
    notifyListeners();
  }

  Future<void> updateAccentColor(Color color) async {
    _settings = _settings.copyWith(accentColor: color);
    await _prefs.setString(_themeKey, json.encode(_settings.toJson()));
    notifyListeners();
  }
}

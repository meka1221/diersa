import 'package:flutter/material.dart';

class ThemeSettings {
  final bool isDarkMode;
  final Color primaryColor;
  final Color accentColor;

  ThemeSettings({
    required this.isDarkMode,
    required this.primaryColor,
    required this.accentColor,
  });

  ThemeSettings copyWith({
    bool? isDarkMode,
    Color? primaryColor,
    Color? accentColor,
  }) {
    return ThemeSettings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      primaryColor: primaryColor ?? this.primaryColor,
      accentColor: accentColor ?? this.accentColor,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isDarkMode': isDarkMode,
      'primaryColor': primaryColor.value,
      'accentColor': accentColor.value,
    };
  }

  factory ThemeSettings.fromJson(Map<String, dynamic> json) {
    return ThemeSettings(
      isDarkMode: json['isDarkMode'] as bool,
      primaryColor: Color(json['primaryColor'] as int),
      accentColor: Color(json['accentColor'] as int),
    );
  }

  static ThemeSettings get defaultSettings => ThemeSettings(
        isDarkMode: true,
        primaryColor: Colors.blueGrey,
        accentColor: Colors.tealAccent,
      );
}

import 'package:flutter/material.dart';

/// The design is drawn dark-only — there is no light-mode frame anywhere
/// in the 14 screens, so this app ships a single dark theme rather than
/// inventing a light one nobody asked for.
class AppTheme {
  AppTheme._();

  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color surfaceHigh = Color(0xFF2A2A2A);
  static const Color destructive = Color(0xFFE0473E);
  static const Color affirmative = Color(0xFF3FBF62);
  static const Color favoriteGold = Color(0xFFF2C94C);

  static ThemeData get theme {
    final base = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        surface: background,
        primary: Colors.white,
        secondary: favoriteGold,
        error: destructive,
      ),
      useMaterial3: true,
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

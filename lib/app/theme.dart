import 'package:flutter/material.dart';

class SweepTheme {
  static const Color ink = Color(0xFF0F1724);
  static const Color sea = Color(0xFF1F8A8A);
  static const Color lime = Color(0xFFA5C957);
  static const Color coral = Color(0xFFF25F5C);
  static const Color mist = Color(0xFFF3F6FA);
  static const Color slate = Color(0xFF384555);

  static ThemeData get light {
    const ColorScheme colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: sea,
      onPrimary: Colors.white,
      secondary: lime,
      onSecondary: ink,
      error: coral,
      onError: Colors.white,
      surface: Colors.white,
      onSurface: ink,
    );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: mist,
      fontFamily: 'Avenir',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: sea,
        unselectedItemColor: slate,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      useMaterial3: true,
    );
  }
}

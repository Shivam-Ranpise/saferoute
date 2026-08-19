import 'package:flutter/material.dart';

class AdminColors {
  AdminColors._();

  static const Color sidebarBg = Color(0xFF0A1329);
  static const Color sidebarActive = Color(0xFF1E2D4F);
  static const Color sidebarText = Color(0xFF94A3B8);
  static const Color sidebarTextActive = Color(0xFFFFFFFF);

  static const Color deepNavy = Color(0xFF0D1B3E);
  static const Color blue = Color(0xFF1565C0);
  static const Color blueLight = Color(0xFFE3F2FD);
  static const Color yellow = Color(0xFFFFC107);
  static const Color safetyGreen = Color(0xFF2E7D32);
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFF57C00);

  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
}

class AdminTheme {
  AdminTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AdminColors.background,
      fontFamily: 'Roboto',
      colorScheme: const ColorScheme.light(
        primary: AdminColors.deepNavy,
        secondary: AdminColors.blue,
        surface: AdminColors.surface,
        error: AdminColors.error,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AdminColors.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AdminColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AdminColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AdminColors.blue, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// SafeRoute brand color palette.
/// Deep navy, blue, yellow, white — professional, modern, trustworthy.
class SafeRouteColors {
  SafeRouteColors._();

  // Primary brand colors
  static const Color deepNavy = Color(0xFF0D1B3E);
  static const Color navyMid = Color(0xFF1A2F5A);
  static const Color navyLight = Color(0xFF243B73);

  static const Color blue = Color(0xFF1565C0);
  static const Color blueLight = Color(0xFF1976D2);
  static const Color blueLighter = Color(0xFF42A5F5);
  static const Color blueBackground = Color(0xFFE3F2FD);

  static const Color yellow = Color(0xFFFFC107);
  static const Color yellowLight = Color(0xFFFFD54F);
  static const Color yellowDark = Color(0xFFFFA000);

  static const Color safetyGreen = Color(0xFF2E7D32);
  static const Color safetyGreenLight = Color(0xFF4CAF50);

  static const Color orange = Color(0xFFFF6D00);
  static const Color orangeLight = Color(0xFFFF9100);

  // Semantic colors
  static const Color error = Color(0xFFD32F2F);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color warning = Color(0xFFF57C00);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color success = Color(0xFF2E7D32);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color info = Color(0xFF1565C0);
  static const Color infoLight = Color(0xFFE3F2FD);

  // Status colors
  static const Color statusActive = safetyGreen;
  static const Color statusStale = warning;
  static const Color statusIdle = Color(0xFF757575);
  static const Color statusEmergency = error;

  // Neutral
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F2F5);
  static const Color outline = Color(0xFFDDE1E7);
  static const Color onSurface = Color(0xFF1A1F36);
  static const Color onSurfaceVariant = Color(0xFF5A6478);
  static const Color disabled = Color(0xFFBDBDBD);
}

/// SafeRoute Material 3 theme definition.
class SafeRouteTheme {
  SafeRouteTheme._();

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: SafeRouteColors.blue,
      primary: SafeRouteColors.blue,
      onPrimary: SafeRouteColors.white,
      secondary: SafeRouteColors.yellow,
      onSecondary: SafeRouteColors.deepNavy,
      surface: SafeRouteColors.surface,
      onSurface: SafeRouteColors.onSurface,
      error: SafeRouteColors.error,
      onError: SafeRouteColors.white,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      
      // Typography — Inter font family for professional look
      fontFamily: 'Inter',
      textTheme: _buildTextTheme(),

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: SafeRouteColors.deepNavy,
        foregroundColor: SafeRouteColors.white,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: SafeRouteColors.white,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(color: SafeRouteColors.white),
      ),

      // Bottom Navigation Bar
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: SafeRouteColors.white,
        indicatorColor: SafeRouteColors.blueBackground,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: SafeRouteColors.blue, size: 24);
          }
          return const IconThemeData(color: SafeRouteColors.onSurfaceVariant, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: SafeRouteColors.blue,
            );
          }
          return const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: SafeRouteColors.onSurfaceVariant,
          );
        }),
        elevation: 4,
        shadowColor: Colors.black12,
      ),

      // Cards
      cardTheme: CardThemeData(
        color: SafeRouteColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: SafeRouteColors.outline, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Elevated Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SafeRouteColors.blue,
          foregroundColor: SafeRouteColors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),

      // Outlined Buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: SafeRouteColors.blue,
          side: const BorderSide(color: SafeRouteColors.blue),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: SafeRouteColors.blue,
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Input Fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SafeRouteColors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SafeRouteColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SafeRouteColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SafeRouteColors.blue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SafeRouteColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SafeRouteColors.error, width: 2),
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          color: SafeRouteColors.onSurfaceVariant,
        ),
        hintStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          color: SafeRouteColors.disabled,
        ),
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: SafeRouteColors.surfaceVariant,
        selectedColor: SafeRouteColors.blueBackground,
        labelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // Dividers
      dividerTheme: const DividerThemeData(
        color: SafeRouteColors.outline,
        thickness: 1,
        space: 0,
      ),

      // List tiles
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        dense: false,
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: SafeRouteColors.deepNavy,
        contentTextStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          color: SafeRouteColors.white,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),

      // FAB
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: SafeRouteColors.blue,
        foregroundColor: SafeRouteColors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return SafeRouteColors.blue;
          return SafeRouteColors.disabled;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return SafeRouteColors.blueBackground;
          }
          return SafeRouteColors.outline;
        }),
      ),

      // Background
      scaffoldBackgroundColor: SafeRouteColors.background,
    );
  }

  static TextTheme _buildTextTheme() {
    return const TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 57,
        fontWeight: FontWeight.w700,
        color: SafeRouteColors.onSurface,
        letterSpacing: -1,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 45,
        fontWeight: FontWeight.w700,
        color: SafeRouteColors.onSurface,
        letterSpacing: -0.5,
      ),
      headlineLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: SafeRouteColors.deepNavy,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: SafeRouteColors.deepNavy,
        letterSpacing: -0.3,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: SafeRouteColors.deepNavy,
        letterSpacing: -0.2,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: SafeRouteColors.onSurface,
        letterSpacing: -0.2,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: SafeRouteColors.onSurface,
        letterSpacing: 0,
      ),
      titleSmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: SafeRouteColors.onSurface,
        letterSpacing: 0,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: SafeRouteColors.onSurface,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: SafeRouteColors.onSurface,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: SafeRouteColors.onSurfaceVariant,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
      ),
      labelSmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
      ),
    );
  }
}

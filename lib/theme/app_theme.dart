// lib/theme/app_theme.dart
// Defines the complete dark theme for AstraFlix
// Fixed for Flutter 3.18+ compatibility

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  // Primary Brand Colors
  static const Color background = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF141414);
  static const Color surfaceVariant = Color(0xFF1F1F1F);
  static const Color card = Color(0xFF1A1A1A);

  // Accent Colors
  static const Color primary = Color(0xFFE50914);
  static const Color primaryDark = Color(0xFFC40812);
  static const Color primaryLight = Color(0xFFFF1A1A);
  static const Color secondary = Color(0xFFFFB800);
  static const Color tertiary = Color(0xFF00D4FF);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textMuted = Color(0xFF737373);
  static const Color textHint = Color(0xFF4D4D4D);

  // Status Colors
  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFE74C3C);
  static const Color info = Color(0xFF3498DB);

  // Glass Colors
  static const Color glassWhite = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color glassBlack = Color(0x80000000);

  // Gradient Colors
  static const List<Color> primaryGradient = [
    Color(0xFFE50914),
    Color(0xFF8B0000),
  ];
  static const List<Color> darkGradient = [
    Color(0xFF0A0A0A),
    Color(0xFF1A1A1A),
  ];
  static const List<Color> cardGradient = [
    Colors.transparent,
    Color(0xCC000000),
  ];
  static const List<Color> shimmerGradient = [
    Color(0xFF1A1A1A),
    Color(0xFF2A2A2A),
    Color(0xFF1A1A1A),
  ];
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Poppins',

      colorScheme: const ColorScheme.dark(
        surface: AppColors.background,
        surfaceContainerHighest: AppColors.surfaceVariant,
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryDark,
        secondary: AppColors.secondary,
        tertiary: AppColors.tertiary,
        onSurface: AppColors.textPrimary,
        onPrimary: Colors.white,
        error: AppColors.error,
      ),

      scaffoldBackgroundColor: AppColors.background,

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.background,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: 0.5,
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF111111),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 8,
        shadowColor: Colors.black54,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2A2A2A), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        hintStyle: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 14,
          fontFamily: 'Poppins',
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontFamily: 'Poppins',
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.glassBorder, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32, fontWeight: FontWeight.w800,
          color: AppColors.textPrimary, letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: 28, fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        displaySmall: TextStyle(
          fontSize: 24, fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        headlineLarge: TextStyle(
          fontSize: 22, fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        bodySmall: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w400,
          color: AppColors.textMuted,
        ),
        labelLarge: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        labelMedium: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
        labelSmall: TextStyle(
          fontSize: 10, fontWeight: FontWeight.w500,
          color: AppColors.textMuted,
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2A2A2A),
        thickness: 1,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: AppColors.textPrimary,
        size: 24,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: AppColors.primary.withValues(alpha: 0.2),
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
        side: const BorderSide(color: Color(0xFF2A2A2A)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }


  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Poppins',
      colorScheme: const ColorScheme.light(
        surface: Color(0xFFF5F5F5),
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryDark,
        secondary: AppColors.secondary,
        tertiary: AppColors.tertiary,
        onSurface: Color(0xFF1A1A1A),
        onPrimary: Colors.white,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF1A1A1A),
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
      ),
    );
  }
}

// Text Style Extensions
extension TextStyleExtension on TextStyle {
  TextStyle get primary => copyWith(color: AppColors.primary);
  TextStyle get secondary => copyWith(color: AppColors.textSecondary);
  TextStyle get muted => copyWith(color: AppColors.textMuted);
}
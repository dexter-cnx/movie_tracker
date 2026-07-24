import 'package:flutter/material.dart';

abstract final class AppColors {
  // Tinker-inspired cinematic dark UI.
  static const background = Color(0xFF0B0B0B);
  static const surface = Color(0xFF121212);
  static const card = Color(0xFF171717);
  static const cardAlt = Color(0xFF202020);
  static const elevated = Color(0xFF292929);
  static const text = Color(0xFFF7F7F5);
  static const secondary = Color(0xFF8E8E8E);
  static const muted = Color(0xFF5D5D5D);
  static const orange = Color(0xFFFF7A00);
  static const red = Color(0xFFFF2D20);
  static const yellow = Color(0xFFFFB21C);
  static const green = Color(0xFF32C978);
  static const button = Color(0xFFF4F4F1);
  static const onButton = Color(0xFF111111);
  static const divider = Color(0xFF2A2A2A);
  static const white = Colors.white;
}

abstract final class AppTheme {
  static ThemeData get light {
    const scheme = ColorScheme.dark(
      primary: AppColors.text,
      onPrimary: AppColors.onButton,
      secondary: AppColors.orange,
      onSecondary: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      error: AppColors.red,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Inter',
      splashColor: Colors.white.withValues(alpha: .04),
      highlightColor: Colors.transparent,
      dividerColor: AppColors.divider,
      cardColor: AppColors.card,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: AppColors.text,
            height: 1.05,
            letterSpacing: -0.8),
        headlineMedium: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w900,
            color: AppColors.text,
            letterSpacing: -0.5),
        titleLarge: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w900,
            color: AppColors.text,
            letterSpacing: -0.25),
        titleMedium: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.text),
        bodyLarge: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.text),
        bodyMedium: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.secondary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        hintStyle: const TextStyle(color: AppColors.secondary),
        prefixIconColor: AppColors.secondary,
        suffixIconColor: AppColors.secondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.button,
          foregroundColor: AppColors.onButton,
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
          shape: const StadiumBorder(),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.cardAlt,
        selectedColor: AppColors.button,
        labelStyle:
            const TextStyle(color: AppColors.text, fontWeight: FontWeight.w700),
        secondaryLabelStyle: const TextStyle(
            color: AppColors.onButton, fontWeight: FontWeight.w800),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}

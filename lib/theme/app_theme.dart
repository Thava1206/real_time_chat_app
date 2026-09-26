import 'package:flutter/material.dart';

/// Brand color palette used across the app's [ThemeData].
class AppColors {
  AppColors._();

  static const plum = Color(0xFF6B2D5C);
  static const gold = Color(0xFFE3B505);
  static const forest = Color(0xFF4E6E5D);
  static const ink = Color(0xFF1A1B25);
  static const terracotta = Color(0xFFD17A5A);
}

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.ink,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.gold,
    onPrimary: AppColors.ink,
    secondary: AppColors.terracotta,
    onSecondary: AppColors.ink,
    tertiary: AppColors.forest,
    onTertiary: Colors.white,
    error: AppColors.terracotta,
    onError: AppColors.ink,
    surface: AppColors.plum,
    onSurface: Colors.white,
    errorContainer: AppColors.terracotta,
    onErrorContainer: AppColors.ink,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.plum,
    foregroundColor: Colors.white,
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.gold,
      foregroundColor: AppColors.ink,
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: AppColors.gold),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: const OutlineInputBorder(),
    focusedBorder: const OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.gold, width: 2),
    ),
    labelStyle: const TextStyle(color: Colors.white70),
  ),
  textTheme: const TextTheme(
    headlineSmall: TextStyle(color: Colors.white),
    headlineMedium: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.white),
  ),
);

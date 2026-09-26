import 'package:flutter/material.dart';

/// Brand color palette used across the app's [ThemeData].
class AppColors {
  AppColors._();

  static const plum = Color(0xFF6B2D5C);
  static const gold = Color(0xFFE3B505);
  static const forest = Color(0xFF4E6E5D);
  static const ink = Color(0xFF1A1B25);
  static const terracotta = Color(0xFFD17A5A);

  // Neutral surfaces layered on top of [ink] for the chat UI.
  static const inkRaised = Color(0xFF22232F);
  static const inkHigh = Color(0xFF2C2D3B);
  static const divider = Color(0xFF34354A);
  static const textMuted = Color(0xFF9A9BB0);
  static const online = Color(0xFF3DD68C);
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
  dividerTheme: const DividerThemeData(color: AppColors.divider, space: 1),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: AppColors.inkRaised,
    showDragHandle: true,
  ),
  popupMenuTheme: const PopupMenuThemeData(color: AppColors.inkHigh),
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

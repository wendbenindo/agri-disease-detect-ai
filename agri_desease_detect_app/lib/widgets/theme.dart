import 'package:flutter/material.dart';

// Palette de couleurs centralisée (alignée sur HomePage)
class AppColors {
  static const Color primaryDarkGreen = Color(0xFF1B5E20);
  static const Color accentGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFFF0FDF4);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color backgroundColor = Colors.white;
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color errorRed = Color(0xFFF44336);
}

final ThemeData tipTigaTheme = ThemeData(
  useMaterial3: true,
  primaryColor: AppColors.primaryDarkGreen,
  scaffoldBackgroundColor: AppColors.backgroundColor,
  fontFamily: 'SF Pro Display',
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.primaryDarkGreen,
    foregroundColor: Colors.white,
    elevation: 1,
    centerTitle: true,
    iconTheme: const IconThemeData(color: Colors.white),
    titleTextStyle: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: Colors.white,
      fontFamily: 'SF Pro Display',
    ),
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w800,
      color: AppColors.primaryDarkGreen,
      fontFamily: 'SF Pro Display',
    ),
    headlineMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      fontFamily: 'SF Pro Display',
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      color: AppColors.textPrimary,
      fontFamily: 'SF Pro Text',
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      color: AppColors.textSecondary,
      fontFamily: 'SF Pro Text',
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.accentGreen,
      fontFamily: 'SF Pro Text',
    ),
  ),
  colorScheme: const ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primaryDarkGreen,
    onPrimary: Colors.white,
    secondary: AppColors.accentGreen,
    onSecondary: Colors.white,
    error: AppColors.errorRed,
    onError: Colors.white,
    surface: AppColors.backgroundColor,
    onSurface: AppColors.textPrimary,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryDarkGreen,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        fontFamily: 'SF Pro Text',
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
    ),
  ),
  cardTheme: CardThemeData(
    color: AppColors.cardColor,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    shadowColor: Colors.black.withOpacity(0.08),
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  ),
);

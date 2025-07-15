import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(
  useMaterial3: true, // Enables Material You (Material 3)
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.green, // Base environmental theme color
    brightness: Brightness.light,
  ),
  scaffoldBackgroundColor: Colors.grey[50],
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.green,
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
  ),
  textTheme: const TextTheme(
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    ),
    bodyMedium: TextStyle(
      fontSize: 16,
      color: Colors.black87,
    ),
    labelLarge: TextStyle(
      fontWeight: FontWeight.w600,
      color: Colors.green,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.green),
      borderRadius: BorderRadius.circular(12),
    ),
    labelStyle: const TextStyle(color: Colors.green),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  ),
);

import 'package:flutter/material.dart';

/// Occupational Health and Safety palette: a deep regulatory teal with clear status colours.
class OhsColors {
  static const brand = Color(0xFF0F5C63);
  static const critical = Color(0xFFC62828);
  static const high = Color(0xFFEF6C00);
  static const medium = Color(0xFFF9A825);
  static const low = Color(0xFF2E7D32);
  static const info = Color(0xFF1565C0);
  static const neutral = Color(0xFF607D8B);
}

ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(seedColor: OhsColors.brand, brightness: brightness);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: brightness == Brightness.light ? const Color(0xFFF4F7F8) : scheme.surface,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: brightness == Brightness.light ? OhsColors.brand : scheme.surface,
      foregroundColor: brightness == Brightness.light ? Colors.white : scheme.onSurface,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: scheme.outlineVariant)),
    ),
    inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder(), isDense: true),
    listTileTheme: const ListTileThemeData(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2)),
  );
}

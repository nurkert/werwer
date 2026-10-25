import 'package:flutter/material.dart';

/// Colours of the "Mondbühne" art direction (docs/DESIGN.md).
abstract final class Palette {
  static const night900 = Color(0xFF141A33);
  static const night800 = Color(0xFF1B2242);
  static const night700 = Color(0xFF232C52);
  static const moon100 = Color(0xFFF6E7C1);
  static const moon200 = Color(0xFFE9D8AD);
  static const lantern400 = Color(0xFFF2A93B);
  static const curtain400 = Color(0xFFE0605A);
  static const curtain600 = Color(0xFF9E1F24);
  static const ink = Color(0xFF2A1B12);
}

const displayFont = 'LilitaOne';

ThemeData buildTheme() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Palette.lantern400,
      brightness: Brightness.dark,
      surface: Palette.night900,
    ),
    scaffoldBackgroundColor: Palette.night900,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Palette.night800,
      labelStyle: const TextStyle(color: Palette.moon200),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Palette.lantern400, width: 2),
      ),
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontFamily: displayFont,
        color: Palette.moon100,
      ),
      bodyLarge: TextStyle(color: Palette.moon200, height: 1.5),
    ),
  );
}

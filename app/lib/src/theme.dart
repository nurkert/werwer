import 'package:flutter/material.dart';

/// Colours of the "Mondbühne" art direction (docs/DESIGN.md).
abstract final class Palette {
  static const night900 = Color(0xFF141A33);
  static const night700 = Color(0xFF232C52);
  static const moon100 = Color(0xFFF6E7C1);
  static const moon200 = Color(0xFFE9D8AD);
  static const lantern400 = Color(0xFFF2A93B);
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
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontFamily: displayFont,
        color: Palette.moon100,
      ),
      bodyLarge: TextStyle(color: Palette.moon200, height: 1.5),
    ),
  );
}

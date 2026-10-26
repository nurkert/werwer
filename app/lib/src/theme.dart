import 'package:flutter/material.dart';
import 'package:whowolf/src/palette.g.dart';

export 'package:whowolf/src/palette.g.dart';

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

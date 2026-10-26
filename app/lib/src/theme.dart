import 'package:flutter/material.dart';
import 'package:whowolf/src/palette.g.dart';

export 'package:whowolf/src/palette.g.dart';

const displayFont = 'LilitaOne';
const textFont = 'Manrope';

/// The app's theme: night stage, Manrope text, Lilita One titles. Screens
/// sit on a transparent scaffold over the shared stage background.
ThemeData buildTheme() {
  return ThemeData(
    fontFamily: textFont,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Palette.lantern400,
      brightness: Brightness.dark,
      primary: Palette.lantern400,
      onPrimary: Palette.ink,
      surface: Palette.night800,
      onSurface: Palette.moon100,
      error: Palette.curtain400,
    ),
    scaffoldBackgroundColor: Colors.transparent,
    canvasColor: Palette.night800,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: Palette.moon100,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: displayFont,
        fontSize: 24,
        color: Palette.moon100,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Palette.lantern300,
        textStyle: const TextStyle(
          fontFamily: textFont,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Palette.night800,
      dragHandleColor: Palette.card200,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.l)),
        side: BorderSide(color: Palette.night500, width: 1.5),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Palette.night800,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.l),
        side: const BorderSide(color: Palette.night500, width: 1.5),
      ),
      titleTextStyle: const TextStyle(
        fontFamily: displayFont,
        fontSize: 24,
        color: Palette.moon100,
      ),
      contentTextStyle: const TextStyle(
        fontFamily: textFont,
        fontSize: 16,
        height: 1.45,
        color: Palette.moon200,
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Palette.paper,
      contentTextStyle: TextStyle(fontFamily: textFont, color: Palette.ink),
      behavior: SnackBarBehavior.floating,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Palette.night800,
      labelStyle: const TextStyle(color: Palette.moon200),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.s + 4),
        borderSide: BorderSide(color: Palette.card200.withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.s + 4),
        borderSide: BorderSide(
          color: Palette.card200.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.s + 4),
        borderSide: const BorderSide(color: Palette.lantern400, width: 2),
      ),
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontFamily: displayFont,
        color: Palette.moon100,
      ),
      bodyLarge: TextStyle(color: Palette.moon200, height: 1.5),
      bodyMedium: TextStyle(color: Palette.moon200),
    ),
  );
}

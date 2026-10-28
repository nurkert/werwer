import 'package:flutter/material.dart';
import 'package:whowolf/src/palette.g.dart';

export 'package:whowolf/src/palette.g.dart';

const displayFont = 'AncizarSerif';
const textFont = 'Manrope';

final MenuStyle _menuStyle = MenuStyle(
  backgroundColor: const WidgetStatePropertyAll(Palette.stagePlaque),
  surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
  elevation: const WidgetStatePropertyAll(14),
  shadowColor: const WidgetStatePropertyAll(Colors.black),
  shape: WidgetStatePropertyAll(
    RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Radii.m),
      side: const BorderSide(color: Palette.stageBrass, width: 1.5),
    ),
  ),
);

/// The app's theme: night stage, Manrope text, Ancizar Serif titles. Screens
/// sit on a transparent scaffold over the shared stage background.
ThemeData buildTheme() {
  return ThemeData(
    fontFamily: textFont,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Palette.lantern400,
      brightness: Brightness.dark,
      primary: Palette.lantern400,
      onPrimary: Palette.ink,
      surface: Palette.stagePlaque,
      onSurface: Palette.moon100,
      error: Palette.curtain400,
    ),
    scaffoldBackgroundColor: Colors.transparent,
    canvasColor: Palette.stagePlaque,
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
    // Sheets and dialogs are plaques too (task 012): warm dark, brass edge.
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Palette.stagePlaque,
      dragHandleColor: Palette.stageBrassLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.l)),
        side: BorderSide(color: Palette.stageBrass, width: 1.5),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Palette.stagePlaque,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.l),
        side: const BorderSide(color: Palette.stageBrass, width: 1.5),
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
    // Menus (the language flag, any pick-one list) are small plaques:
    // warm dark, brass edge, the book serif, a lantern glow on the chosen.
    popupMenuTheme: PopupMenuThemeData(
      color: Palette.stagePlaque,
      surfaceTintColor: Colors.transparent,
      elevation: 14,
      shadowColor: Colors.black,
      menuPadding: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.m),
        side: const BorderSide(color: Palette.stageBrass, width: 1.5),
      ),
      labelTextStyle: const WidgetStatePropertyAll(
        TextStyle(
          fontFamily: displayFont,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Palette.stageIvory,
        ),
      ),
    ),
    menuTheme: MenuThemeData(style: _menuStyle),
    dropdownMenuTheme: DropdownMenuThemeData(menuStyle: _menuStyle),
    // Choices side by side (night, ghosts): brass outline, the chosen one
    // lit like a lantern.
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        side: const WidgetStatePropertyAll(
          BorderSide(color: Palette.stageBrass, width: 1.5),
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Palette.stageLantern
              : Palette.stagePlaque.withValues(alpha: 0.6),
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Palette.stageLanternInk
              : Palette.stageIvory,
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontFamily: displayFont, fontWeight: FontWeight.w700),
        ),
      ),
    ),
    // Times: a brass groove, lit as far as the lantern knob has gone.
    sliderTheme: SliderThemeData(
      trackHeight: 6,
      activeTrackColor: Palette.stageLantern,
      inactiveTrackColor: Palette.stageBrass.withValues(alpha: 0.35),
      thumbColor: Palette.stageLanternTop,
      overlayColor: Palette.stageLantern.withValues(alpha: 0.18),
      activeTickMarkColor: Colors.transparent,
      inactiveTickMarkColor: Colors.transparent,
      valueIndicatorColor: Palette.stagePlaque,
      valueIndicatorShape: const RoundedRectSliderValueIndicatorShape(),
      valueIndicatorTextStyle: const TextStyle(
        fontFamily: displayFont,
        fontWeight: FontWeight.w700,
        color: Palette.stageIvory,
      ),
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Palette.paper,
      contentTextStyle: TextStyle(fontFamily: textFont, color: Palette.ink),
      behavior: SnackBarBehavior.floating,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      // A field cut into a plaque (task 012): warm dark, brass edge.
      fillColor: Palette.stagePlaque.withValues(alpha: 0.86),
      labelStyle: const TextStyle(color: Palette.stageIvorySoft),
      hintStyle: TextStyle(
        color: Palette.stageIvorySoft.withValues(alpha: 0.6),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.m),
        borderSide: const BorderSide(color: Palette.stageBrass),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.m),
        borderSide: const BorderSide(color: Palette.stageBrass, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.m),
        borderSide: const BorderSide(
          color: Palette.stageLanternTop,
          width: 2,
        ),
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

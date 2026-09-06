import 'package:flutter/material.dart';
import '../vfx/neon_palette.dart';

ThemeData buildAetherTheme() {
  final base = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    fontFamily: 'Roboto',
    scaffoldBackgroundColor: NeonPalette.bg,
    colorScheme: const ColorScheme.dark(
      primary: NeonPalette.cyan,
      secondary: NeonPalette.magenta,
      surface: NeonPalette.bgElevated,
      error: NeonPalette.danger,
    ),
  );
  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: NeonPalette.cyan,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: 3,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: NeonPalette.cyan.withOpacity(0.15),
        foregroundColor: NeonPalette.cyan,
        side: const BorderSide(color: NeonPalette.cyan, width: 1.4),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
        ),
      ),
    ),
  );
}

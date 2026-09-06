import 'package:flutter/material.dart';
import '../vfx/neon_palette.dart';

ThemeData buildAetherTheme() {
  final base = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    fontFamily: 'Roboto',
    scaffoldBackgroundColor: NeonPalette.bg,
    colorScheme: const ColorScheme.dark(
      primary: NeonPalette.accent,
      secondary: NeonPalette.text,
      surface: NeonPalette.bgElevated,
      error: NeonPalette.danger,
      onPrimary: NeonPalette.bg,
      onSurface: NeonPalette.text,
    ),
  );
  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: NeonPalette.text,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: NeonPalette.surface,
        foregroundColor: NeonPalette.text,
        side: const BorderSide(color: NeonPalette.tileEdge, width: 1),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: NeonPalette.surface,
      contentTextStyle: TextStyle(color: NeonPalette.text),
    ),
  );
}

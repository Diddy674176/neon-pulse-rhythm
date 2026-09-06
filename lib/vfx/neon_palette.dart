import 'dart:ui';

/// Restrained AETHER BEAT palette — deep black, clean whites, one accent.
/// Intentionally not neon cyberpunk.
class NeonPalette {
  static const bg = Color(0xFF0A0A0A);
  static const bgElevated = Color(0xFF141414);
  static const surface = Color(0xFF1C1C1C);
  static const tile = Color(0xFF121212);
  static const tileEdge = Color(0xFF2E2E2E);
  static const laneFill = Color(0xFF101010);
  static const laneDivider = Color(0xFF222222);
  static const hitZone = Color(0xFFFFFFFF);
  static const hitZoneSoft = Color(0x33FFFFFF);

  /// Single brand accent (cool white-blue).
  static const accent = Color(0xFF7EB6FF);
  static const cyan = accent; // alias for legacy call sites
  static const magenta = Color(0xFFB8C0CC); // desaturated, not neon pink
  static const violet = Color(0xFF9AA3B2);
  static const lime = Color(0xFFE8E8E8);
  static const amber = Color(0xFFC8C8C8);
  static const danger = Color(0xFFE85D5D);
  static const text = Color(0xFFF5F5F5);
  static const muted = Color(0xFF8A8A8A);

  /// Subtle per-lane tint (very restrained).
  static const laneColors = [
    Color(0xFF1A1A1A),
    Color(0xFF161616),
    Color(0xFF1A1A1A),
    Color(0xFF161616),
    Color(0xFF1A1A1A),
    Color(0xFF161616),
  ];
}

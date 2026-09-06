import 'dart:ui';

/// Restrained AETHER BEAT palette — deep black chrome, light lanes, dark tiles.
/// Intentionally not neon cyberpunk rainbow.
class NeonPalette {
  static const bg = Color(0xFF0B0B0B);
  static const bgElevated = Color(0xFF141414);
  static const surface = Color(0xFF1A1A1A);
  /// Near-black tiles for piano-tiles readability on light lanes.
  static const tile = Color(0xFF111111);
  static const tileEdge = Color(0xFF2A2A2A);
  /// Light lane fills (strong contrast vs dark tiles).
  static const laneFill = Color(0xFFE4E4E4);
  static const laneFillAlt = Color(0xFFD6D6D6);
  static const laneDivider = Color(0xFF9A9A9A);
  static const gutter = Color(0xFF0B0B0B);
  static const hitZone = Color(0xFF1A1A1A);
  static const hitZoneSoft = Color(0x331A1A1A);
  static const hitLine = Color(0xFF111111);

  /// Single brand accent (cool white-blue).
  static const accent = Color(0xFF7EB6FF);
  static const cyan = accent;
  static const magenta = Color(0xFFB8C0CC);
  static const violet = Color(0xFF9AA3B2);
  static const lime = Color(0xFFE8E8E8);
  static const amber = Color(0xFFC8C8C8);
  static const danger = Color(0xFFE85D5D);
  static const text = Color(0xFFF5F5F5);
  static const muted = Color(0xFF8A8A8A);
  static const perfect = Color(0xFFF5F5F5);
  static const great = Color(0xFF7EB6FF);
  static const good = Color(0xFFB0B0B0);

  static const laneColors = [
    laneFill,
    laneFillAlt,
    laneFill,
    laneFillAlt,
    laneFill,
    laneFillAlt,
  ];
}

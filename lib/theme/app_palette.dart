// theme/app_palette.dart
//
// Centralized color tokens for Harmony Pairs.
//
// The palette is inspired by classical-music aesthetics: deep navy as the
// primary, brass-gold as the accent, with a paper-cream backdrop in light
// mode and a charcoal backdrop in dark mode.

import 'package:flutter/material.dart';

class AppPalette {
  AppPalette._(); // utility class — no instances

  // ---- Brand colors ------------------------------------------------------

  /// Primary brand color: deep navy ("midnight orchestra").
  static const Color navy = Color(0xFF1E3A5F);

  /// Slightly lighter navy used for hovers / gradients.
  static const Color navyLight = Color(0xFF2C5282);

  /// Brass-gold accent — borrows from trumpets / saxophones in the icon set.
  static const Color brass = Color(0xFFC9A227);

  /// Success / matched-pair color.
  static const Color sage = Color(0xFF5A8A6B);

  /// Wrong-pair flash color.
  static const Color crimson = Color(0xFFB3433A);

  // ---- Backdrops ---------------------------------------------------------

  static const Color lightBackdrop = Color(0xFFF4EFE5); // warm paper cream
  static const Color darkBackdrop  = Color(0xFF12182A); // deep midnight

  // ---- Text / surfaces ---------------------------------------------------

  static const Color textLight = Color(0xFF1A1F36);
  static const Color textDark  = Color(0xFFE8EBF5);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark  = Color(0xFF1F2940);

  // ---- Tile back-face palette --------------------------------------------
  //
  // 12 muted, music-themed tints — kept low-saturation so the brass-gold
  // accent stands out. The board cycles through these for face-down tiles.
  static const List<Color> tileTints = [
    Color(0xFFD9A66A), // warm sand
    Color(0xFF7A9BB3), // dusty steel-blue
    Color(0xFF8E7CC3), // muted violet
    Color(0xFF6B9A8B), // pine
    Color(0xFFC97B63), // terracotta
    Color(0xFFB39CD0), // lavender
    Color(0xFF5D8AA8), // air-force blue
    Color(0xFFC2A878), // antique brass
    Color(0xFF7B8FA1), // slate
    Color(0xFFA89060), // olive gold
    Color(0xFF8B6F47), // bourbon
    Color(0xFF6D90A8), // cornflower
  ];
}

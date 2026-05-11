import 'package:flutter/material.dart';

/// Palette sampled from the design mock. See docs/DESIGN_SPEC.md §1.
///
/// Nothing outside this file should contain a raw hex value.
abstract final class AppColors {
  // ---- Surfaces -------------------------------------------------------
  static const bg = Color(0xFF050505);
  static const surface = Color(0xFF121212);
  static const surfaceHigh = Color(0xFF1C1C1E);

  // ---- Lung test card (magenta -> violet, diagonal) -------------------
  static const magenta = Color(0xFFFF3DB4);
  static const orchid = Color(0xFFC845F0);
  static const violet = Color(0xFF7B2FF7);

  // ---- Carousel neighbours --------------------------------------------
  static const indigoPeek = Color(0xFF6B4EFF);
  static const peachPeek = Color(0xFFFFB27A);

  // ---- Tiles -----------------------------------------------------------
  static const trainingBlue = Color(0xFF1E2A78);
  static const trainingGlow = Color(0xFF3D5AFE);
  static const volumeRed = Color(0xFFE5342A);
  static const volumeAmber = Color(0xFFFF7A45);

  // ---- Accents ---------------------------------------------------------
  static const acidYellow = Color(0xFFD4FF3D);
  static const sheetNavy = Color(0xFF232B6B);

  // ---- Text ------------------------------------------------------------
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xB3FFFFFF);
  static const textTertiary = Color(0x66FFFFFF);

  /// Unlit dot-matrix cell. Deliberately visible: the faint grid behind the
  /// lit dots is what gives the design its texture.
  static const dotOff = Color(0x1AFFFFFF);

  /// Diagonal gradient for the hero "Lung test" card.
  static const lungCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [magenta, orchid, violet],
    stops: [0.0, 0.45, 1.0],
  );
}

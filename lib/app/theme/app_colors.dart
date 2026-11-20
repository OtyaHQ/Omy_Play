import 'package:flutter/material.dart';

/// Canonical Otya visual system.
///
/// The product canvas is deliberately quiet: content and media artwork carry
/// the personality, while surfaces establish calm hierarchy and readability.
abstract class AppColors {
  static const Color background = Color(0xFF050812);
  static const Color surface = Color(0xFF0A1020);
  static const Color surfaceElevated = Color(0xFF202027);
  static const Color surfaceHighlight = Color(0xFF2A2934);
  static const Color border = Color(0xFF353442);
  static const Color borderSubtle = Color(0xFF282732);

  // Owner-approved Otya identity: cyan, bright blue and deep blue.
  // Violet names remain source-compatible aliases; they no longer define
  // a separate purple product palette.
  static const Color brandCyan = Color(0xFF27E8FF);
  static const Color brandBlue = Color(0xFF126BFF);
  static const Color brandDeepBlue = Color(0xFF173BFF);
  static const Color brandViolet = brandBlue;
  static const Color brandVioletDeep = brandDeepBlue;

  static const Color brandRed = Color(0xFFFF5A63);
  static const Color brandYellow = Color(0xFFF2C94C);

  static const Color accent = brandBlue;
  static const Color accentBlue = brandBlue;
  static const Color accentCyan = brandCyan;
  static const Color accentViolet = brandDeepBlue;
  static const Color accentPink = brandRed;
  static const Color accentOrange = Color(0xFFFF9A62);
  static const Color accentGreen = Color(0xFF48C78E);
  static const Color accentAmber = brandYellow;

  static const Color glowBlue = Color(0x1F126BFF);
  static const Color glowViolet = Color(0x16126BFF);

  static const LinearGradient accentGradient = LinearGradient(
    colors: [brandBlue, brandDeepBlue],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient accentGradientDiag = LinearGradient(
    colors: [brandBlue, brandDeepBlue],
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [surfaceElevated, surface],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkOverlay = LinearGradient(
    colors: [Colors.transparent, Color(0xE0101014)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const Color textPrimary = Color(0xFFF5F4FA);
  static const Color textSecondary = Color(0xFFC8C5D3);
  static const Color textMuted = Color(0xFF9793A5);

  static const Color error = Color(0xFFFF6B72);
  static const Color success = Color(0xFF48C78E);
  static const Color warning = brandYellow;

  static Color backgroundOf(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;

  static Color surfaceOf(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  static Color textPrimaryOf(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  static Color borderOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? border
          : const Color(0xFFE6E4EC);

  static Color cardOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? surfaceElevated
          : Colors.white;
}

import 'package:flutter/material.dart';

/// Design tokens extracted from `erp telas/*/DESIGN.md` (DirectDistribution design system).
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFA04100);
  static const Color primaryContainer = Color(0xFFFF6B00);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF572000);
  static const Color inversePrimary = Color(0xFFFFB693);

  static const Color secondary = Color(0xFF5F5E5E);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFE2DFDE);
  static const Color onSecondaryContainer = Color(0xFF636262);

  static const Color tertiary = Color(0xFF5D5F5F);
  static const Color onTertiaryFixed = Color(0xFF1A1C1C);

  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  static const Color primaryFixed = Color(0xFFFFDBCC);
  static const Color primaryFixedDim = Color(0xFFFFB693);
  static const Color onPrimaryFixedVariant = Color(0xFF7A3000);

  static const Color background = Color(0xFFFBF9F8);
  static const Color onBackground = Color(0xFF1B1C1C);

  static const Color surface = Color(0xFFFBF9F8);
  static const Color surfaceDim = Color(0xFFDBDAD9);
  static const Color surfaceBright = Color(0xFFFBF9F8);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF5F3F3);
  static const Color surfaceContainer = Color(0xFFEFEDED);
  static const Color surfaceContainerHigh = Color(0xFFE9E8E7);
  static const Color surfaceContainerHighest = Color(0xFFE4E2E2);
  static const Color surfaceVariant = Color(0xFFE4E2E2);

  static const Color onSurface = Color(0xFF1B1C1C);
  static const Color onSurfaceVariant = Color(0xFF5A4136);

  static const Color outline = Color(0xFF8E7164);
  static const Color outlineVariant = Color(0xFFE2BFB0);

  /// Card background used across product/order lists (#F5F5F5 in the mockups).
  static const Color cardBackground = Color(0xFFF5F5F5);

  /// Stock alert red, used only for the "Estoque baixo" badge.
  static const Color lowStock = Color(0xFFE74C3C);

  /// Success green, used for "Entregue" status.
  static const Color success = Color(0xFF27AE60);
}

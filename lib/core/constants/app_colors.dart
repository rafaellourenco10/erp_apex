import 'package:flutter/material.dart';

/// Design tokens. Originally extracted from `erp telas/*/DESIGN.md`; neutrals
/// re-based on Shopify Polaris in 2026-10-02 (gray `#F1F1F1` canvas, white
/// cards, `#1A1A1A` top bar, `#303030`/`#616161` text) with the brand orange
/// kept as the single accent.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF9A3412);
  /// Laranja da marca (Tailwind orange-700). Histórico: #FF6B00 original
  /// tinha contraste ~2.9:1 com branco (abaixo do WCAG AA); em 2026-09-16
  /// virou #BF360C (5.6:1, mas puxado pro tijolo); em 2026-10-02 virou este
  /// tom mais vivo, ainda 5.2:1 — usado como texto e como fundo no app.
  static const Color primaryContainer = Color(0xFFC2410C);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF7C2D12);
  static const Color inversePrimary = Color(0xFFFDBA74);

  static const Color secondary = Color(0xFF616161);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFEBEBEB);
  static const Color onSecondaryContainer = Color(0xFF616161);

  static const Color tertiary = Color(0xFF0369A1);
  static const Color onTertiaryFixed = Color(0xFF1A1A1A);

  static const Color error = Color(0xFFDC2626);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color onErrorContainer = Color(0xFF991B1B);

  static const Color primaryFixed = Color(0xFFFFEDD5);
  static const Color primaryFixedDim = Color(0xFFFDBA74);
  static const Color onPrimaryFixedVariant = Color(0xFF9A3412);

  static const Color background = Color(0xFFF1F1F1);
  static const Color onBackground = Color(0xFF303030);

  static const Color surface = Color(0xFFF1F1F1);
  static const Color surfaceDim = Color(0xFFB5B5B5);
  static const Color surfaceBright = Color(0xFFF1F1F1);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF7F7F7);
  static const Color surfaceContainer = Color(0xFFEBEBEB);
  static const Color surfaceContainerHigh = Color(0xFFE3E3E3);
  static const Color surfaceContainerHighest = Color(0xFFD4D4D4);
  static const Color surfaceVariant = Color(0xFFE3E3E3);

  static const Color onSurface = Color(0xFF303030);
  static const Color onSurfaceVariant = Color(0xFF616161);

  static const Color outline = Color(0xFF8A8A8A);
  static const Color outlineVariant = Color(0xFFCCCCCC);

  /// Card background used across product/order lists — white over the gray canvas.
  static const Color cardBackground = Color(0xFFFFFFFF);

  /// Stock alert red, used only for the "Estoque baixo" badge.
  static const Color lowStock = Color(0xFFDC2626);

  /// Success green, used for "Entregue" status.
  static const Color success = Color(0xFF15803D);

  /// Status hues — all ≥4.5:1 against white, so they work both as solid
  /// fills with white text and as text over their own light tint.
  static const Color warning = Color(0xFFB45309);
  static const Color violet = Color(0xFF7C3AED);
}

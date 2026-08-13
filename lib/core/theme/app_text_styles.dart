import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

/// Typography scale from the DirectDistribution design system (Inter font).
class AppTextStyles {
  AppTextStyles._();

  static TextStyle _inter({
    required double fontSize,
    required FontWeight fontWeight,
    required double height,
    double letterSpacing = 0,
    Color color = AppColors.onSurface,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height / fontSize,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  static TextStyle headlineLg({Color color = AppColors.onSurface}) =>
      _inter(fontSize: 24, fontWeight: FontWeight.w700, height: 32, letterSpacing: -0.5, color: color);

  static TextStyle headlineMd({Color color = AppColors.onSurface}) =>
      _inter(fontSize: 20, fontWeight: FontWeight.w600, height: 28, letterSpacing: -0.2, color: color);

  static TextStyle headlineSm({Color color = AppColors.onSurface}) =>
      _inter(fontSize: 16, fontWeight: FontWeight.w600, height: 24, color: color);

  static TextStyle bodyLg({Color color = AppColors.onSurface}) =>
      _inter(fontSize: 16, fontWeight: FontWeight.w400, height: 24, color: color);

  static TextStyle bodyMd({Color color = AppColors.onSurfaceVariant}) =>
      _inter(fontSize: 14, fontWeight: FontWeight.w400, height: 20, color: color);

  static TextStyle labelLg({Color color = AppColors.onSurface}) =>
      _inter(fontSize: 14, fontWeight: FontWeight.w600, height: 20, color: color);

  static TextStyle labelMd({Color color = AppColors.onSurfaceVariant}) =>
      _inter(fontSize: 12, fontWeight: FontWeight.w500, height: 16, color: color);

  static TextStyle labelSm({Color color = AppColors.onSurfaceVariant}) =>
      _inter(fontSize: 10, fontWeight: FontWeight.w600, height: 12, color: color);
}

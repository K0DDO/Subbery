import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(
    brightness: Brightness.light,
    background: AppColors.lightBackground,
    foreground: AppColors.lightText,
  );

  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    background: AppColors.darkBackground,
    foreground: AppColors.darkText,
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color foreground,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.coral,
      brightness: brightness,
      surface: background,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.manropeTextTheme().apply(
        bodyColor: foreground,
        displayColor: foreground,
      ),
    );
  }
}

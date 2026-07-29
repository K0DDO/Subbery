import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'glass_theme.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(
    brightness: Brightness.light,
    background: AppColors.lightBackground,
    foreground: AppColors.lightText,
    muted: AppColors.lightMutedText,
    glassTheme: const GlassTheme(
      surface: Color(0x73FFFFFF),
      strongSurface: Color(0xA6FFFFFF),
      border: Color(0x99FFFFFF),
      highlight: Color(0xCCFFFFFF),
      shadow: Color(0x267D3E45),
      blur: 22,
    ),
  );

  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    background: AppColors.darkBackground,
    foreground: AppColors.darkText,
    muted: AppColors.darkMutedText,
    glassTheme: const GlassTheme(
      surface: Color(0x14FFFFFF),
      strongSurface: Color(0x24FFFFFF),
      border: Color(0x29FFFFFF),
      highlight: Color(0x38FFFFFF),
      shadow: Color(0x66000000),
      blur: 24,
    ),
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color foreground,
    required Color muted,
    required GlassTheme glassTheme,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.coral,
      brightness: brightness,
      surface: background,
    );

    final baseTextTheme = GoogleFonts.manropeTextTheme();
    final textTheme = baseTextTheme
        .copyWith(
          displayLarge: baseTextTheme.displayLarge?.copyWith(
            fontSize: 52,
            height: 1.02,
            fontWeight: FontWeight.w700,
            letterSpacing: -2.2,
          ),
          displaySmall: baseTextTheme.displaySmall?.copyWith(
            fontSize: 36,
            height: 1.08,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.4,
          ),
          headlineMedium: baseTextTheme.headlineMedium?.copyWith(
            fontSize: 26,
            height: 1.15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.7,
          ),
          titleLarge: baseTextTheme.titleLarge?.copyWith(
            fontSize: 20,
            height: 1.25,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
          titleMedium: baseTextTheme.titleMedium?.copyWith(
            fontSize: 16,
            height: 1.3,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: baseTextTheme.bodyLarge?.copyWith(
            fontSize: 16,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
          bodyMedium: baseTextTheme.bodyMedium?.copyWith(
            fontSize: 14,
            height: 1.45,
            fontWeight: FontWeight.w500,
          ),
          labelLarge: baseTextTheme.labelLarge?.copyWith(
            fontSize: 15,
            height: 1.2,
            fontWeight: FontWeight.w700,
          ),
        )
        .apply(bodyColor: foreground, displayColor: foreground);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[glassTheme],
      dividerColor: glassTheme.border,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: glassTheme.surface,
        hintStyle: textTheme.bodyLarge?.copyWith(color: muted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: glassTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: glassTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.coral, width: 1.5),
        ),
      ),
    );
  }
}

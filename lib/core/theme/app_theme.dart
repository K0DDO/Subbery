import 'package:flutter/material.dart';

import 'app_accent_theme.dart';
import 'glass_theme.dart';

abstract final class AppTheme {
  static ThemeData get light => lightFor(AppAccentChoice.peach);

  static ThemeData get dark => darkFor(AppAccentChoice.peach);

  static ThemeData lightFor(AppAccentChoice accentChoice) =>
      _build(brightness: Brightness.light, accentChoice: accentChoice);

  static ThemeData darkFor(AppAccentChoice accentChoice) =>
      _build(brightness: Brightness.dark, accentChoice: accentChoice);

  static ThemeData _build({
    required Brightness brightness,
    required AppAccentChoice accentChoice,
  }) {
    final accent = SubberryTheme.fromChoice(accentChoice, brightness);
    final isDark = brightness == Brightness.dark;
    final foreground = isDark
        ? const Color(0xFFFFF8F5)
        : const Color(0xFF291C1C);
    final muted = accent.mutedTextColor;
    final glassTheme = GlassTheme(
      surface: Color.lerp(
        isDark ? const Color(0x14FFFFFF) : const Color(0x73FFFFFF),
        accent.glassTint,
        isDark ? 0.42 : 0.32,
      )!,
      strongSurface: Color.lerp(
        isDark ? const Color(0x24FFFFFF) : const Color(0xA6FFFFFF),
        accent.glassTint,
        isDark ? 0.5 : 0.28,
      )!,
      border: Color.lerp(
        isDark ? const Color(0x29FFFFFF) : const Color(0x99FFFFFF),
        accent.borderColor,
        isDark ? 0.7 : 0.46,
      )!,
      highlight: Color.lerp(
        isDark ? const Color(0x38FFFFFF) : const Color(0xCCFFFFFF),
        accent.primaryLight.withValues(alpha: isDark ? 0.24 : 0.4),
        0.28,
      )!,
      shadow: Color.lerp(
        isDark ? const Color(0x66000000) : const Color(0x267D3E45),
        accent.glowColor,
        isDark ? 0.42 : 0.32,
      )!,
      blur: isDark ? 24 : 22,
    );
    final onPrimary = accent.primary.computeLuminance() > 0.48
        ? const Color(0xFF211719)
        : const Color(0xFFFFFBFA);
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: accent.primary,
          brightness: brightness,
          surface: accent.backgroundStart,
        ).copyWith(
          primary: accent.primary,
          onPrimary: onPrimary,
          primaryContainer: accent.softBackgroundTint,
          secondary: accent.primaryLight,
          secondaryContainer: accent.primaryLight.withValues(alpha: 0.18),
          tertiary: accent.primaryDark,
          error: accent.error,
          outline: accent.borderColor,
          outlineVariant: accent.borderColor.withValues(alpha: 0.55),
        );

    final baseTextTheme = ThemeData(
      brightness: brightness,
      useMaterial3: true,
    ).textTheme;
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
      scaffoldBackgroundColor: accent.backgroundStart,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[glassTheme, accent],
      dividerColor: glassTheme.border,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      iconTheme: IconThemeData(color: accent.primary),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return muted.withValues(alpha: 0.34);
            }
            if (states.contains(WidgetState.pressed) ||
                states.contains(WidgetState.hovered)) {
              return accent.primaryDark;
            }
            return accent.primary;
          }),
          foregroundColor: WidgetStatePropertyAll(onPrimary),
          overlayColor: WidgetStatePropertyAll(
            accent.primaryLight.withValues(alpha: 0.14),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        selectedColor: accent.softBackgroundTint,
        side: BorderSide(color: accent.borderColor),
        secondaryLabelStyle: TextStyle(color: accent.primaryDark),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color.alphaBlend(accent.glassTint, glassTheme.surface),
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
          borderSide: BorderSide(color: accent.primary, width: 1.5),
        ),
      ),
    );
  }
}

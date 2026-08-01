import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subberry/core/theme/app_accent_theme.dart';
import 'package:subberry/core/theme/app_theme.dart';
import 'package:subberry/core/theme/glass_theme.dart';

void main() {
  test('builds a coordinated theme for the selected accent', () {
    final theme = AppTheme.darkFor(AppAccentChoice.emerald);
    final accent = theme.extension<SubberryTheme>();

    expect(theme.colorScheme.primary, AppAccentChoice.emerald.primary);
    expect(theme.colorScheme.secondary, AppAccentChoice.emerald.secondary);
    expect(theme.colorScheme.tertiary, AppAccentChoice.emerald.tertiary);
    expect(accent?.primary, AppAccentChoice.emerald.primary);
    expect(theme.colorScheme.error, accent?.error);
    expect(accent?.backgroundStart, isNot(equals(accent?.backgroundEnd)));
  });

  test('generates a complete palette from every selected seed', () {
    for (final choice in AppAccentChoice.values) {
      final light = AppTheme.lightFor(choice);
      final dark = AppTheme.darkFor(choice);
      final lightPalette = light.extension<SubberryTheme>()!;
      final darkPalette = dark.extension<SubberryTheme>()!;

      expect(lightPalette.primary, choice.seed);
      expect(lightPalette.primaryLight, isNot(choice.seed));
      expect(lightPalette.primaryDark, isNot(choice.seed));
      expect(lightPalette.glowColor.a, closeTo(0.4, 0.01));
      expect(lightPalette.borderColor.a, closeTo(0.34, 0.01));
      expect(darkPalette.primary, choice.seed);
      expect(
        darkPalette.softBackgroundTint,
        isNot(lightPalette.softBackgroundTint),
      );
      expect(darkPalette.mutedTextColor, isNot(lightPalette.mutedTextColor));
    }
  });

  test('accent choice updates glass, background, and component colors', () {
    final coral = AppTheme.lightFor(AppAccentChoice.coral);
    final purple = AppTheme.lightFor(AppAccentChoice.violet);
    final coralPalette = coral.extension<SubberryTheme>()!;
    final purplePalette = purple.extension<SubberryTheme>()!;
    final coralGlass = coral.extension<GlassTheme>()!;
    final purpleGlass = purple.extension<GlassTheme>()!;

    expect(coral.colorScheme.primary, const Color(0xFFE67F73));
    expect(purple.colorScheme.primary, const Color(0xFF9878C4));
    expect(coralPalette.glassTint, isNot(purplePalette.glassTint));
    expect(coralPalette.backgroundEnd, isNot(purplePalette.backgroundEnd));
    expect(coralGlass.border, isNot(purpleGlass.border));
    expect(coral.dividerColor, isNot(purple.dividerColor));
  });

  test('keeps the default light coral palette warm and subdued', () {
    final theme = AppTheme.light;
    final palette = theme.extension<SubberryTheme>()!;
    final glass = theme.extension<GlassTheme>()!;

    expect(theme.colorScheme.primary, const Color(0xFFE67F73));
    expect(palette.backgroundStart.computeLuminance(), lessThan(0.65));
    expect(palette.backgroundEnd.computeLuminance(), lessThan(0.65));

    final surface = Color.alphaBlend(glass.surface, palette.backgroundStart);
    final strongSurface = Color.alphaBlend(
      glass.strongSurface,
      palette.backgroundStart,
    );
    expect(
      (surface.computeLuminance() - palette.backgroundStart.computeLuminance())
          .abs(),
      greaterThan(0.04),
    );
    expect(
      (strongSurface.computeLuminance() -
              palette.backgroundStart.computeLuminance())
          .abs(),
      greaterThan(0.08),
    );
  });

  test(
    'keeps green blue and violet accents lively without neon saturation',
    () {
      for (final choice in <AppAccentChoice>[
        AppAccentChoice.emerald,
        AppAccentChoice.blue,
        AppAccentChoice.violet,
      ]) {
        final saturation = HSLColor.fromColor(choice.seed).saturation;
        expect(saturation, greaterThan(0.3), reason: choice.label);
        expect(saturation, lessThan(0.7), reason: choice.label);
      }
    },
  );
}

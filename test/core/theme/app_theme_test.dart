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
      expect(lightPalette.glowColor.a, closeTo(0.35, 0.01));
      expect(lightPalette.categoryColors, hasLength(8));
      expect(lightPalette.categoryColors.toSet().length, greaterThan(4));
      expect(lightPalette.borderColor.a, closeTo(0.2, 0.01));
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

    expect(coral.colorScheme.primary, const Color(0xFFFF7665));
    expect(purple.colorScheme.primary, const Color(0xFFA855F7));
    expect(coralPalette.glassTint, isNot(purplePalette.glassTint));
    expect(coralPalette.backgroundEnd, isNot(purplePalette.backgroundEnd));
    expect(coralGlass.border, isNot(purpleGlass.border));
    expect(coral.dividerColor, isNot(purple.dividerColor));
  });
}

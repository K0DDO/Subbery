import 'package:flutter/material.dart';

import 'app_accent_theme.dart';
import 'glass_theme.dart';

/// Resolved liquid-glass parameters for a given effect strength.
///
/// strength 0 = current matte Subberry glass; 1 = full Liquid Glass.
@immutable
class LiquidGlassTokens {
  const LiquidGlassTokens({
    required this.blur,
    required this.fill,
    required this.rimHighlight,
    required this.rimShadow,
    required this.innerGlow,
    required this.shadowColor,
    required this.shadowBlur,
    required this.shadowOffsetY,
    required this.shadowSpread,
    required this.highlightStrength,
    required this.borderAlpha,
    required this.sheenEnabled,
    required this.sheenAlpha,
  });

  final double blur;
  final Color fill;
  final Color rimHighlight;
  final Color rimShadow;
  final Color innerGlow;
  final Color shadowColor;
  final double shadowBlur;
  final double shadowOffsetY;
  final double shadowSpread;
  final double highlightStrength;
  final double borderAlpha;
  final bool sheenEnabled;
  final double sheenAlpha;

  factory LiquidGlassTokens.resolve({
    required double strength,
    required GlassTheme glass,
    required SubberryTheme palette,
    required Brightness brightness,
    required bool strong,
    double progress = 1,
  }) {
    final t = strength.clamp(0.0, 1.0);
    final p = progress.clamp(0.0, 1.0);
    final isDark = brightness == Brightness.dark;
    final base = strong ? glass.strongSurface : glass.surface;

    // Higher strength → stronger blur, lower fill density so the berry
    // background reads through the glass.
    final blur = glass.blur + t * (isDark ? 18 : 16);
    final fillAlpha = (base.a * (1 - t * 0.62)).clamp(0.08, 1.0);
    final fill = Color.alphaBlend(
      palette.glassTint.withValues(
        alpha: palette.glassTint.a * (0.35 + t * 0.55),
      ),
      base.withValues(alpha: fillAlpha),
    );

    final highlightStrength = 0.18 + t * 0.72;
    final borderAlpha = (isDark ? 0.22 : 0.34) + t * (isDark ? 0.28 : 0.36);
    final rimHighlight = Color.lerp(
      glass.highlight,
      Color.lerp(Colors.white, palette.primaryLight, isDark ? 0.35 : 0.18)!,
      t,
    )!.withValues(alpha: (isDark ? 0.28 : 0.55) + t * 0.42);
    final rimShadow = Color.lerp(
      glass.border,
      Color.lerp(palette.primaryDark, Colors.black, isDark ? 0.45 : 0.25)!,
      t,
    )!.withValues(alpha: (isDark ? 0.18 : 0.12) + t * 0.28);

    final shadowBlur = 32 + t * 22 + p * 8;
    final shadowOffsetY = 14 + t * 8 + p * 4;
    final shadowSpread = t * 2.5;
    final shadowColor = Color.lerp(
      glass.shadow,
      palette.glowColor.withValues(alpha: isDark ? 0.45 : 0.32),
      t * 0.7,
    )!;

    final innerGlow = Color.lerp(
      glass.highlight.withValues(alpha: 0.08),
      palette.primaryLight.withValues(alpha: isDark ? 0.14 : 0.22),
      t,
    )!;

    return LiquidGlassTokens(
      blur: blur,
      fill: fill,
      rimHighlight: rimHighlight,
      rimShadow: rimShadow,
      innerGlow: innerGlow,
      shadowColor: shadowColor,
      shadowBlur: shadowBlur,
      shadowOffsetY: shadowOffsetY,
      shadowSpread: shadowSpread,
      highlightStrength: highlightStrength,
      borderAlpha: borderAlpha,
      sheenEnabled: t >= 0.35,
      sheenAlpha: ((t - 0.35) / 0.65).clamp(0.0, 1.0) * (isDark ? 0.18 : 0.28),
    );
  }
}

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
    required this.edgeShade,
    required this.reflectionTint,
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
  final Color edgeShade;
  final Color reflectionTint;
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

    // Opacity, not brightness, is the primary transition. At maximum the
    // background remains clearly visible through the blurred material.
    final materialT = Curves.easeInOutCubic.transform(t);
    final targetBlur = isDark ? 6.0 : 5.0;
    final blur = glass.blur + (targetBlur - glass.blur) * materialT;
    final targetFillAlpha = (isDark ? 0.07 : 0.055) + (strong ? 0.035 : 0);
    final fill = Color.lerp(
      base,
      palette.glassTint.withValues(alpha: targetFillAlpha),
      materialT,
    )!;

    final highlightStrength = 0.14 + t * 0.16;
    final borderAlpha = Color.lerp(
      glass.border,
      glass.border.withValues(alpha: isDark ? 0.1 : 0.12),
      materialT,
    )!.a;
    final rimHighlight = Color.lerp(
      glass.highlight,
      palette.primaryLight,
      t * 0.25,
    )!.withValues(alpha: (isDark ? 0.13 : 0.16) - t * 0.035);
    final rimShadow = Color.lerp(
      glass.border,
      palette.primaryDark,
      t * 0.35,
    )!.withValues(alpha: (isDark ? 0.12 : 0.1) + t * 0.025);

    final shadowBlur = 30 + t * 14 + p * 6;
    final shadowOffsetY = 12 + t * 5 + p * 3;
    final shadowSpread = t * 0.8;
    final shadowColor = Color.lerp(
      glass.shadow,
      palette.primaryDark.withValues(alpha: isDark ? 0.22 : 0.14),
      t * 0.45,
    )!;

    final innerGlow = Color.lerp(
      glass.highlight.withValues(alpha: isDark ? 0.055 : 0.07),
      palette.primaryLight.withValues(alpha: isDark ? 0.075 : 0.085),
      t,
    )!;
    final edgeShade = Color.lerp(
      glass.border.withValues(alpha: isDark ? 0.045 : 0.035),
      palette.primaryDark.withValues(alpha: isDark ? 0.095 : 0.065),
      t,
    )!;
    final reflectionTint = Color.lerp(
      glass.highlight,
      palette.primaryLight,
      isDark ? 0.38 : 0.2,
    )!.withValues(alpha: isDark ? 0.028 : 0.035);

    return LiquidGlassTokens(
      blur: blur,
      fill: fill,
      rimHighlight: rimHighlight,
      rimShadow: rimShadow,
      innerGlow: innerGlow,
      edgeShade: edgeShade,
      reflectionTint: reflectionTint,
      shadowColor: shadowColor,
      shadowBlur: shadowBlur,
      shadowOffsetY: shadowOffsetY,
      shadowSpread: shadowSpread,
      highlightStrength: highlightStrength,
      borderAlpha: borderAlpha,
      sheenEnabled: t >= 0.6,
      sheenAlpha: ((t - 0.6) / 0.4).clamp(0.0, 1.0) * (isDark ? 0.022 : 0.03),
    );
  }
}

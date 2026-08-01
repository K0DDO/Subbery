import 'package:flutter/material.dart';

/// Shared four-stop color token used by category and brand systems.
@immutable
class ColorPalette {
  const ColorPalette({
    required this.primary,
    required this.light,
    required this.dark,
    required this.glow,
  });

  factory ColorPalette.fromSeed(
    Color seed, {
    Brightness brightness = Brightness.light,
    Color? light,
    Color? dark,
    Color? glow,
  }) {
    final normalized = _normalizeSeed(seed, brightness);
    final resolvedLight = light ?? _shiftLightness(normalized, 0.14);
    final resolvedDark = dark ?? _shiftLightness(normalized, -0.16);
    return ColorPalette(
      primary: normalized,
      light: resolvedLight,
      dark: resolvedDark,
      glow: glow ?? normalized.withValues(alpha: 0.42),
    );
  }

  final Color primary;
  final Color light;
  final Color dark;
  final Color glow;

  LinearGradient get gradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[light, primary, dark],
  );

  ColorPalette forBrightness(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ColorPalette(
      primary: _shiftLightness(primary, isDark ? 0.05 : -0.02),
      light: _shiftLightness(light, isDark ? 0.04 : -0.01),
      dark: _shiftLightness(dark, isDark ? 0.06 : -0.03),
      glow: glow.withValues(alpha: isDark ? 0.48 : 0.38),
    );
  }

  ColorPalette lerp(ColorPalette other, double t) {
    return ColorPalette(
      primary: Color.lerp(primary, other.primary, t)!,
      light: Color.lerp(light, other.light, t)!,
      dark: Color.lerp(dark, other.dark, t)!,
      glow: Color.lerp(glow, other.glow, t)!,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ColorPalette &&
        other.primary == primary &&
        other.light == light &&
        other.dark == dark &&
        other.glow == glow;
  }

  @override
  int get hashCode => Object.hash(primary, light, dark, glow);
}

Color _normalizeSeed(Color seed, Brightness brightness) {
  final hsl = HSLColor.fromColor(seed);
  if (hsl.lightness > 0.12 && hsl.lightness < 0.9) {
    return seed;
  }
  // Lift near-black / near-white brands so they remain visible on glass.
  final targetLightness = brightness == Brightness.dark ? 0.42 : 0.28;
  final saturation = hsl.saturation < 0.08 ? 0.12 : hsl.saturation;
  return hsl
      .withSaturation(saturation.clamp(0.12, 1.0))
      .withLightness(targetLightness)
      .toColor();
}

Color _shiftLightness(Color color, double amount) {
  final hsl = HSLColor.fromColor(color);
  return hsl
      .withLightness((hsl.lightness + amount).clamp(0.08, 0.94))
      .toColor();
}

import 'package:flutter/material.dart';

@immutable
class GlassTheme extends ThemeExtension<GlassTheme> {
  const GlassTheme({
    required this.surface,
    required this.strongSurface,
    required this.border,
    required this.highlight,
    required this.shadow,
    required this.blur,
  });

  final Color surface;
  final Color strongSurface;
  final Color border;
  final Color highlight;
  final Color shadow;
  final double blur;

  @override
  GlassTheme copyWith({
    Color? surface,
    Color? strongSurface,
    Color? border,
    Color? highlight,
    Color? shadow,
    double? blur,
  }) {
    return GlassTheme(
      surface: surface ?? this.surface,
      strongSurface: strongSurface ?? this.strongSurface,
      border: border ?? this.border,
      highlight: highlight ?? this.highlight,
      shadow: shadow ?? this.shadow,
      blur: blur ?? this.blur,
    );
  }

  @override
  GlassTheme lerp(GlassTheme? other, double t) {
    if (other == null) return this;
    return GlassTheme(
      surface: Color.lerp(surface, other.surface, t)!,
      strongSurface: Color.lerp(strongSurface, other.strongSurface, t)!,
      border: Color.lerp(border, other.border, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      blur: blur + (other.blur - blur) * t,
    );
  }
}

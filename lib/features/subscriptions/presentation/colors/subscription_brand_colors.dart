import 'package:flutter/material.dart';

import '../../../../core/theme/color_palette.dart';
import '../../data/catalog/known_services.dart';
import '../../domain/entities/subscription.dart';
import 'category_colors.dart';

/// Brand palettes for known services, with stable custom fallbacks.
abstract final class SubscriptionBrandColors {
  static const Map<String, ColorPalette> _explicit =
      <String, ColorPalette>{
        'netflix': ColorPalette(
          primary: Color(0xFFE50914),
          light: Color(0xFFFF4D57),
          dark: Color(0xFFB20710),
          glow: Color(0x66E50914),
        ),
        'spotify': ColorPalette(
          primary: Color(0xFF1DB954),
          light: Color(0xFF4CDE7C),
          dark: Color(0xFF128C3E),
          glow: Color(0x661DB954),
        ),
        'telegram': ColorPalette(
          primary: Color(0xFF2AABEE),
          light: Color(0xFF5CC4F5),
          dark: Color(0xFF1A7FB8),
          glow: Color(0x662AABEE),
        ),
      };

  static ColorPalette resolve({
    required String name,
    String? logoKey,
    required SubscriptionCategory category,
    Brightness brightness = Brightness.light,
  }) {
    final explicit = _explicit[logoKey];
    if (explicit != null) {
      return brightness == Brightness.dark
          ? explicit.forBrightness(brightness)
          : explicit;
    }

    final known = KnownServices.byLogoKey(logoKey);
    if (known != null) {
      return ColorPalette.fromSeed(
        Color(known.brandColorValue),
        brightness: brightness,
      );
    }

    return customFallback(
      name: name,
      logoKey: logoKey,
      category: category,
      brightness: brightness,
    );
  }

  static ColorPalette customFallback({
    required String name,
    String? logoKey,
    required SubscriptionCategory category,
    Brightness brightness = Brightness.light,
  }) {
    final base = CategoryColors.palette(category, brightness: brightness);
    final hash = Object.hash(name.trim().toLowerCase(), logoKey ?? '');
    final hueNudge = ((hash % 17) - 8) / 90.0;
    final lightNudge = ((hash % 11) - 5) / 120.0;
    final hsl = HSLColor.fromColor(base.primary);
    final nudged = hsl
        .withHue((hsl.hue + hueNudge * 360) % 360)
        .withLightness((hsl.lightness + lightNudge).clamp(0.18, 0.78))
        .toColor();
    return ColorPalette.fromSeed(
      nudged,
      brightness: brightness,
    ).forBrightness(brightness);
  }
}

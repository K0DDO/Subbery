import 'package:flutter/material.dart';

import '../../../../core/theme/color_palette.dart';
import '../../domain/entities/subscription.dart';

/// Semantic category palettes that stay stable across accent themes.
abstract final class CategoryColors {
  static const Map<SubscriptionCategory, Color> _seeds =
      <SubscriptionCategory, Color>{
        SubscriptionCategory.entertainment: Color(0xFFE36B5C), // coral
        SubscriptionCategory.music: Color(0xFF4FAE78), // green
        SubscriptionCategory.work: Color(0xFFE08A45), // orange
        SubscriptionCategory.cloud: Color(0xFF5B8FCF), // blue
        SubscriptionCategory.gaming: Color(0xFF8B6BC9), // purple
        SubscriptionCategory.education: Color(0xFFE0B14A), // yellow
        SubscriptionCategory.health: Color(0xFFE07A9A), // pink
        SubscriptionCategory.other: Color(0xFF8B7E8A), // neutral mauve
      };

  static ColorPalette palette(
    SubscriptionCategory category, {
    Brightness brightness = Brightness.light,
  }) {
    final seed = _seeds[category] ?? _seeds[SubscriptionCategory.other]!;
    return ColorPalette.fromSeed(seed, brightness: brightness)
        .forBrightness(brightness);
  }

  static Color primary(
    SubscriptionCategory category, {
    Brightness brightness = Brightness.light,
  }) => palette(category, brightness: brightness).primary;

  static Map<SubscriptionCategory, ColorPalette> all({
    Brightness brightness = Brightness.light,
  }) {
    return <SubscriptionCategory, ColorPalette>{
      for (final category in SubscriptionCategory.values)
        category: palette(category, brightness: brightness),
    };
  }
}

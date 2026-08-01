import 'package:flutter/material.dart';

import '../../../core/theme/color_palette.dart';
import '../data/catalog/known_services.dart';
import '../domain/entities/subscription.dart';
import 'colors/category_colors.dart';
import 'colors/subscription_brand_colors.dart';

@immutable
class ResolvedSubscriptionVisual {
  const ResolvedSubscriptionVisual({
    required this.palette,
    required this.knownService,
    required this.isBrand,
  });

  final ColorPalette palette;
  final KnownService? knownService;
  final bool isBrand;

  Color get primary => palette.primary;
  Color get light => palette.light;
  Color get dark => palette.dark;
  Color get glow => palette.glow;
  LinearGradient get gradient => palette.gradient;
}

ResolvedSubscriptionVisual resolveSubscriptionVisual({
  required String name,
  String? logoKey,
  required SubscriptionCategory category,
  required Brightness brightness,
}) {
  final known = KnownServices.byLogoKey(logoKey);
  final palette = SubscriptionBrandColors.resolve(
    name: name,
    logoKey: logoKey,
    category: category,
    brightness: brightness,
  );
  return ResolvedSubscriptionVisual(
    palette: palette,
    knownService: known,
    isBrand: known != null,
  );
}

ColorPalette categoryPalette(
  SubscriptionCategory category,
  Brightness brightness,
) => CategoryColors.palette(category, brightness: brightness);

import 'package:flutter/material.dart';
import 'package:simple_icons/simple_icons.dart';

import '../../data/catalog/known_services.dart';
import '../../domain/entities/subscription.dart';
import '../subscription_ui_extensions.dart';

class ServiceLogo extends StatelessWidget {
  const ServiceLogo({
    required this.name,
    required this.category,
    this.logoKey,
    this.size = 56,
    super.key,
  });

  final String name;
  final String? logoKey;
  final SubscriptionCategory category;
  final double size;

  @override
  Widget build(BuildContext context) {
    KnownService? knownService;
    for (final service in KnownServices.all) {
      if (service.logoKey == logoKey) {
        knownService = service;
        break;
      }
    }

    final color = knownService == null
        ? category.color
        : Color(knownService.brandColorValue);
    final monogram =
        knownService?.monogram ??
        (name.trim().isEmpty ? 'S' : name.trim().substring(0, 1).toUpperCase());
    final brandIcon = _brandIconFor(knownService?.logoKey);

    return Semantics(
      image: true,
      label: 'Логотип $name',
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.3),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              color.withValues(alpha: 0.96),
              Color.lerp(color, Colors.black, 0.22)!,
            ],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.42)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: color.withValues(alpha: 0.28),
              blurRadius: size * 0.4,
              offset: Offset(0, size * 0.14),
            ),
          ],
        ),
        child: brandIcon == null
            ? Text(
                monogram,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.42,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              )
            : Icon(brandIcon, color: Colors.white, size: size * 0.48),
      ),
    );
  }

  static IconData? _brandIconFor(String? logoKey) => switch (logoKey) {
    'netflix' => SimpleIcons.netflix,
    'spotify' => SimpleIcons.spotify,
    'telegram' => SimpleIcons.telegram,
    'discord' => SimpleIcons.discord,
    'icloud' => SimpleIcons.icloud,
    'youtube' => SimpleIcons.youtube,
    'apple_music' => SimpleIcons.applemusic,
    'google_one' => SimpleIcons.googlecloud,
    'notion' => SimpleIcons.notion,
    'figma' => SimpleIcons.figma,
    'github' => SimpleIcons.github,
    'playstation' => SimpleIcons.playstation,
    _ => null,
  };
}

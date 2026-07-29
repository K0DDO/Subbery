import '../../domain/entities/subscription.dart';

class KnownService {
  const KnownService({
    required this.name,
    required this.logoKey,
    required this.category,
    required this.brandColorValue,
  });

  final String name;
  final String logoKey;
  final SubscriptionCategory category;
  final int brandColorValue;

  String get monogram => name.substring(0, 1).toUpperCase();
}

abstract final class KnownServices {
  static const all = <KnownService>[
    KnownService(
      name: 'Netflix',
      logoKey: 'netflix',
      category: SubscriptionCategory.entertainment,
      brandColorValue: 0xFFE50914,
    ),
    KnownService(
      name: 'Spotify',
      logoKey: 'spotify',
      category: SubscriptionCategory.music,
      brandColorValue: 0xFF1DB954,
    ),
    KnownService(
      name: 'Telegram Premium',
      logoKey: 'telegram',
      category: SubscriptionCategory.other,
      brandColorValue: 0xFF2AABEE,
    ),
    KnownService(
      name: 'Discord Nitro',
      logoKey: 'discord',
      category: SubscriptionCategory.gaming,
      brandColorValue: 0xFF5865F2,
    ),
    KnownService(
      name: 'iCloud',
      logoKey: 'icloud',
      category: SubscriptionCategory.cloud,
      brandColorValue: 0xFF4A9EFF,
    ),
    KnownService(
      name: 'YouTube Premium',
      logoKey: 'youtube',
      category: SubscriptionCategory.entertainment,
      brandColorValue: 0xFFFF0033,
    ),
    KnownService(
      name: 'Apple Music',
      logoKey: 'apple_music',
      category: SubscriptionCategory.music,
      brandColorValue: 0xFFFA243C,
    ),
    KnownService(
      name: 'Google One',
      logoKey: 'google_one',
      category: SubscriptionCategory.cloud,
      brandColorValue: 0xFF4285F4,
    ),
    KnownService(
      name: 'Notion',
      logoKey: 'notion',
      category: SubscriptionCategory.work,
      brandColorValue: 0xFF222222,
    ),
    KnownService(
      name: 'Figma',
      logoKey: 'figma',
      category: SubscriptionCategory.work,
      brandColorValue: 0xFFF24E1E,
    ),
    KnownService(
      name: 'GitHub Copilot',
      logoKey: 'github',
      category: SubscriptionCategory.work,
      brandColorValue: 0xFF6E40C9,
    ),
    KnownService(
      name: 'PlayStation Plus',
      logoKey: 'playstation',
      category: SubscriptionCategory.gaming,
      brandColorValue: 0xFF0070D1,
    ),
  ];

  static KnownService? exactMatch(String query) {
    final normalizedQuery = _normalize(query);
    for (final service in all) {
      if (_normalize(service.name) == normalizedQuery) return service;
    }
    return null;
  }

  static List<KnownService> suggestionsFor(String query, {int limit = 4}) {
    final normalizedQuery = _normalize(query);
    if (normalizedQuery.isEmpty) return const <KnownService>[];

    final matches = all.where((service) {
      return _normalize(service.name).contains(normalizedQuery);
    }).toList();
    matches.sort((left, right) {
      final leftStarts = _normalize(left.name).startsWith(normalizedQuery);
      final rightStarts = _normalize(right.name).startsWith(normalizedQuery);
      if (leftStarts != rightStarts) return leftStarts ? -1 : 1;
      return left.name.compareTo(right.name);
    });
    return matches.take(limit).toList(growable: false);
  }

  static String _normalize(String value) => value.trim().toLowerCase();
}

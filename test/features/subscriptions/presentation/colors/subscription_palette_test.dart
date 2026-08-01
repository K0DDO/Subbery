import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subberry/features/subscriptions/domain/entities/subscription.dart';
import 'package:subberry/features/subscriptions/presentation/colors/category_colors.dart';
import 'package:subberry/features/subscriptions/presentation/colors/subscription_brand_colors.dart';

void main() {
  test('category palettes stay distinct and accent-independent', () {
    final light = CategoryColors.all(brightness: Brightness.light);
    final dark = CategoryColors.all(brightness: Brightness.dark);

    expect(light, hasLength(SubscriptionCategory.values.length));
    final primaries = light.values.map((palette) => palette.primary).toSet();
    expect(primaries, hasLength(SubscriptionCategory.values.length));

    expect(
      light[SubscriptionCategory.entertainment]!.primary,
      isNot(light[SubscriptionCategory.music]!.primary),
    );
    expect(
      dark[SubscriptionCategory.entertainment]!.primary,
      isNot(light[SubscriptionCategory.entertainment]!.primary),
    );
  });

  test('known brands keep canonical primaries', () {
    final netflix = SubscriptionBrandColors.resolve(
      name: 'Netflix',
      logoKey: 'netflix',
      category: SubscriptionCategory.entertainment,
    );
    final spotify = SubscriptionBrandColors.resolve(
      name: 'Spotify',
      logoKey: 'spotify',
      category: SubscriptionCategory.music,
    );
    final telegram = SubscriptionBrandColors.resolve(
      name: 'Telegram Premium',
      logoKey: 'telegram',
      category: SubscriptionCategory.other,
    );

    expect(netflix.primary, const Color(0xFFE50914));
    expect(spotify.primary, const Color(0xFF1DB954));
    expect(telegram.primary, const Color(0xFF2AABEE));
  });

  test('custom fallbacks are deterministic and category-based', () {
    final first = SubscriptionBrandColors.customFallback(
      name: 'Мой сервис',
      category: SubscriptionCategory.cloud,
    );
    final second = SubscriptionBrandColors.customFallback(
      name: 'Мой сервис',
      category: SubscriptionCategory.cloud,
    );
    final other = SubscriptionBrandColors.customFallback(
      name: 'Другой сервис',
      category: SubscriptionCategory.cloud,
    );

    expect(first.primary, second.primary);
    expect(first.primary, isNot(other.primary));
  });

  test('near-black brands are lifted for visibility', () {
    final apple = SubscriptionBrandColors.resolve(
      name: 'Apple TV+',
      logoKey: 'apple_tv',
      category: SubscriptionCategory.entertainment,
    );
    expect(HSLColor.fromColor(apple.primary).lightness, greaterThan(0.15));
  });
}

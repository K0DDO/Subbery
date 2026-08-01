import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'background_pattern_catalog.dart';

class BackgroundPatternChoice {
  const BackgroundPatternChoice._({
    required this.id,
    required this.label,
    this.assetName,
  });

  static const none = BackgroundPatternChoice._(id: 'none', label: 'Без узора');

  static BackgroundPatternChoice get cupid => byId('cupid');
  static BackgroundPatternChoice get strawberry => byId('strawberry');

  factory BackgroundPatternChoice.fromAsset(BackgroundPatternAsset asset) {
    return BackgroundPatternChoice._(
      id: asset.id,
      label: asset.label,
      assetName: asset.id,
    );
  }

  final String id;
  final String label;
  final String? assetName;

  String? get assetPath =>
      assetName == null ? null : 'assets/background_patterns/$assetName.png';

  static final List<BackgroundPatternChoice> values = <BackgroundPatternChoice>[
    none,
    ...backgroundPatternAssets.map(BackgroundPatternChoice.fromAsset),
  ];

  static BackgroundPatternChoice byId(String? id) {
    return values.firstWhere((pattern) => pattern.id == id, orElse: () => none);
  }

  @override
  bool operator ==(Object other) =>
      other is BackgroundPatternChoice && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

final backgroundPatternProvider =
    StateNotifierProvider<BackgroundPatternController, BackgroundPatternChoice>(
      (ref) => BackgroundPatternController(),
    );

class BackgroundPatternController
    extends StateNotifier<BackgroundPatternChoice> {
  BackgroundPatternController() : super(BackgroundPatternChoice.none) {
    unawaited(_restore());
  }

  static const _storageKey = 'background_pattern';

  Future<void> _restore() async {
    final preferences = await SharedPreferences.getInstance();
    final storedPattern = preferences.getString(_storageKey);
    // Legacy enum-style names used the Dart identifier; prefer id, then name map.
    state = BackgroundPatternChoice.byId(storedPattern);
    if (state == BackgroundPatternChoice.none &&
        storedPattern != null &&
        storedPattern != 'none') {
      final legacy = BackgroundPatternChoice.values.firstWhere(
        (pattern) => pattern.assetName == _legacyAssetName(storedPattern),
        orElse: () => BackgroundPatternChoice.none,
      );
      state = legacy;
    }
  }

  Future<void> setPattern(BackgroundPatternChoice pattern) async {
    if (state == pattern) return;
    state = pattern;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, pattern.id);
  }

  static String? _legacyAssetName(String stored) {
    const map = <String, String>{
      'fingers': 'fingers',
      'cupid': 'cupid',
      'rose': 'rose',
      'loveButterfly': 'love_butterfly',
      'coupleBunnies': 'couple_bunnies',
      'teddy': 'teddy',
      'seashell': 'seashell',
      'palm': 'palm',
      'pineapple': 'pineapple',
      'umbrella': 'umbrella',
      'wave': 'wave',
      'dolphin': 'dolphin',
      'strawberry': 'strawberry',
      'bunny': 'bunny',
      'cupcake': 'cupcake',
      'star': 'star',
      'heart': 'heart',
      'flowerBunny': 'flower_bunny',
    };
    return map[stored];
  }
}

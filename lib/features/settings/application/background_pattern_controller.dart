import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum BackgroundPatternChoice {
  none('Без узора', null),
  fingers('Жест', 'fingers'),
  cupid('Купидон', 'cupid'),
  rose('Роза', 'rose'),
  loveButterfly('Бабочка', 'love_butterfly'),
  coupleBunnies('Кролики', 'couple_bunnies'),
  teddy('Мишка', 'teddy'),
  seashell('Ракушка', 'seashell'),
  palm('Пальма', 'palm'),
  pineapple('Ананас', 'pineapple'),
  umbrella('Зонтик', 'umbrella'),
  wave('Волна', 'wave'),
  dolphin('Дельфин', 'dolphin'),
  strawberry('Клубника', 'strawberry'),
  bunny('Кролик', 'bunny'),
  cupcake('Кекс', 'cupcake'),
  star('Звезда', 'star'),
  heart('Сердце', 'heart'),
  flowerBunny('Цветочный кролик', 'flower_bunny');

  const BackgroundPatternChoice(this.label, this.assetName);

  final String label;
  final String? assetName;

  String? get assetPath =>
      assetName == null ? null : 'assets/background_patterns/$assetName.png';
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
    state = BackgroundPatternChoice.values.firstWhere(
      (pattern) => pattern.name == storedPattern,
      orElse: () => BackgroundPatternChoice.none,
    );
  }

  Future<void> setPattern(BackgroundPatternChoice pattern) async {
    if (state == pattern) return;
    state = pattern;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, pattern.name);
  }
}

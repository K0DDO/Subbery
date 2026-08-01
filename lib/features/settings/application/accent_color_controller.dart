import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_accent_theme.dart';

final accentColorProvider =
    StateNotifierProvider<AccentColorController, AppAccentChoice>(
      (ref) => AccentColorController(),
    );

class AccentColorController extends StateNotifier<AppAccentChoice> {
  AccentColorController() : super(AppAccentChoice.coral) {
    unawaited(_restore());
  }

  static const _storageKey = 'accent_color';

  Future<void> _restore() async {
    final preferences = await SharedPreferences.getInstance();
    final storedAccent = preferences.getString(_storageKey);
    state = AppAccentChoice.values.firstWhere(
      (accent) => accent.name == storedAccent,
      orElse: () => AppAccentChoice.coral,
    );
  }

  Future<void> setAccent(AppAccentChoice accent) async {
    if (state == accent) return;
    state = accent;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, accent.name);
  }
}

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final glassEffectProvider =
    StateNotifierProvider<GlassEffectController, double>(
      (ref) => GlassEffectController(),
    );

class GlassEffectController extends StateNotifier<double> {
  GlassEffectController() : super(0) {
    unawaited(_restore());
  }

  static const _key = 'glass_effect_strength';

  Future<void> _restore() async {
    final preferences = await SharedPreferences.getInstance();
    state = (preferences.getDouble(_key) ?? 0).clamp(0.0, 1.0);
  }

  Future<void> setStrength(double value) async {
    final next = value.clamp(0.0, 1.0);
    if ((state - next).abs() < 0.001) return;
    state = next;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setDouble(_key, next);
  }
}

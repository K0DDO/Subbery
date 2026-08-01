import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final hapticSettingsProvider =
    StateNotifierProvider<HapticSettingsController, HapticSettings>(
      (ref) => HapticSettingsController(),
    );

class HapticSettings extends Equatable {
  const HapticSettings({this.enabled = true, this.intensity = 0.55});

  final bool enabled;
  final double intensity;

  HapticSettings copyWith({bool? enabled, double? intensity}) {
    return HapticSettings(
      enabled: enabled ?? this.enabled,
      intensity: intensity ?? this.intensity,
    );
  }

  @override
  List<Object?> get props => <Object?>[enabled, intensity];
}

class HapticSettingsController extends StateNotifier<HapticSettings> {
  HapticSettingsController() : super(const HapticSettings()) {
    unawaited(_restore());
  }

  static const _enabledKey = 'haptics_enabled';
  static const _intensityKey = 'haptics_intensity';

  Future<void> _restore() async {
    final preferences = await SharedPreferences.getInstance();
    state = HapticSettings(
      enabled: preferences.getBool(_enabledKey) ?? true,
      intensity: (preferences.getDouble(_intensityKey) ?? 0.55).clamp(0.0, 1.0),
    );
  }

  Future<void> setEnabled(bool value) async {
    if (state.enabled == value) return;
    state = state.copyWith(enabled: value);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_enabledKey, value);
  }

  Future<void> setIntensity(double value) async {
    final next = value.clamp(0.0, 1.0);
    if ((state.intensity - next).abs() < 0.001) return;
    state = state.copyWith(intensity: next);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setDouble(_intensityKey, next);
  }
}

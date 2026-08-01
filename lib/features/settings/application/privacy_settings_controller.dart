import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final privacySettingsProvider =
    StateNotifierProvider<PrivacySettingsController, PrivacySettings>(
      (ref) => PrivacySettingsController(),
    );

/// Bumps whenever revealed spoilers should collapse again.
final moneyRevealEpochProvider =
    StateNotifierProvider<MoneyRevealEpochController, int>(
      (ref) => MoneyRevealEpochController(),
    );

class PrivacySettings extends Equatable {
  const PrivacySettings({
    this.transparentBalance = false,
    this.transparencyStrength = 0.55,
    this.hideNumbers = false,
    this.showKopecks = false,
    this.privateMode = false,
  });

  final bool transparentBalance;
  final double transparencyStrength;
  final bool hideNumbers;
  final bool showKopecks;
  final bool privateMode;

  bool get effectiveHideNumbers => privateMode || hideNumbers;

  bool get effectiveTransparentBalance => privateMode || transparentBalance;

  PrivacySettings copyWith({
    bool? transparentBalance,
    double? transparencyStrength,
    bool? hideNumbers,
    bool? showKopecks,
    bool? privateMode,
  }) {
    return PrivacySettings(
      transparentBalance: transparentBalance ?? this.transparentBalance,
      transparencyStrength: transparencyStrength ?? this.transparencyStrength,
      hideNumbers: hideNumbers ?? this.hideNumbers,
      showKopecks: showKopecks ?? this.showKopecks,
      privateMode: privateMode ?? this.privateMode,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    transparentBalance,
    transparencyStrength,
    hideNumbers,
    showKopecks,
    privateMode,
  ];
}

class PrivacySettingsController extends StateNotifier<PrivacySettings> {
  PrivacySettingsController() : super(const PrivacySettings()) {
    unawaited(_restore());
  }

  static const _transparentKey = 'privacy_transparent_balance';
  static const _strengthKey = 'privacy_transparency_strength';
  static const _hideKey = 'privacy_hide_numbers';
  static const _kopecksKey = 'privacy_show_kopecks';
  static const _privateKey = 'privacy_private_mode';

  Future<void> _restore() async {
    final preferences = await SharedPreferences.getInstance();
    state = PrivacySettings(
      transparentBalance: preferences.getBool(_transparentKey) ?? false,
      transparencyStrength: (preferences.getDouble(_strengthKey) ?? 0.55).clamp(
        0.0,
        1.0,
      ),
      hideNumbers: preferences.getBool(_hideKey) ?? false,
      showKopecks: preferences.getBool(_kopecksKey) ?? false,
      privateMode: preferences.getBool(_privateKey) ?? false,
    );
  }

  Future<void> setTransparentBalance(bool value) async {
    final next = state.copyWith(
      transparentBalance: value,
      privateMode: value ? state.privateMode : false,
    );
    state = next;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_transparentKey, next.transparentBalance);
    await preferences.setBool(_privateKey, next.privateMode);
  }

  Future<void> setTransparencyStrength(double value) async {
    final strength = value.clamp(0.0, 1.0);
    if ((state.transparencyStrength - strength).abs() < 0.001) return;
    state = state.copyWith(transparencyStrength: strength);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setDouble(_strengthKey, strength);
  }

  Future<void> setHideNumbers(bool value) async {
    final next = state.copyWith(
      hideNumbers: value,
      privateMode: value ? state.privateMode : false,
    );
    state = next;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_hideKey, next.hideNumbers);
    await preferences.setBool(_privateKey, next.privateMode);
  }

  Future<void> setShowKopecks(bool value) async {
    if (state.showKopecks == value) return;
    state = state.copyWith(showKopecks: value);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_kopecksKey, value);
  }

  Future<void> setPrivateMode(bool value) async {
    final next = value
        ? state.copyWith(
            privateMode: true,
            hideNumbers: true,
            transparentBalance: true,
          )
        : state.copyWith(privateMode: false);
    state = next;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_privateKey, next.privateMode);
    await preferences.setBool(_hideKey, next.hideNumbers);
    await preferences.setBool(_transparentKey, next.transparentBalance);
  }
}

class MoneyRevealEpochController extends StateNotifier<int> {
  MoneyRevealEpochController() : super(0);

  void hideAll() => state++;
}

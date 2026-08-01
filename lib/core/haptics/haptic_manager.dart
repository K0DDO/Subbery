import 'dart:async';

import 'package:flutter/services.dart';

/// Pluggable haptic backend so intensity/amplitude APIs can replace Flutter
/// services later without rewriting call sites.
abstract class HapticBackend {
  Future<void> selectionClick();
  Future<void> lightImpact();
  Future<void> mediumImpact();
  Future<void> heavyImpact();
}

class SystemHapticBackend implements HapticBackend {
  @override
  Future<void> selectionClick() => HapticFeedback.selectionClick();

  @override
  Future<void> lightImpact() => HapticFeedback.lightImpact();

  @override
  Future<void> mediumImpact() => HapticFeedback.mediumImpact();

  @override
  Future<void> heavyImpact() => HapticFeedback.heavyImpact();
}

enum HapticBand { off, selection, light, medium, heavy }

/// Maps 0–100% intensity to the available Flutter haptic primitives.
HapticBand hapticBandForIntensity(double intensity) {
  final value = intensity.clamp(0.0, 1.0);
  if (value <= 0) return HapticBand.off;
  if (value <= 0.33) return HapticBand.selection;
  if (value <= 0.66) return HapticBand.light;
  if (value <= 0.85) return HapticBand.medium;
  return HapticBand.heavy;
}

enum HapticIntent {
  selection,
  sliderTick,
  toggle,
  sheetOpen,
  sheetClose,
  longPress,
  create,
  destructive,
}

/// App-wide haptic façade. Configure from settings; call semantic helpers.
class HapticManager {
  HapticManager({HapticBackend? backend})
    : _backend = backend ?? SystemHapticBackend();

  static final HapticManager instance = HapticManager();

  final HapticBackend _backend;
  bool enabled = true;
  double intensity = 0.55;

  void configure({required bool enabled, required double intensity}) {
    this.enabled = enabled;
    this.intensity = intensity.clamp(0.0, 1.0);
  }

  Future<void> selection() => _play(HapticIntent.selection);
  Future<void> sliderTick() => _play(HapticIntent.sliderTick);
  Future<void> toggle() => _play(HapticIntent.toggle);
  Future<void> sheetOpen() => _play(HapticIntent.sheetOpen);
  Future<void> sheetClose() => _play(HapticIntent.sheetClose);
  Future<void> longPress() => _play(HapticIntent.longPress);
  Future<void> create() => _play(HapticIntent.create);
  Future<void> destructive() => _play(HapticIntent.destructive);

  Future<void> _play(HapticIntent intent) async {
    if (!enabled) return;
    final band = hapticBandForIntensity(intensity);
    if (band == HapticBand.off) return;

    final resolved = _resolve(intent, band);
    switch (resolved) {
      case HapticBand.off:
        return;
      case HapticBand.selection:
        await _backend.selectionClick();
      case HapticBand.light:
        await _backend.lightImpact();
      case HapticBand.medium:
        await _backend.mediumImpact();
      case HapticBand.heavy:
        await _backend.heavyImpact();
    }
  }

  /// Semantic intent prefers a floor, then is capped by the user intensity band.
  /// Destructive may use heavy only when intensity itself is in the heavy band.
  HapticBand _resolve(HapticIntent intent, HapticBand intensityBand) {
    final preferred = switch (intent) {
      HapticIntent.selection || HapticIntent.sliderTick => HapticBand.selection,
      HapticIntent.toggle => HapticBand.light,
      HapticIntent.sheetOpen ||
      HapticIntent.sheetClose ||
      HapticIntent.longPress ||
      HapticIntent.create => HapticBand.medium,
      HapticIntent.destructive => HapticBand.heavy,
    };

    return _minBand(preferred, intensityBand);
  }

  HapticBand _minBand(HapticBand a, HapticBand b) {
    return HapticBand.values[a.index < b.index ? a.index : b.index];
  }
}

void unawaitedHaptic(Future<void> future) {
  unawaited(future);
}

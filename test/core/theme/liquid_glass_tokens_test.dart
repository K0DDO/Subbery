import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subberry/core/haptics/haptic_manager.dart';
import 'package:subberry/core/theme/app_accent_theme.dart';
import 'package:subberry/core/theme/app_theme.dart';
import 'package:subberry/core/theme/glass_theme.dart';
import 'package:subberry/core/theme/liquid_glass_tokens.dart';

void main() {
  group('LiquidGlassTokens', () {
    LiquidGlassTokens tokensFor(double strength) {
      final theme = AppTheme.lightFor(AppAccentChoice.coral);
      final glass = theme.extension<GlassTheme>()!;
      final palette = theme.extension<SubberryTheme>()!;
      return LiquidGlassTokens.resolve(
        strength: strength,
        glass: glass,
        palette: palette,
        brightness: Brightness.light,
        strong: false,
      );
    }

    test('keeps current blur at strength 0', () {
      final theme = AppTheme.lightFor(AppAccentChoice.coral);
      final glass = theme.extension<GlassTheme>()!;
      final zero = tokensFor(0);
      expect(zero.blur, closeTo(glass.blur, 0.01));
      expect(zero.sheenEnabled, isFalse);
    });

    test('raises blur and enables sheen toward full liquid glass', () {
      final mid = tokensFor(0.5);
      final max = tokensFor(1);
      expect(mid.blur, greaterThan(tokensFor(0).blur));
      expect(max.blur, greaterThan(mid.blur));
      expect(max.blur, inInclusiveRange(36, 42));
      expect(max.sheenEnabled, isTrue);
      expect(max.fill.a, lessThan(tokensFor(0).fill.a));
    });
  });

  group('hapticBandForIntensity', () {
    test('maps intensity ranges to system bands', () {
      expect(hapticBandForIntensity(0), HapticBand.off);
      expect(hapticBandForIntensity(0.1), HapticBand.selection);
      expect(hapticBandForIntensity(0.33), HapticBand.selection);
      expect(hapticBandForIntensity(0.34), HapticBand.light);
      expect(hapticBandForIntensity(0.66), HapticBand.light);
      expect(hapticBandForIntensity(0.67), HapticBand.medium);
      expect(hapticBandForIntensity(0.85), HapticBand.medium);
      expect(hapticBandForIntensity(0.86), HapticBand.heavy);
      expect(hapticBandForIntensity(1), HapticBand.heavy);
    });
  });

  group('HapticManager', () {
    test('caps destructive intent by intensity band', () async {
      final backend = _RecordingBackend();
      final manager = HapticManager(backend: backend)
        ..configure(enabled: true, intensity: 0.5);
      await manager.destructive();
      expect(backend.last, 'light');

      manager.configure(enabled: true, intensity: 0.95);
      await manager.destructive();
      expect(backend.last, 'heavy');

      manager.configure(enabled: false, intensity: 1);
      backend.last = null;
      await manager.selection();
      expect(backend.last, isNull);
    });
  });
}

class _RecordingBackend implements HapticBackend {
  String? last;

  @override
  Future<void> selectionClick() async => last = 'selection';

  @override
  Future<void> lightImpact() async => last = 'light';

  @override
  Future<void> mediumImpact() async => last = 'medium';

  @override
  Future<void> heavyImpact() async => last = 'heavy';
}

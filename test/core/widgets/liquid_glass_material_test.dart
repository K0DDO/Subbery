import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:subberry/core/theme/app_theme.dart';
import 'package:subberry/core/widgets/glass_card.dart';
import 'package:subberry/core/widgets/liquid_glass_material.dart';
import 'package:subberry/core/widgets/liquid_glass_runtime_host.dart';
import 'package:subberry/features/settings/application/glass_effect_controller.dart';
import 'package:subberry/features/settings/application/haptic_settings_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('glass effect and haptic settings persist', () async {
    final glass = GlassEffectController();
    final haptics = HapticSettingsController();
    await Future<void>.delayed(Duration.zero);
    await glass.setStrength(0.7);
    await haptics.setEnabled(false);
    await haptics.setIntensity(0.9);
    glass.dispose();
    haptics.dispose();

    final glass2 = GlassEffectController();
    final haptics2 = HapticSettingsController();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(glass2.state, closeTo(0.7, 0.001));
    expect(haptics2.state.enabled, isFalse);
    expect(haptics2.state.intensity, closeTo(0.9, 0.001));
    glass2.dispose();
    haptics2.dispose();
  });

  testWidgets('GlassCard uses LiquidGlassMaterial in light and dark', (
    tester,
  ) async {
    for (final mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: mode,
            home: const LiquidGlassRuntimeHost(
              child: Scaffold(
                body: Center(child: GlassCard(child: Text('Карточка'))),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(LiquidGlassMaterial), findsOneWidget);
      expect(find.text('Карточка'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}

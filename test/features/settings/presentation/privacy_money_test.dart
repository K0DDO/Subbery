import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:subberry/core/theme/app_theme.dart';
import 'package:subberry/core/widgets/money_text.dart';
import 'package:subberry/features/settings/application/privacy_settings_controller.dart';
import 'package:subberry/features/settings/presentation/widgets/privacy_controls.dart';
import 'package:subberry/features/settings/presentation/widgets/privacy_quick_sheet.dart';
import 'package:subberry/widgets/morphing_sheet/morphing_glass_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('shows kopecks when enabled', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: MoneyText(cents: 428050, style: TextStyle(fontSize: 20)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('4'), findsWidgets);

    await container.read(privacySettingsProvider.notifier).setShowKopecks(true);
    await tester.pumpAndSettle();
    expect(find.textContaining(',50'), findsOneWidget);
  });

  testWidgets('hides numbers behind a spoiler until tapped', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(privacySettingsProvider.notifier).setHideNumbers(true);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: Center(
              child: MoneyText(cents: 150000, style: TextStyle(fontSize: 24)),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(TelegramSpoilerMask), findsOneWidget);

    await tester.tap(find.byType(MoneyText));
    await tester.pumpAndSettle();
    expect(find.textContaining('1'), findsWidgets);
  });

  testWidgets('frosted balance renders when transparent mode is on', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container
        .read(privacySettingsProvider.notifier)
        .setTransparentBalance(true);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: MoneyText(
              cents: 99900,
              frost: true,
              style: TextStyle(fontSize: 32),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FrostedBalanceText), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(FrostedBalanceText),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
  });

  testWidgets('transparency slider changes glass-effect strength', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: PrivacyControls()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch).at(1));
    await tester.pumpAndSettle();
    expect(find.byType(Slider), findsOneWidget);
    final before = container.read(privacySettingsProvider).transparencyStrength;
    await tester.drag(find.byType(Slider), const Offset(-100, 0));
    await tester.pumpAndSettle();
    expect(
      container.read(privacySettingsProvider).transparencyStrength,
      lessThan(before),
    );
  });

  for (final mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
    testWidgets('privacy quick sheet opens in ${mode.name}', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(400, 900);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: mode,
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () {
                      showPrivacyQuickSheet(
                        context: context,
                        startRect: const Rect.fromLTWH(40, 120, 320, 160),
                        plannedCents: 428000,
                      );
                    },
                    child: const Text('Открыть приватность'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Открыть приватность'));
      await tester.pumpAndSettle();
      expect(find.byKey(MorphingGlassSheetKeys.surface), findsOneWidget);
      expect(find.byType(PrivacyControls), findsOneWidget);
      expect(find.text('Прозрачный баланс'), findsOneWidget);
      expect(find.text('Скрывать числа'), findsOneWidget);
      expect(find.text('Показывать копейки'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

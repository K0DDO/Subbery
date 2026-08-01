import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subberry/core/theme/app_theme.dart';
import 'package:subberry/widgets/morphing_sheet/morphing_glass_sheet.dart';
import 'package:subberry/widgets/morphing_sheet/sheet_animation.dart';

void main() {
  test('adaptive duration respects configured limits', () {
    const settings = MorphingSheetAnimationSettings();
    const start = Rect.fromLTWH(16, 700, 360, 72);

    expect(
      settings.durationFor(start, const Rect.fromLTWH(16, 650, 360, 120)),
      const Duration(milliseconds: 350),
    );
    expect(
      settings.durationFor(start, const Rect.fromLTWH(0, -700, 900, 1400)),
      const Duration(milliseconds: 900),
    );
  });

  testWidgets('measures small and large content without empty space', (
    tester,
  ) async {
    await tester.pumpWidget(
      const _Harness(themeMode: ThemeMode.light, contentHeight: 220),
    );
    await _open(tester);

    expect(
      tester.getSize(find.byKey(MorphingGlassSheetKeys.surface)).height,
      closeTo(220, 0.1),
    );

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.byKey(MorphingGlassSheetKeys.surface), findsNothing);

    await tester.pumpWidget(
      const _Harness(themeMode: ThemeMode.light, contentHeight: 900),
    );
    await _open(tester);

    expect(
      tester.getSize(find.byKey(MorphingGlassSheetKeys.surface)).height,
      closeTo(420, 0.1),
    );
  });

  testWidgets('tap outside dismisses the sheet', (tester) async {
    await tester.pumpWidget(
      const _Harness(themeMode: ThemeMode.light, contentHeight: 240),
    );
    await _open(tester);

    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();

    expect(find.byKey(MorphingGlassSheetKeys.surface), findsNothing);
  });

  testWidgets('drag threshold restores or dismisses the sheet', (tester) async {
    await tester.pumpWidget(
      const _Harness(themeMode: ThemeMode.light, contentHeight: 240),
    );
    await _open(tester);
    final handle = find.byKey(
      const ValueKey<String>('morphing-sheet-drag-handle'),
    );

    await tester.drag(handle, const Offset(0, 40));
    await tester.pumpAndSettle();
    expect(find.byKey(MorphingGlassSheetKeys.surface), findsOneWidget);

    await tester.drag(handle, const Offset(0, 70));
    await tester.pumpAndSettle();
    expect(find.byKey(MorphingGlassSheetKeys.surface), findsNothing);
  });

  testWidgets('scroll consumes gestures before top-edge dismissal', (
    tester,
  ) async {
    await tester.pumpWidget(
      const _Harness(
        themeMode: ThemeMode.light,
        contentHeight: 900,
        scrollable: true,
      ),
    );
    await _open(tester);
    final content = find.byKey(MorphingGlassSheetKeys.content);

    await tester.drag(content, const Offset(0, -180));
    await tester.pumpAndSettle();
    expect(find.byKey(MorphingGlassSheetKeys.surface), findsOneWidget);

    await tester.drag(content, const Offset(0, 80));
    await tester.pumpAndSettle();
    expect(find.byKey(MorphingGlassSheetKeys.surface), findsOneWidget);

    await tester.drag(content, const Offset(0, 900));
    await tester.pumpAndSettle();
    expect(find.byKey(MorphingGlassSheetKeys.surface), findsNothing);
  });

  for (final mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
    testWidgets('renders liquid glass in ${mode.name} theme', (tester) async {
      await tester.pumpWidget(_Harness(themeMode: mode, contentHeight: 240));
      await _open(tester);

      expect(find.byKey(MorphingGlassSheetKeys.surface), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('Открыть'));
  await tester.pump();
  await tester.pumpAndSettle();
}

class _Harness extends StatelessWidget {
  const _Harness({
    required this.themeMode,
    required this.contentHeight,
    this.scrollable = false,
  });

  final ThemeMode themeMode;
  final double contentHeight;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () {
                final size = MediaQuery.sizeOf(context);
                MorphingGlassSheet.show<void>(
                  context: context,
                  startRect: Rect.fromLTWH(
                    16,
                    size.height - 88,
                    size.width - 32,
                    72,
                  ),
                  maximumHeight: 420,
                  source: const Center(child: Text('HOTBAR')),
                  builder: (_) => SizedBox(
                    height: contentHeight,
                    child: scrollable
                        ? ListView.builder(
                            shrinkWrap: true,
                            itemCount: 30,
                            itemBuilder: (_, index) =>
                                ListTile(title: Text('Строка $index')),
                          )
                        : const Center(child: Text('Содержимое окна')),
                  ),
                );
              },
              child: const Text('Открыть'),
            ),
          ),
        ),
      ),
    );
  }
}

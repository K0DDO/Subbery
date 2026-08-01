import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subberry/core/theme/app_theme.dart';
import 'package:subberry/widgets/morphing_sheet/morphing_glass_sheet.dart';
import 'package:subberry/widgets/morphing_sheet/sheet_animation.dart';
import 'package:subberry/widgets/morphing_sheet/sheet_page_navigator.dart';

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

  testWidgets('double tap outside does not black-screen the host route', (
    tester,
  ) async {
    await tester.pumpWidget(
      const _Harness(themeMode: ThemeMode.light, contentHeight: 240),
    );
    await _open(tester);

    await tester.tapAt(const Offset(8, 8));
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();

    expect(find.byKey(MorphingGlassSheetKeys.surface), findsNothing);
    expect(find.text('Открыть'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('drag threshold restores or dismisses the sheet', (tester) async {
    await tester.pumpWidget(
      const _Harness(themeMode: ThemeMode.light, contentHeight: 240),
    );
    await _open(tester);
    final handle = find.byKey(
      const ValueKey<String>('morphing-sheet-drag-handle'),
    );

    await tester.drag(handle, const Offset(0, 25));
    await tester.pumpAndSettle();
    expect(find.byKey(MorphingGlassSheetKeys.surface), findsOneWidget);

    await tester.drag(handle, const Offset(0, 120));
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

  testWidgets('keeps content visible while sheet is mostly open during close', (
    tester,
  ) async {
    await tester.pumpWidget(
      const _Harness(themeMode: ThemeMode.light, contentHeight: 240),
    );
    await _open(tester);

    final handle = find.byKey(
      const ValueKey<String>('morphing-sheet-drag-handle'),
    );
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await gesture.moveBy(const Offset(0, 40));
    await tester.pump();

    final opacity = tester.widget<Opacity>(
      find
          .descendant(
            of: find.byKey(MorphingGlassSheetKeys.surface),
            matching: find.byType(Opacity),
          )
          .last,
    );
    expect(opacity.opacity, greaterThan(0.95));
    expect(find.text('Содержимое окна'), findsOneWidget);

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('handle and content drags keep content opacity aligned', (
    tester,
  ) async {
    Future<double> opacityAfterDrag(Finder target) async {
      await tester.pumpWidget(
        const _Harness(themeMode: ThemeMode.light, contentHeight: 240),
      );
      await _open(tester);
      final gesture = await tester.startGesture(tester.getCenter(target));
      await gesture.moveBy(const Offset(0, 70));
      await tester.pump();
      final opacity = tester.widget<Opacity>(
        find
            .descendant(
              of: find.byKey(MorphingGlassSheetKeys.surface),
              matching: find.byType(Opacity),
            )
            .last,
      );
      await gesture.up();
      await tester.pumpAndSettle();
      return opacity.opacity;
    }

    final handleOpacity = await opacityAfterDrag(
      find.byKey(const ValueKey<String>('morphing-sheet-drag-handle')),
    );
    final contentOpacity = await opacityAfterDrag(
      find.byKey(MorphingGlassSheetKeys.content),
    );

    expect(handleOpacity, greaterThan(0.95));
    expect(contentOpacity, closeTo(handleOpacity, 0.05));
  });

  testWidgets('fast content swipe dismisses the sheet', (tester) async {
    await tester.pumpWidget(
      const _Harness(themeMode: ThemeMode.light, contentHeight: 240),
    );
    await _open(tester);

    await tester.fling(
      find.byKey(MorphingGlassSheetKeys.content),
      const Offset(0, 400),
      1800,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(MorphingGlassSheetKeys.surface), findsNothing);
  });

  testWidgets('pins scroll offset while content dismisses from the top', (
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
    final gesture = await tester.startGesture(tester.getCenter(content));
    await gesture.moveBy(const Offset(0, 40));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 60));
    await tester.pump();

    final scrollable = tester.state<ScrollableState>(
      find.descendant(of: content, matching: find.byType(Scrollable)).first,
    );
    expect(scrollable.position.pixels, 0);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byKey(MorphingGlassSheetKeys.surface), findsOneWidget);
  });

  testWidgets('supports internal page navigation with back', (tester) async {
    await tester.pumpWidget(const _NavigatorHarness());
    await tester.tap(find.text('Открыть'));
    await tester.pumpAndSettle();

    final surface = find.byKey(MorphingGlassSheetKeys.surface);
    expect(tester.getSize(surface).height, closeTo(320, 0.5));
    expect(
      find.descendant(of: surface, matching: find.text('Динамика')),
      findsOneWidget,
    );
    await tester.tap(
      find.descendant(of: surface, matching: find.text('Открыть месяц')),
    );
    await tester.pump(const Duration(milliseconds: 160));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 160));

    final resizingHeight = tester.getSize(surface).height;
    expect(resizingHeight, greaterThan(180));
    expect(resizingHeight, lessThan(320));
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: surface, matching: find.text('Август')),
      findsOneWidget,
    );
    expect(tester.getSize(surface).height, closeTo(180, 0.5));
    expect(
      find.descendant(
        of: surface,
        matching: find.byKey(const ValueKey<String>('morphing-sheet-back')),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.descendant(
        of: surface,
        matching: find.byKey(const ValueKey<String>('morphing-sheet-back')),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: surface, matching: find.text('Динамика')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: surface, matching: find.text('Август')),
      findsNothing,
    );
    expect(tester.getSize(surface).height, closeTo(320, 0.5));
    expect(surface, findsOneWidget);
  });
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

class _NavigatorHarness extends StatelessWidget {
  const _NavigatorHarness();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light,
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
                  endSize: Size(size.width - 32, 320),
                  builder: (_) => MorphingSheetNavigator(
                    home: Builder(
                      builder: (navContext) => SizedBox(
                        height: 320,
                        child: ListView(
                          shrinkWrap: true,
                          padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
                          children: <Widget>[
                            const Text('Динамика'),
                            TextButton(
                              onPressed: () {
                                MorphingSheetNavigator.of(navContext).push(
                                  const SizedBox(
                                    height: 180,
                                    child: Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        16,
                                        56,
                                        16,
                                        16,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          MorphingSheetBackButton(),
                                          Text('Август'),
                                        ],
                                      ),
                                    ),
                                  ),
                                  title: 'По месяцам',
                                );
                              },
                              child: const Text('Открыть месяц'),
                            ),
                          ],
                        ),
                      ),
                    ),
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

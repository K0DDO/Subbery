import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subberry/core/theme/app_theme.dart';
import 'package:subberry/features/subscriptions/domain/entities/subscription.dart';
import 'package:subberry/features/subscriptions/presentation/subscriptions_screen.dart';
import 'package:subberry/widgets/morphing_sheet/morphing_glass_sheet.dart';

void main() {
  testWidgets('selects multiple categories and status filters', (tester) async {
    await tester.pumpWidget(const _FilterHarness());

    await tester.tap(find.text('Открыть фильтры'));
    await tester.pumpAndSettle();

    expect(find.byKey(MorphingGlassSheetKeys.surface), findsOneWidget);
    expect(find.text('Единовременная'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('subscription-filter-category-music')),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('subscription-filter-category-work')),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('subscription-filter-status-active')),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('subscription-filter-status-one-time')),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('subscription-filter-done')),
    );
    await tester.pumpAndSettle();

    expect(find.text('categories=2 statuses=1 oneTime=true'), findsOneWidget);
    expect(find.byKey(MorphingGlassSheetKeys.surface), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reset clears all advanced filters', (tester) async {
    await tester.pumpWidget(
      const _FilterHarness(
        initial: SubscriptionFilterState(
          categories: <SubscriptionCategory>{SubscriptionCategory.music},
          statuses: <SubscriptionStatus>{SubscriptionStatus.paused},
          oneTime: true,
        ),
      ),
    );

    await tester.tap(find.text('Открыть фильтры'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('subscription-filter-reset')),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('subscription-filter-done')),
    );
    await tester.pumpAndSettle();

    expect(find.text('categories=0 statuses=0 oneTime=false'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tap outside dismisses filter sheet in light theme', (
    tester,
  ) async {
    await tester.pumpWidget(const _FilterHarness());

    await tester.tap(find.text('Открыть фильтры'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();

    expect(find.byKey(MorphingGlassSheetKeys.surface), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('swipe dismisses filter sheet in dark theme', (tester) async {
    await tester.pumpWidget(const _FilterHarness(themeMode: ThemeMode.dark));

    await tester.tap(find.text('Открыть фильтры'));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(MorphingGlassSheetKeys.surface),
      const Offset(0, 420),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(MorphingGlassSheetKeys.surface), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _FilterHarness extends StatefulWidget {
  const _FilterHarness({
    this.initial = const SubscriptionFilterState(),
    this.themeMode = ThemeMode.light,
  });

  final SubscriptionFilterState initial;
  final ThemeMode themeMode;

  @override
  State<_FilterHarness> createState() => _FilterHarnessState();
}

class _FilterHarnessState extends State<_FilterHarness> {
  SubscriptionFilterState? _result;

  Future<void> _open(BuildContext context, GlobalKey buttonKey) async {
    final renderBox =
        buttonKey.currentContext!.findRenderObject()! as RenderBox;
    final result = await showSubscriptionFilterSheet(
      context: context,
      startRect: renderBox.localToGlobal(Offset.zero) & renderBox.size,
      initial: widget.initial,
    );
    if (result != null && mounted) setState(() => _result = result);
  }

  @override
  Widget build(BuildContext context) {
    final buttonKey = GlobalKey();
    return MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: widget.themeMode,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                FilledButton(
                  key: buttonKey,
                  onPressed: () => _open(context, buttonKey),
                  child: const Text('Открыть фильтры'),
                ),
                if (_result case final result?)
                  Text(
                    'categories=${result.categories.length} '
                    'statuses=${result.statuses.length} '
                    'oneTime=${result.oneTime}',
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

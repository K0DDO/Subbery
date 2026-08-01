import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subberry/core/theme/app_theme.dart';
import 'package:subberry/features/subscriptions/domain/entities/subscription.dart';
import 'package:subberry/features/subscriptions/presentation/subscription_ui_extensions.dart';
import 'package:subberry/features/subscriptions/presentation/widgets/category_picker_sheet.dart';
import 'package:subberry/widgets/morphing_sheet/morphing_glass_sheet.dart';

void main() {
  testWidgets('offers every existing category exactly once', (tester) async {
    await tester.pumpWidget(
      _CategoryHarness(
        child: CategoryPickerSheet(
          selected: SubscriptionCategory.other,
          onSelected: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final category in SubscriptionCategory.values) {
      expect(
        find.byKey(ValueKey<String>('category-picker-${category.name}')),
        findsOneWidget,
      );
      expect(find.text(category.label), findsOneWidget);
    }
    expect(
      find.byKey(const ValueKey<String>('category-picker-grid')),
      findsOneWidget,
    );
  });

  for (final mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
    testWidgets('picks a category through the morph sheet in ${mode.name}', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(400, 900);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_CategorySheetHarness(themeMode: mode));

      await tester.tap(find.text('Открыть категории'));
      await tester.pumpAndSettle();
      expect(find.byKey(MorphingGlassSheetKeys.surface), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('category-picker-music')),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(MorphingGlassSheetKeys.surface), findsNothing);
      expect(find.text('Выбрано: Музыка'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

class _CategoryHarness extends StatelessWidget {
  const _CategoryHarness({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: SizedBox(width: 390, child: child)),
    );
  }
}

class _CategorySheetHarness extends StatefulWidget {
  const _CategorySheetHarness({required this.themeMode});

  final ThemeMode themeMode;

  @override
  State<_CategorySheetHarness> createState() => _CategorySheetHarnessState();
}

class _CategorySheetHarnessState extends State<_CategorySheetHarness> {
  SubscriptionCategory? _selected;

  @override
  Widget build(BuildContext context) {
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
                  onPressed: () async {
                    final category = await showCategoryPickerSheet(
                      context: context,
                      selected: SubscriptionCategory.other,
                    );
                    if (category != null && mounted) {
                      setState(() => _selected = category);
                    }
                  },
                  child: const Text('Открыть категории'),
                ),
                if (_selected case final selected?)
                  Text('Выбрано: ${selected.label}'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

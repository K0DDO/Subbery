import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subberry/core/theme/app_theme.dart';
import 'package:subberry/features/subscriptions/data/catalog/known_services.dart';
import 'package:subberry/features/subscriptions/domain/entities/subscription.dart';
import 'package:subberry/features/subscriptions/presentation/widgets/service_picker_sheet.dart';
import 'package:subberry/widgets/morphing_sheet/morphing_glass_sheet.dart';

void main() {
  test('filters existing services by search and category', () {
    final search = filterKnownServices(query: 'spotify');
    final music = filterKnownServices(
      query: '',
      category: SubscriptionCategory.music,
    );

    expect(search.map((service) => service.logoKey), contains('spotify'));
    expect(search, hasLength(1));
    expect(
      music.every((service) => service.category == SubscriptionCategory.music),
      isTrue,
    );
    expect(music, isNotEmpty);
  });

  testWidgets('renders services as equal three-column app cells', (
    tester,
  ) async {
    await tester.pumpWidget(
      _PickerHarness(
        child: ServicePickerSheet(
          initialQuery: '',
          onQueryChanged: (_) {},
          onSelected: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final first = find.byKey(
      ValueKey<String>('service-app-${KnownServices.all[0].logoKey}'),
    );
    final second = find.byKey(
      ValueKey<String>('service-app-${KnownServices.all[1].logoKey}'),
    );
    final third = find.byKey(
      ValueKey<String>('service-app-${KnownServices.all[2].logoKey}'),
    );

    expect(first, findsOneWidget);
    expect(second, findsOneWidget);
    expect(third, findsOneWidget);
    expect(tester.getTopLeft(first).dy, tester.getTopLeft(second).dy);
    expect(tester.getTopLeft(second).dy, tester.getTopLeft(third).dy);
    expect(tester.getSize(first).height, closeTo(108, 0.1));
    expect(tester.getSize(second).height, closeTo(108, 0.1));
    expect(tester.getSize(third).height, closeTo(108, 0.1));
    expect(tester.getTopLeft(first).dx, lessThan(tester.getTopLeft(second).dx));
    expect(tester.getTopLeft(second).dx, lessThan(tester.getTopLeft(third).dx));
  });

  testWidgets('searches, filters categories, and selects a service', (
    tester,
  ) async {
    KnownService? selected;
    var query = '';
    await tester.pumpWidget(
      _PickerHarness(
        child: ServicePickerSheet(
          initialQuery: '',
          onQueryChanged: (value) => query = value,
          onSelected: (service) => selected = service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey<String>('service-picker-search')),
      'Spotify',
    );
    await tester.pumpAndSettle();
    expect(query, 'Spotify');
    expect(
      find.byKey(const ValueKey<String>('service-app-spotify')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey<String>('service-picker-search')),
      '',
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('service-category-music')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('service-app-spotify')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('service-app-netflix')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey<String>('service-app-spotify')));
    expect(selected?.logoKey, 'spotify');
  });

  for (final mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
    testWidgets('opens and returns from morph sheet in ${mode.name} mode', (
      tester,
    ) async {
      await tester.pumpWidget(_SheetHarness(themeMode: mode));

      await tester.tap(find.text('Открыть сервисы'));
      await tester.pumpAndSettle();
      expect(find.byKey(MorphingGlassSheetKeys.surface), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('service-picker-grid')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('service-picker-close')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(MorphingGlassSheetKeys.surface), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}

class _PickerHarness extends StatelessWidget {
  const _PickerHarness({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: SizedBox(width: 390, child: child)),
    );
  }
}

class _SheetHarness extends StatelessWidget {
  const _SheetHarness({required this.themeMode});

  final ThemeMode themeMode;

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
                showServicePickerSheet(
                  context: context,
                  initialQuery: '',
                  onQueryChanged: (_) {},
                );
              },
              child: const Text('Открыть сервисы'),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:subberry/core/theme/app_theme.dart';
import 'package:subberry/features/subscriptions/application/subscription_providers.dart';
import 'package:subberry/features/subscriptions/data/local/app_database.dart';
import 'package:subberry/features/subscriptions/domain/entities/subscription.dart';
import 'package:subberry/features/subscriptions/presentation/add_subscription_screen.dart';
import 'package:subberry/features/subscriptions/presentation/subscription_ui_extensions.dart';
import 'package:subberry/widgets/morphing_sheet/morphing_glass_sheet.dart';

final _categoryField = find.byKey(
  const ValueKey<String>('add-subscription-category'),
);

void main() {
  late AppDatabase database;

  setUpAll(() => initializeDateFormatting('ru'));
  setUp(() => database = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() async => database.close());

  testWidgets('replaces the category chips with a single category field', (
    tester,
  ) async {
    await _useTallScreen(tester);
    await tester.pumpWidget(_addScreen(database));
    await tester.pumpAndSettle();

    await _revealCategoryField(tester);

    expect(_categoryField, findsOneWidget);
    expect(find.text('Выберите категорию'), findsOneWidget);
    expect(
      find.descendant(
        of: _categoryField,
        matching: find.text(SubscriptionCategory.other.label),
      ),
      findsOneWidget,
    );
    for (final category in SubscriptionCategory.values) {
      expect(find.text('${category.emoji} ${category.label}'), findsNothing);
    }
  });

  testWidgets('picks a category through the morph sheet', (tester) async {
    await _useTallScreen(tester);
    await tester.pumpWidget(_addScreen(database));
    await tester.pumpAndSettle();

    await _revealCategoryField(tester);
    await tester.tap(_categoryField);
    await tester.pumpAndSettle();

    expect(find.byKey(MorphingGlassSheetKeys.surface), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('category-picker-gaming')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(MorphingGlassSheetKeys.surface), findsNothing);
    await _revealCategoryField(tester);
    expect(
      find.descendant(
        of: _categoryField,
        matching: find.text(SubscriptionCategory.gaming.label),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the service picker flow filling name and category', (
    tester,
  ) async {
    await _useTallScreen(tester);
    await tester.pumpWidget(_addScreen(database));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextField, 'Сервис'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('service-picker-grid')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey<String>('service-app-netflix')));
    await tester.pumpAndSettle();

    expect(find.byKey(MorphingGlassSheetKeys.surface), findsNothing);
    expect(find.text('Netflix'), findsWidgets);
    expect(
      find.text(
        '${SubscriptionCategory.entertainment.emoji} '
        '${SubscriptionCategory.entertainment.label}',
      ),
      findsOneWidget,
    );

    await _revealCategoryField(tester);
    expect(
      find.descendant(
        of: _categoryField,
        matching: find.text(SubscriptionCategory.entertainment.label),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _revealCategoryField(WidgetTester tester) async {
  await tester.dragUntilVisible(
    _categoryField,
    find.byType(ListView),
    const Offset(0, -160),
  );
  await tester.pumpAndSettle();
}

Future<void> _useTallScreen(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(400, 900);
  addTearDown(tester.view.reset);
}

Widget _addScreen(AppDatabase database) {
  return ProviderScope(
    overrides: <Override>[databaseProvider.overrideWithValue(database)],
    child: MaterialApp(
      theme: AppTheme.light,
      home: const AddSubscriptionScreen(),
    ),
  );
}

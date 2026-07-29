import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subberry/app/app.dart';
import 'package:subberry/features/subscriptions/application/subscription_providers.dart';
import 'package:subberry/features/subscriptions/domain/entities/payment.dart';
import 'package:subberry/features/subscriptions/domain/entities/subscription.dart';

void main() {
  testWidgets('renders overview empty state', (tester) async {
    await tester.pumpWidget(_emptyApp());
    await tester.pumpAndSettle();

    expect(find.text('Привет, Дима 👋'), findsOneWidget);
    expect(find.text('Пока нет подписок 🍓'), findsOneWidget);
    expect(find.text('Добавить подписку'), findsOneWidget);
  });

  testWidgets('switches between navigation tabs', (tester) async {
    await tester.pumpWidget(_emptyApp());

    await tester.tap(find.text('Аналитика'));
    await tester.pumpAndSettle();

    expect(find.text('Здесь появится аналитика'), findsOneWidget);

    await tester.tap(find.text('Настройки'));
    await tester.pumpAndSettle();

    expect(find.text('Версия 1.0.0'), findsOneWidget);
  });
}

ProviderScope _emptyApp() {
  return ProviderScope(
    overrides: <Override>[
      subscriptionsProvider.overrideWith(
        (ref) => Stream<List<Subscription>>.value(const <Subscription>[]),
      ),
      allPaymentsProvider.overrideWith(
        (ref) => Stream<List<Payment>>.value(const <Payment>[]),
      ),
    ],
    child: const SubberryApp(),
  );
}

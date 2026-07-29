import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subberry/app/app.dart';
import 'package:subberry/features/profile/application/user_profile_controller.dart';
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
    await tester.pumpAndSettle();

    await tester.tap(find.text('Аналитика'));
    await tester.pumpAndSettle();

    expect(find.text('Здесь появится аналитика'), findsOneWidget);

    await tester.tap(find.text('Настройки'));
    await tester.pumpAndSettle();

    expect(find.text('Иконка приложения'), findsOneWidget);
  });

  testWidgets('asks for name on first launch', (tester) async {
    await tester.pumpWidget(_emptyApp(userName: null));
    await tester.pumpAndSettle();

    expect(find.text('Как вас зовут?'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), 'Анна');
    await tester.pump();
    await tester.tap(find.text('Продолжить'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Обзор'));
    await tester.pumpAndSettle();
    expect(find.text('Привет, Анна 👋'), findsOneWidget);
  });
}

ProviderScope _emptyApp({String? userName = 'Дима'}) {
  return ProviderScope(
    overrides: <Override>[
      userProfileGatewayProvider.overrideWithValue(
        _MemoryProfileGateway(userName),
      ),
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

class _MemoryProfileGateway implements UserProfileGateway {
  _MemoryProfileGateway(this.name);

  String? name;

  @override
  Future<String?> readName() async => name;

  @override
  Future<void> writeName(String name) async {
    this.name = name;
  }
}

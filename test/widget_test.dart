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

  testWidgets('shows admin date simulator only for dima4ka', (tester) async {
    final subscription = Subscription(
      id: 'netflix',
      name: 'Netflix',
      logo: 'netflix',
      category: SubscriptionCategory.entertainment,
      priceInCents: 79900,
      billingCycle: BillingCycle.monthly,
      startDate: DateTime(2026, 1, 1),
      nextPaymentDate: DateTime(2026, 8, 3),
      status: SubscriptionStatus.active,
      totalSpentInCents: 0,
      reminderEnabled: true,
    );

    await tester.pumpWidget(
      _emptyApp(
        userName: 'dima4ka',
        subscriptions: <Subscription>[subscription],
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Обзор'));
    await tester.pumpAndSettle();

    expect(find.byType(Slider), findsOneWidget);

    await tester.pumpWidget(
      _emptyApp(userName: 'Анна', subscriptions: <Subscription>[subscription]),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Обзор'));
    await tester.pumpAndSettle();

    expect(find.byType(Slider), findsNothing);
  });

  testWidgets('admin date simulator changes overview date', (tester) async {
    final subscription = Subscription(
      id: 'netflix',
      name: 'Netflix',
      logo: 'netflix',
      category: SubscriptionCategory.entertainment,
      priceInCents: 79900,
      billingCycle: BillingCycle.monthly,
      startDate: DateTime(2026, 1, 1),
      nextPaymentDate: DateTime(2026, 8, 3),
      status: SubscriptionStatus.active,
      totalSpentInCents: 0,
      reminderEnabled: true,
    );

    await tester.pumpWidget(
      _emptyApp(
        userName: 'DIMA4KA',
        subscriptions: <Subscription>[subscription],
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Обзор'));
    await tester.pumpAndSettle();

    final slider = find.byType(Slider);
    await tester.ensureVisible(slider);
    await tester.pumpAndSettle();

    final initialDate = tester.widget<Slider>(slider).value;
    expect(initialDate, 0);

    await tester.drag(slider, const Offset(180, 0));
    await tester.pumpAndSettle();

    final updatedSlider = tester.widget<Slider>(slider);
    expect(updatedSlider.value, greaterThan(0));
  });

  testWidgets('swipes from upcoming ring to yearly calendar', (tester) async {
    final subscription = Subscription(
      id: 'netflix',
      name: 'Netflix',
      logo: 'netflix',
      category: SubscriptionCategory.entertainment,
      priceInCents: 79900,
      billingCycle: BillingCycle.monthly,
      startDate: DateTime(2026, 1, 1),
      nextPaymentDate: DateTime(2026, 8, 3),
      status: SubscriptionStatus.active,
      totalSpentInCents: 0,
      reminderEnabled: true,
    );
    await tester.pumpWidget(
      _emptyApp(subscriptions: <Subscription>[subscription]),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Обзор'));
    await tester.pumpAndSettle();

    expect(find.text('Ближайшие платежи'), findsOneWidget);
    expect(find.text('Следующие списания'), findsNothing);
    final pageView = find.byType(PageView);
    final swipeStart = tester.getTopLeft(pageView) + const Offset(200, 48);
    await tester.flingFrom(swipeStart, const Offset(-620, 0), 1200);
    await tester.pumpAndSettle();

    expect(find.text('Календарь платежей'), findsOneWidget);
  });

  testWidgets('changes profile name without removing subscriptions', (
    tester,
  ) async {
    final subscription = _subscription('Netflix', BillingCycle.monthly);
    await tester.pumpWidget(
      _emptyApp(userName: 'Анна', subscriptions: <Subscription>[subscription]),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Настройки'));
    await tester.pumpAndSettle();
    expect(find.text('Анна'), findsOneWidget);

    await tester.tap(find.byTooltip('Изменить имя'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Мария');
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
    expect(find.text('Мария'), findsOneWidget);

    await tester.tap(find.text('Подписки'));
    await tester.pumpAndSettle();
    expect(find.text('Netflix'), findsOneWidget);

    await tester.tap(find.text('Обзор'));
    await tester.pumpAndSettle();
  });

  testWidgets('resets subscription filters after switching tabs', (
    tester,
  ) async {
    final subscriptions = <Subscription>[
      _subscription('Monthly', BillingCycle.monthly),
      _subscription('Annual', BillingCycle.yearly),
    ];
    await tester.pumpWidget(_emptyApp(subscriptions: subscriptions));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Подписки'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Годовые'));
    await tester.pumpAndSettle();
    expect(find.text('Monthly'), findsNothing);
    expect(find.text('Annual'), findsOneWidget);

    await tester.tap(find.text('Обзор'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Подписки'));
    await tester.pumpAndSettle();
    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text('Annual'), findsOneWidget);
  });
}

Subscription _subscription(String name, BillingCycle billingCycle) {
  return Subscription(
    id: name.toLowerCase(),
    name: name,
    category: SubscriptionCategory.other,
    priceInCents: 10000,
    billingCycle: billingCycle,
    startDate: DateTime(2026, 1, 1),
    nextPaymentDate: DateTime(2026, 8, 10),
    status: SubscriptionStatus.active,
    totalSpentInCents: 0,
    reminderEnabled: true,
  );
}

ProviderScope _emptyApp({
  String? userName = 'Дима',
  List<Subscription> subscriptions = const <Subscription>[],
}) {
  return ProviderScope(
    overrides: <Override>[
      userProfileGatewayProvider.overrideWithValue(
        _MemoryProfileGateway(userName),
      ),
      subscriptionsProvider.overrideWith(
        (ref) => Stream<List<Subscription>>.value(subscriptions),
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

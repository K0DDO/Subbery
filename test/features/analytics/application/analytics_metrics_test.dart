import 'package:flutter_test/flutter_test.dart';
import 'package:subberry/features/analytics/application/analytics_metrics.dart';
import 'package:subberry/features/subscriptions/domain/entities/payment.dart';
import 'package:subberry/features/subscriptions/domain/entities/subscription.dart';

void main() {
  test('calculates spending cards and category totals', () {
    final netflix = _subscription(
      id: 'netflix',
      category: SubscriptionCategory.entertainment,
      priceInCents: 79900,
      startDate: DateTime(2025, 5, 1),
    );
    final spotify = _subscription(
      id: 'spotify',
      category: SubscriptionCategory.music,
      priceInCents: 16900,
      startDate: DateTime(2026, 1, 1),
    );
    final payments = <Payment>[
      Payment(
        id: 'july',
        subscriptionId: netflix.id,
        amountInCents: 79900,
        date: DateTime(2026, 7, 3),
      ),
      Payment(
        id: 'january',
        subscriptionId: spotify.id,
        amountInCents: 16900,
        date: DateTime(2026, 1, 10),
      ),
    ];

    final metrics = AnalyticsMetrics.calculate(
      subscriptions: <Subscription>[netflix, spotify],
      payments: payments,
      now: DateTime(2026, 7, 29),
    );

    expect(metrics.thisMonthInCents, 79900);
    expect(metrics.thisYearInCents, 96800);
    expect(metrics.totalSpentInCents, 96800);
    expect(
      metrics.categorySpending.first.category,
      SubscriptionCategory.entertainment,
    );
    expect(metrics.monthlySpending, hasLength(6));
  });

  test('creates local smart insights', () {
    final netflix = _subscription(
      id: 'netflix',
      category: SubscriptionCategory.entertainment,
      priceInCents: 79900,
      startDate: DateTime(2025, 5, 1),
    );

    final metrics = AnalyticsMetrics.calculate(
      subscriptions: <Subscription>[netflix],
      payments: const <Payment>[],
      now: DateTime(2026, 7, 29),
    );

    expect(metrics.insights.first.title, contains('14 месяцев'));
    expect(
      metrics.insights.any(
        (insight) => insight.title.contains('Всего потрачено'),
      ),
      isTrue,
    );
  });

  test('counts a manual plan only in its explicitly scheduled month', () {
    final manual =
        _subscription(
          id: 'manual',
          category: SubscriptionCategory.work,
          priceInCents: 50000,
          startDate: DateTime(2026, 1, 1),
        ).copyWith(
          renewalMode: RenewalMode.manual,
          nextPaymentDate: DateTime(2026, 8, 15),
        );

    final july = AnalyticsMetrics.calculate(
      subscriptions: <Subscription>[manual],
      payments: const <Payment>[],
      now: DateTime(2026, 7, 29),
    );
    final august = AnalyticsMetrics.calculate(
      subscriptions: <Subscription>[manual],
      payments: const <Payment>[],
      now: DateTime(2026, 8, 1),
    );

    expect(july.thisMonthInCents, 0);
    expect(july.categorySpending, isEmpty);
    expect(august.thisMonthInCents, 50000);
    expect(august.categorySpending.single.amountInCents, 50000);
  });
}

Subscription _subscription({
  required String id,
  required SubscriptionCategory category,
  required int priceInCents,
  required DateTime startDate,
}) {
  return Subscription(
    id: id,
    name: id == 'netflix' ? 'Netflix' : 'Spotify',
    category: category,
    priceInCents: priceInCents,
    billingCycle: BillingCycle.monthly,
    startDate: startDate,
    nextPaymentDate: DateTime(2026, 8, 3),
    status: SubscriptionStatus.active,
    totalSpentInCents: 0,
    reminderEnabled: true,
  );
}

import 'package:flutter_test/flutter_test.dart';
import 'package:subberry/features/overview/application/overview_metrics.dart';
import 'package:subberry/features/subscriptions/domain/entities/payment.dart';
import 'package:subberry/features/subscriptions/domain/entities/subscription.dart';

void main() {
  test('calculates normalized monthly spend and upcoming order', () {
    final monthly = _subscription(
      id: 'monthly',
      priceInCents: 79900,
      billingCycle: BillingCycle.monthly,
      nextPaymentDate: DateTime(2026, 8, 3),
    );
    final annual = _subscription(
      id: 'annual',
      priceInCents: 120000,
      billingCycle: BillingCycle.yearly,
      nextPaymentDate: DateTime(2026, 7, 30),
    );

    final metrics = OverviewMetrics.calculate(
      subscriptions: <Subscription>[monthly, annual],
      payments: <Payment>[
        Payment(
          id: 'payment',
          subscriptionId: monthly.id,
          amountInCents: 79900,
          date: DateTime(2026, 7, 3),
        ),
      ],
      now: DateTime(2026, 7, 29),
    );

    expect(metrics.plannedThisMonthInCents, 199900);
    expect(metrics.actualThisMonthInCents, 79900);
    expect(metrics.averageMonthlyPlannedInCents, 89900);
    expect(metrics.upcomingPayments.first.subscription.id, 'annual');
    expect(metrics.spendingByMonth.last.amountInCents, 79900);
    expect(metrics.upcomingYearOccurrences, hasLength(6));
    expect(
      metrics.upcomingYearOccurrences.every(
        (occurrence) => !occurrence.date.isBefore(DateTime(2026, 7, 29)),
      ),
      isTrue,
    );
  });

  test('creates monthly and yearly calendar occurrences', () {
    final monthly = _subscription(
      id: 'monthly',
      priceInCents: 79900,
      billingCycle: BillingCycle.monthly,
      nextPaymentDate: DateTime(2026, 8, 31),
    );
    final annual = _subscription(
      id: 'annual',
      priceInCents: 120000,
      billingCycle: BillingCycle.yearly,
      nextPaymentDate: DateTime(2026, 10, 2),
    );

    final occurrences = OverviewMetrics.buildYearOccurrences(<Subscription>[
      monthly,
      annual,
    ], 2026);

    expect(
      occurrences.where((item) => item.subscription.id == 'monthly'),
      hasLength(5),
    );
    expect(
      occurrences.firstWhere((item) => item.subscription.id == 'monthly').date,
      DateTime(2026, 8, 31),
    );
    expect(
      occurrences.where((item) => item.subscription.id == 'annual').single.date,
      DateTime(2026, 10, 2),
    );
  });
}

Subscription _subscription({
  required String id,
  required int priceInCents,
  required BillingCycle billingCycle,
  required DateTime nextPaymentDate,
}) {
  return Subscription(
    id: id,
    name: id,
    category: SubscriptionCategory.other,
    priceInCents: priceInCents,
    billingCycle: billingCycle,
    startDate: DateTime(2026),
    nextPaymentDate: nextPaymentDate,
    status: SubscriptionStatus.active,
    totalSpentInCents: 0,
    reminderEnabled: true,
  );
}

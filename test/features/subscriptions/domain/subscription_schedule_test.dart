import 'package:flutter_test/flutter_test.dart';
import 'package:subberry/features/subscriptions/domain/entities/subscription.dart';
import 'package:subberry/features/subscriptions/domain/subscription_schedule.dart';

void main() {
  test('advances a stale monthly payment to the next cycle', () {
    final subscription = _subscription(nextPaymentDate: DateTime(2026, 7, 29));

    expect(
      SubscriptionSchedule.normalizedNextPayment(
        subscription,
        DateTime(2026, 7, 30),
      ),
      DateTime(2026, 8, 29),
    );
  });

  test('preserves the billing anchor through short months', () {
    final subscription = _subscription(
      nextPaymentDate: DateTime(2026, 1, 31),
      billingAnchorDay: 31,
    );

    expect(
      SubscriptionSchedule.normalizedNextPayment(
        subscription,
        DateTime(2026, 3, 1),
      ),
      DateTime(2026, 3, 31),
    );
  });

  test('preserves leap-day yearly billing anchor', () {
    final subscription = _subscription(
      nextPaymentDate: DateTime(2024, 2, 29),
      billingCycle: BillingCycle.yearly,
      billingAnchorDay: 29,
    );

    expect(
      SubscriptionSchedule.normalizedNextPayment(
        subscription,
        DateTime(2027, 3, 1),
      ),
      DateTime(2028, 2, 29),
    );
  });

  test('builds a subscription-specific payment schedule', () {
    final subscription = _subscription(
      nextPaymentDate: DateTime(2026, 7, 31),
      billingAnchorDay: 31,
    );

    expect(
      SubscriptionSchedule.upcomingDates(
        subscription,
        DateTime(2026, 7, 30),
        count: 3,
      ),
      <DateTime>[
        DateTime(2026, 7, 31),
        DateTime(2026, 8, 31),
        DateTime(2026, 9, 30),
      ],
    );
  });

  test('keeps one explicit date for a manual subscription', () {
    final subscription = _subscription(
      nextPaymentDate: DateTime(2026, 7, 1),
      renewalMode: RenewalMode.manual,
    );

    expect(
      SubscriptionSchedule.normalizedNextPayment(
        subscription,
        DateTime(2026, 9, 1),
      ),
      DateTime(2026, 7, 1),
    );
    expect(
      SubscriptionSchedule.upcomingDates(
        subscription,
        DateTime(2026, 9, 1),
        count: 12,
      ),
      <DateTime>[DateTime(2026, 7, 1)],
    );
  });
}

Subscription _subscription({
  required DateTime nextPaymentDate,
  BillingCycle billingCycle = BillingCycle.monthly,
  RenewalMode renewalMode = RenewalMode.automatic,
  int? billingAnchorDay,
}) {
  return Subscription(
    id: 'test',
    name: 'Test',
    category: SubscriptionCategory.other,
    priceInCents: 10000,
    billingCycle: billingCycle,
    renewalMode: renewalMode,
    startDate: DateTime(2024),
    nextPaymentDate: nextPaymentDate,
    status: SubscriptionStatus.active,
    totalSpentInCents: 0,
    reminderEnabled: true,
    billingAnchorDay: billingAnchorDay,
  );
}

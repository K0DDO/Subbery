import 'package:flutter_test/flutter_test.dart';
import 'package:subberry/features/subscriptions/domain/entities/subscription.dart';
import 'package:subberry/features/subscriptions/presentation/subscriptions_screen.dart';

void main() {
  final today = DateTime(2026, 7, 29);
  final monthly = _subscription(
    id: 'monthly',
    billingCycle: BillingCycle.monthly,
    nextPaymentDate: DateTime(2026, 8, 3),
  );
  final annual = _subscription(
    id: 'annual',
    billingCycle: BillingCycle.yearly,
    nextPaymentDate: DateTime(2026, 10, 1),
  );
  final paused = _subscription(
    id: 'paused',
    billingCycle: BillingCycle.monthly,
    nextPaymentDate: DateTime(2026, 8, 5),
    status: SubscriptionStatus.paused,
  );

  test('filters upcoming active subscriptions within thirty days', () {
    final result = filterSubscriptions(
      <Subscription>[monthly, annual, paused],
      SubscriptionListFilter.upcoming,
      now: today,
    );

    expect(result, <Subscription>[monthly]);
  });

  test('filters yearly subscriptions regardless of payment date', () {
    final result = filterSubscriptions(
      <Subscription>[monthly, annual, paused],
      SubscriptionListFilter.yearly,
      now: today,
    );

    expect(result, <Subscription>[annual]);
  });

  test('combines category and list filters', () {
    final music = _subscription(
      id: 'music',
      billingCycle: BillingCycle.monthly,
      nextPaymentDate: DateTime(2026, 8, 4),
      category: SubscriptionCategory.music,
    );

    final result = filterSubscriptions(
      <Subscription>[monthly, music, annual],
      SubscriptionListFilter.upcoming,
      category: SubscriptionCategory.music,
      now: today,
    );

    expect(result, <Subscription>[music]);
  });
}

Subscription _subscription({
  required String id,
  required BillingCycle billingCycle,
  required DateTime nextPaymentDate,
  SubscriptionStatus status = SubscriptionStatus.active,
  SubscriptionCategory category = SubscriptionCategory.other,
}) {
  return Subscription(
    id: id,
    name: id,
    category: category,
    priceInCents: 10000,
    billingCycle: billingCycle,
    startDate: DateTime(2026),
    nextPaymentDate: nextPaymentDate,
    status: status,
    totalSpentInCents: 0,
    reminderEnabled: true,
  );
}

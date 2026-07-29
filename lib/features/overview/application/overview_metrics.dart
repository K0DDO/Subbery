import '../../../core/models/monthly_spend_point.dart';
import '../../subscriptions/domain/entities/payment.dart';
import '../../subscriptions/domain/entities/subscription.dart';

class PaymentOccurrence {
  const PaymentOccurrence({required this.subscription, required this.date});

  final Subscription subscription;
  final DateTime date;
}

class OverviewMetrics {
  const OverviewMetrics({
    required this.monthlyRecurringInCents,
    required this.averageMonthlyInCents,
    required this.upcomingPayments,
    required this.spendingByMonth,
    required this.yearOccurrences,
    required this.upcomingYearOccurrences,
  });

  factory OverviewMetrics.calculate({
    required List<Subscription> subscriptions,
    required List<Payment> payments,
    required DateTime now,
  }) {
    final activeSubscriptions = subscriptions
        .where((item) => item.status == SubscriptionStatus.active)
        .toList(growable: false);
    final monthlyRecurring = activeSubscriptions.fold<int>(
      0,
      (total, item) =>
          total +
          switch (item.billingCycle) {
            BillingCycle.monthly => item.priceInCents,
            BillingCycle.yearly => (item.priceInCents / 12).round(),
          },
    );

    final upcoming =
        activeSubscriptions
            .map(
              (subscription) => PaymentOccurrence(
                subscription: subscription,
                date: nextOccurrence(subscription, now),
              ),
            )
            .toList()
          ..sort((left, right) => left.date.compareTo(right.date));

    final spendingByMonth = _lastSixMonths(
      payments: payments,
      now: now,
      fallbackCurrentMonth: monthlyRecurring,
    );

    final yearOccurrences = buildYearOccurrences(activeSubscriptions, now.year);
    return OverviewMetrics(
      monthlyRecurringInCents: monthlyRecurring,
      averageMonthlyInCents: _averageMonthly(
        payments,
        now,
        fallback: monthlyRecurring,
      ),
      upcomingPayments: upcoming,
      spendingByMonth: spendingByMonth,
      yearOccurrences: yearOccurrences,
      upcomingYearOccurrences: yearOccurrences
          .where(
            (occurrence) =>
                !occurrence.date.isBefore(
                  DateTime(now.year, now.month, now.day),
                ) &&
                occurrence.date.year == now.year,
          )
          .toList(growable: false),
    );
  }

  final int monthlyRecurringInCents;
  final int averageMonthlyInCents;
  final List<PaymentOccurrence> upcomingPayments;
  final List<MonthlySpendPoint> spendingByMonth;
  final List<PaymentOccurrence> yearOccurrences;
  final List<PaymentOccurrence> upcomingYearOccurrences;

  static DateTime nextOccurrence(Subscription subscription, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    var candidate = DateTime(
      subscription.nextPaymentDate.year,
      subscription.nextPaymentDate.month,
      subscription.nextPaymentDate.day,
    );
    while (candidate.isBefore(today)) {
      candidate = switch (subscription.billingCycle) {
        BillingCycle.monthly => _addMonths(candidate, 1),
        BillingCycle.yearly => _safeDate(
          candidate.year + 1,
          candidate.month,
          candidate.day,
        ),
      };
    }
    return candidate;
  }

  static List<PaymentOccurrence> buildYearOccurrences(
    List<Subscription> subscriptions,
    int year,
  ) {
    final occurrences = <PaymentOccurrence>[];
    for (final subscription in subscriptions) {
      switch (subscription.billingCycle) {
        case BillingCycle.monthly:
          for (var month = 1; month <= 12; month++) {
            final date = _safeDate(
              year,
              month,
              subscription.nextPaymentDate.day,
            );
            if (!date.isBefore(subscription.startDate)) {
              occurrences.add(
                PaymentOccurrence(subscription: subscription, date: date),
              );
            }
          }
        case BillingCycle.yearly:
          final date = _safeDate(
            year,
            subscription.nextPaymentDate.month,
            subscription.nextPaymentDate.day,
          );
          if (!date.isBefore(subscription.startDate)) {
            occurrences.add(
              PaymentOccurrence(subscription: subscription, date: date),
            );
          }
      }
    }
    occurrences.sort((left, right) => left.date.compareTo(right.date));
    return occurrences;
  }

  static List<MonthlySpendPoint> _lastSixMonths({
    required List<Payment> payments,
    required DateTime now,
    required int fallbackCurrentMonth,
  }) {
    final currentMonth = DateTime(now.year, now.month);
    final points = <MonthlySpendPoint>[];
    for (var offset = 5; offset >= 0; offset--) {
      final month = _addMonths(currentMonth, -offset);
      final nextMonth = _addMonths(month, 1);
      final amount = payments
          .where(
            (payment) =>
                !payment.date.isBefore(month) &&
                payment.date.isBefore(nextMonth),
          )
          .fold<int>(0, (total, payment) => total + payment.amountInCents);
      points.add(
        MonthlySpendPoint(
          month: month,
          amountInCents: amount == 0 && offset == 0
              ? fallbackCurrentMonth
              : amount,
        ),
      );
    }
    return points;
  }

  static int _averageMonthly(
    List<Payment> payments,
    DateTime now, {
    required int fallback,
  }) {
    if (payments.isEmpty) return fallback;
    final twelveMonthsAgo = DateTime(now.year - 1, now.month + 1);
    final relevant = payments
        .where((payment) => !payment.date.isBefore(twelveMonthsAgo))
        .toList();
    if (relevant.isEmpty) return fallback;

    final earliest = relevant
        .map((payment) => DateTime(payment.date.year, payment.date.month))
        .reduce((left, right) => left.isBefore(right) ? left : right);
    final monthCount =
        (now.year - earliest.year) * 12 + now.month - earliest.month + 1;
    final total = relevant.fold<int>(
      0,
      (sum, payment) => sum + payment.amountInCents,
    );
    return (total / monthCount.clamp(1, 12)).round();
  }

  static DateTime _addMonths(DateTime source, int months) {
    final zeroBasedMonth = source.month - 1 + months;
    final year = source.year + (zeroBasedMonth / 12).floor();
    final month = zeroBasedMonth % 12 + 1;
    return _safeDate(year, month, source.day);
  }

  static DateTime _safeDate(int year, int month, int day) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, day.clamp(1, lastDay));
  }
}

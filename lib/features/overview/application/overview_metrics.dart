import '../../../core/models/monthly_spend_point.dart';
import '../../subscriptions/domain/entities/payment.dart';
import '../../subscriptions/domain/entities/subscription.dart';
import '../../subscriptions/domain/subscription_schedule.dart';

class PaymentOccurrence {
  const PaymentOccurrence({required this.subscription, required this.date});

  final Subscription subscription;
  final DateTime date;
}

class OverviewMetrics {
  const OverviewMetrics({
    required this.plannedThisMonthInCents,
    required this.actualThisMonthInCents,
    required this.averageMonthlyPlannedInCents,
    required this.dueThisMonthCount,
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
    final annualPlan = activeSubscriptions.fold<int>(
      0,
      (total, item) =>
          total +
          switch (item.renewalMode) {
            RenewalMode.manual => 0,
            RenewalMode.automatic => switch (item.billingCycle) {
              BillingCycle.monthly => item.priceInCents * 12,
              BillingCycle.yearly => item.priceInCents,
            },
          },
    );
    final currentMonth = DateTime(now.year, now.month);
    final nextMonth = _addMonths(currentMonth, 1);
    final plannedThisMonth = activeSubscriptions
        .where(
          (subscription) =>
              subscription.startDate.isBefore(nextMonth) &&
              ((subscription.renewalMode == RenewalMode.automatic &&
                      subscription.billingCycle == BillingCycle.monthly) ||
                  (subscription.nextPaymentDate.month == now.month &&
                      subscription.nextPaymentDate.year == now.year)),
        )
        .fold<int>(
          0,
          (total, subscription) => total + subscription.priceInCents,
        );
    final actualThisMonth = payments
        .where(
          (payment) =>
              !payment.date.isBefore(currentMonth) &&
              payment.date.isBefore(nextMonth),
        )
        .fold<int>(0, (total, payment) => total + payment.amountInCents);

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

    final spendingByMonth = _lastSixMonths(payments: payments, now: now);
    final dueThisMonthCount = upcoming
        .where(
          (occurrence) =>
              occurrence.date.year == now.year &&
              occurrence.date.month == now.month,
        )
        .map((occurrence) => occurrence.subscription.id)
        .toSet()
        .length;

    final yearOccurrences = buildYearOccurrences(activeSubscriptions, now.year);
    return OverviewMetrics(
      plannedThisMonthInCents: plannedThisMonth,
      actualThisMonthInCents: actualThisMonth,
      averageMonthlyPlannedInCents: (annualPlan / 12).round(),
      dueThisMonthCount: dueThisMonthCount,
      upcomingPayments: upcoming,
      spendingByMonth: spendingByMonth,
      yearOccurrences: yearOccurrences,
      upcomingYearOccurrences: upcoming
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

  final int plannedThisMonthInCents;
  final int actualThisMonthInCents;
  final int averageMonthlyPlannedInCents;
  final int dueThisMonthCount;
  final List<PaymentOccurrence> upcomingPayments;
  final List<MonthlySpendPoint> spendingByMonth;
  final List<PaymentOccurrence> yearOccurrences;
  final List<PaymentOccurrence> upcomingYearOccurrences;

  static DateTime nextOccurrence(Subscription subscription, DateTime now) {
    return SubscriptionSchedule.normalizedNextPayment(subscription, now);
  }

  static List<PaymentOccurrence> buildYearOccurrences(
    List<Subscription> subscriptions,
    int year,
  ) {
    final occurrences = <PaymentOccurrence>[];
    for (final subscription in subscriptions) {
      if (subscription.renewalMode == RenewalMode.manual) {
        final date = SubscriptionSchedule.dateOnly(
          subscription.nextPaymentDate,
        );
        if (date.year == year) {
          occurrences.add(
            PaymentOccurrence(subscription: subscription, date: date),
          );
        }
        continue;
      }
      final anchorDay =
          subscription.billingAnchorDay ?? subscription.nextPaymentDate.day;
      final startDate = SubscriptionSchedule.dateOnly(subscription.startDate);
      switch (subscription.billingCycle) {
        case BillingCycle.monthly:
          final firstMonth = startDate.year == year ? startDate.month : 1;
          if (startDate.year > year) continue;
          for (var month = firstMonth; month <= 12; month++) {
            final candidate = SubscriptionSchedule.safeDate(
              year,
              month,
              anchorDay,
            );
            if (candidate.isBefore(startDate)) continue;
            occurrences.add(
              PaymentOccurrence(subscription: subscription, date: candidate),
            );
          }
        case BillingCycle.yearly:
          final candidate = SubscriptionSchedule.safeDate(
            year,
            subscription.nextPaymentDate.month,
            anchorDay,
          );
          if (!candidate.isBefore(startDate)) {
            occurrences.add(
              PaymentOccurrence(subscription: subscription, date: candidate),
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
      points.add(MonthlySpendPoint(month: month, amountInCents: amount));
    }
    return points;
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

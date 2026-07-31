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
    final today = SubscriptionSchedule.dateOnly(now);
    final activeSubscriptions = subscriptions
        .where((item) => item.status == SubscriptionStatus.active)
        .toList(growable: false);
    final annualPlan = activeSubscriptions.fold<int>(
      0,
      (total, item) => total + item.annualPlanInCents,
    );
    final currentMonth = DateTime(now.year, now.month);
    final nextMonth = _addMonths(currentMonth, 1);
    final plannedThisMonth = activeSubscriptions
        .where((subscription) {
          if (!subscription.startDate.isBefore(nextMonth)) return false;
          final next = nextOccurrence(subscription, now);
          if (subscription.renewalMode == RenewalMode.manual &&
              next.isBefore(today)) {
            return false;
          }
          if (subscription.renewalMode == RenewalMode.automatic &&
              subscription.billingCycle == BillingCycle.monthly) {
            return true;
          }
          return next.month == now.month && next.year == now.year;
        })
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
            .where((occurrence) {
              if (occurrence.subscription.renewalMode == RenewalMode.manual &&
                  occurrence.date.isBefore(today)) {
                return false;
              }
              return true;
            })
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
                !occurrence.date.isBefore(today) &&
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
    final yearStart = DateTime(year);
    final yearEnd = DateTime(year + 1);
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
      if (startDate.year > year) continue;

      if (subscription.billingCycle == BillingCycle.monthly) {
        final firstMonth = startDate.year == year ? startDate.month : 1;
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
        continue;
      }

      var cursor = SubscriptionSchedule.dateOnly(subscription.nextPaymentDate);
      // Walk back until before the year (or start), then walk forward.
      var guard = 0;
      while (cursor.isAfter(yearStart) && guard < 200) {
        guard++;
        final previous = _stepBackward(
          cursor,
          subscription.billingCycle,
          anchorDay: anchorDay,
          customIntervalDays: subscription.customIntervalDays,
        );
        if (!previous.isBefore(cursor)) break;
        cursor = previous;
      }
      if (cursor.isBefore(startDate)) {
        cursor = SubscriptionSchedule.normalizedNextPayment(
          subscription,
          startDate,
        );
      }
      guard = 0;
      while (cursor.isBefore(yearEnd) && guard < 200) {
        guard++;
        if (!cursor.isBefore(startDate) && cursor.year == year) {
          occurrences.add(
            PaymentOccurrence(subscription: subscription, date: cursor),
          );
        }
        cursor = SubscriptionSchedule.nextAfter(
          cursor,
          subscription.billingCycle,
          anchorDay: anchorDay,
          customIntervalDays: subscription.customIntervalDays,
        );
      }
    }
    occurrences.sort((left, right) => left.date.compareTo(right.date));
    return occurrences;
  }

  static DateTime _stepBackward(
    DateTime date,
    BillingCycle billingCycle, {
    required int anchorDay,
    int? customIntervalDays,
  }) {
    return switch (billingCycle) {
      BillingCycle.monthly => _addMonthsSafe(date, -1, anchorDay),
      BillingCycle.quarterly => _addMonthsSafe(date, -3, anchorDay),
      BillingCycle.semiannual => _addMonthsSafe(date, -6, anchorDay),
      BillingCycle.yearly => _addMonthsSafe(date, -12, anchorDay),
      BillingCycle.biennial => _addMonthsSafe(date, -24, anchorDay),
      BillingCycle.custom => date.subtract(
        Duration(days: (customIntervalDays ?? 30).clamp(1, 3650)),
      ),
    };
  }

  static DateTime _addMonthsSafe(DateTime date, int months, int anchorDay) {
    final zeroBased = date.month - 1 + months;
    final year = date.year + (zeroBased / 12).floor();
    final month = ((zeroBased % 12) + 12) % 12 + 1;
    return SubscriptionSchedule.safeDate(year, month, anchorDay);
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
    var y = year;
    var m = month;
    while (m < 1) {
      m += 12;
      y -= 1;
    }
    while (m > 12) {
      m -= 12;
      y += 1;
    }
    final lastDay = DateTime(y, m + 1, 0).day;
    return DateTime(y, m, day.clamp(1, lastDay));
  }
}

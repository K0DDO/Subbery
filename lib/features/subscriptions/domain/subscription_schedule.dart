import 'entities/subscription.dart';

abstract final class SubscriptionSchedule {
  static DateTime dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static DateTime normalizedNextPayment(
    Subscription subscription,
    DateTime now,
  ) {
    final today = dateOnly(now);
    var candidate = dateOnly(subscription.nextPaymentDate);
    final anchorDay =
        subscription.billingAnchorDay ?? subscription.nextPaymentDate.day;

    while (candidate.isBefore(today)) {
      candidate = nextAfter(
        candidate,
        subscription.billingCycle,
        anchorDay: anchorDay,
      );
    }
    return candidate;
  }

  static DateTime nextAfter(
    DateTime date,
    BillingCycle billingCycle, {
    required int anchorDay,
  }) {
    return switch (billingCycle) {
      BillingCycle.monthly => _safeDate(
        date.month == 12 ? date.year + 1 : date.year,
        date.month == 12 ? 1 : date.month + 1,
        anchorDay,
      ),
      BillingCycle.yearly => _safeDate(date.year + 1, date.month, anchorDay),
    };
  }

  static DateTime safeDate(int year, int month, int day) {
    return _safeDate(year, month, day);
  }

  static DateTime _safeDate(int year, int month, int day) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, day.clamp(1, lastDay));
  }
}

import '../../../core/models/monthly_spend_point.dart';
import '../../subscriptions/domain/entities/payment.dart';
import '../../subscriptions/domain/entities/subscription.dart';
import '../../subscriptions/presentation/subscription_ui_extensions.dart';

enum AnalyticsPeriod { month, year, total }

class PaymentSpendRow {
  const PaymentSpendRow({
    required this.payment,
    required this.subscription,
  });

  final Payment payment;
  final Subscription? subscription;

  String get name => subscription?.name ?? 'Удалённая подписка';
  String? get logoKey => subscription?.logo;
  SubscriptionCategory get category =>
      subscription?.category ?? SubscriptionCategory.other;
}

class CategorySubscriptionRow {
  const CategorySubscriptionRow({
    required this.subscription,
    required this.monthlyEstimateInCents,
  });

  final Subscription subscription;
  final int monthlyEstimateInCents;
}

class AnalyticsBreakdown {
  const AnalyticsBreakdown._();

  static DateTime addMonths(DateTime date, int offset) =>
      DateTime(date.year, date.month + offset);

  static List<Payment> paymentsInRange(
    List<Payment> payments, {
    required DateTime start,
    required DateTime end,
  }) {
    return payments
        .where(
          (payment) =>
              !payment.date.isBefore(start) && payment.date.isBefore(end),
        )
        .toList(growable: false)
      ..sort((left, right) => right.date.compareTo(left.date));
  }

  static (DateTime start, DateTime end) boundsFor(
    AnalyticsPeriod period,
    DateTime now,
  ) {
    return switch (period) {
      AnalyticsPeriod.month => (
        DateTime(now.year, now.month),
        addMonths(DateTime(now.year, now.month), 1),
      ),
      AnalyticsPeriod.year => (DateTime(now.year), DateTime(now.year + 1)),
      AnalyticsPeriod.total => (
        DateTime.fromMillisecondsSinceEpoch(0),
        DateTime(now.year + 100),
      ),
    };
  }

  static String periodTitle(AnalyticsPeriod period, DateTime now) {
    return switch (period) {
      AnalyticsPeriod.month => 'Траты за этот месяц',
      AnalyticsPeriod.year => 'Траты за ${now.year}',
      AnalyticsPeriod.total => 'Все траты',
    };
  }

  static List<PaymentSpendRow> paymentRows({
    required List<Payment> payments,
    required List<Subscription> subscriptions,
    required AnalyticsPeriod period,
    required DateTime now,
  }) {
    final (start, end) = boundsFor(period, now);
    return rowsForPayments(
      payments: paymentsInRange(payments, start: start, end: end),
      subscriptions: subscriptions,
    );
  }

  static List<PaymentSpendRow> rowsForPayments({
    required List<Payment> payments,
    required List<Subscription> subscriptions,
  }) {
    final byId = <String, Subscription>{
      for (final item in subscriptions) item.id: item,
    };
    return <PaymentSpendRow>[
      for (final payment in payments)
        PaymentSpendRow(
          payment: payment,
          subscription: byId[payment.subscriptionId],
        ),
    ];
  }

  static List<PaymentSpendRow> rowsForMonth({
    required List<Payment> payments,
    required List<Subscription> subscriptions,
    required DateTime month,
  }) {
    final start = DateTime(month.year, month.month);
    return rowsForPayments(
      payments: paymentsInRange(
        payments,
        start: start,
        end: addMonths(start, 1),
      ),
      subscriptions: subscriptions,
    );
  }

  static int sumRows(List<PaymentSpendRow> rows) =>
      rows.fold<int>(0, (sum, row) => sum + row.payment.amountInCents);

  static List<CategorySubscriptionRow> activeInCategory({
    required List<Subscription> subscriptions,
    required SubscriptionCategory category,
    required DateTime now,
  }) {
    final rows = <CategorySubscriptionRow>[];
    for (final subscription in subscriptions) {
      if (subscription.status != SubscriptionStatus.active) continue;
      if (subscription.category != category) continue;
      final estimate = monthlyEstimate(subscription, now);
      if (estimate <= 0) continue;
      rows.add(
        CategorySubscriptionRow(
          subscription: subscription,
          monthlyEstimateInCents: estimate,
        ),
      );
    }
    rows.sort(
      (left, right) => right.monthlyEstimateInCents.compareTo(
        left.monthlyEstimateInCents,
      ),
    );
    return rows;
  }

  static int monthlyEstimate(Subscription subscription, DateTime now) {
    if (subscription.renewalMode == RenewalMode.manual) {
      final today = DateTime(now.year, now.month, now.day);
      final date = DateTime(
        subscription.nextPaymentDate.year,
        subscription.nextPaymentDate.month,
        subscription.nextPaymentDate.day,
      );
      if (date.isBefore(today)) return 0;
      return date.year == now.year && date.month == now.month
          ? subscription.priceInCents
          : 0;
    }
    return (subscription.annualPlanInCents / 12).round();
  }

  static String monthLabel(DateTime month) {
    const months = <String>[
      'Январь',
      'Февраль',
      'Март',
      'Апрель',
      'Май',
      'Июнь',
      'Июль',
      'Август',
      'Сентябрь',
      'Октябрь',
      'Ноябрь',
      'Декабрь',
    ];
    return '${months[month.month - 1]} ${month.year}';
  }

  static String categoryLabel(SubscriptionCategory category) => category.label;

  static Map<String, Object?> compactSummary({
    required List<Subscription> subscriptions,
    required List<Payment> payments,
    required List<MonthlySpendPoint> monthlySpending,
    required int thisMonthInCents,
    required int thisYearInCents,
    required int totalSpentInCents,
    required DateTime now,
  }) {
    final active = subscriptions
        .where((item) => item.status == SubscriptionStatus.active)
        .toList(growable: false);
    final paused = subscriptions
        .where((item) => item.status == SubscriptionStatus.paused)
        .length;
    final cancelled = subscriptions
        .where((item) => item.status == SubscriptionStatus.cancelled)
        .length;

    final byCategory = <String, int>{};
    for (final subscription in active) {
      final estimate = monthlyEstimate(subscription, now);
      if (estimate <= 0) continue;
      final key = categoryLabel(subscription.category);
      byCategory.update(key, (value) => value + estimate, ifAbsent: () => estimate);
    }

    return <String, Object?>{
      'currency': 'RUB',
      'asOf': now.toIso8601String().split('T').first,
      'activeCount': active.length,
      'pausedCount': paused,
      'cancelledCount': cancelled,
      'thisMonthRub': thisMonthInCents / 100,
      'thisYearRub': thisYearInCents / 100,
      'totalSpentRub': totalSpentInCents / 100,
      'monthlyLoadRub': active.fold<int>(
            0,
            (sum, item) => sum + monthlyEstimate(item, now),
          ) /
          100,
      'topSubscriptions': <Map<String, Object?>>[
        for (final item
            in (List<Subscription>.from(active)..sort(
                  (a, b) => monthlyEstimate(
                    b,
                    now,
                  ).compareTo(monthlyEstimate(a, now)),
                ))
                .take(8))
          <String, Object?>{
            'name': item.name,
            'category': categoryLabel(item.category),
            'monthlyRub': monthlyEstimate(item, now) / 100,
            'monthsActive': _monthsBetween(item.startDate, now).clamp(0, 999),
          },
      ],
      'categoryMonthlyRub': byCategory,
      'last6MonthsRub': <Map<String, Object?>>[
        for (final point in monthlySpending)
          <String, Object?>{
            'month':
                '${point.month.year}-${point.month.month.toString().padLeft(2, '0')}',
            'amountRub': point.amountInCents / 100,
          },
      ],
      'paymentCount': payments.length,
    };
  }

  static int _monthsBetween(DateTime start, DateTime end) {
    var months = (end.year - start.year) * 12 + end.month - start.month;
    if (end.day < start.day) months--;
    return months;
  }
}

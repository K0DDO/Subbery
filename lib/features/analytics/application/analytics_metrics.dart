import '../../../core/models/monthly_spend_point.dart';
import '../../subscriptions/domain/entities/payment.dart';
import '../../subscriptions/domain/entities/subscription.dart';

class CategorySpend {
  const CategorySpend({required this.category, required this.amountInCents});

  final SubscriptionCategory category;
  final int amountInCents;
}

enum AnalyticsInsightType { longevity, totalSpent, largestCategory }

class AnalyticsInsight {
  const AnalyticsInsight({
    required this.type,
    required this.title,
    required this.detail,
  });

  final AnalyticsInsightType type;
  final String title;
  final String detail;
}

class AnalyticsMetrics {
  const AnalyticsMetrics({
    required this.thisMonthInCents,
    required this.thisYearInCents,
    required this.totalSpentInCents,
    required this.monthlySpending,
    required this.categorySpending,
    required this.insights,
  });

  factory AnalyticsMetrics.calculate({
    required List<Subscription> subscriptions,
    required List<Payment> payments,
    required DateTime now,
  }) {
    final active = subscriptions
        .where((item) => item.status == SubscriptionStatus.active)
        .toList(growable: false);
    final recurringMonthly = active.fold<int>(
      0,
      (total, item) => total + _monthlyEstimate(item, now),
    );
    final startOfMonth = DateTime(now.year, now.month);
    final startOfNextMonth = _addMonths(startOfMonth, 1);
    final startOfYear = DateTime(now.year);
    final thisMonthActual = _sumPayments(
      payments,
      start: startOfMonth,
      end: startOfNextMonth,
    );
    final thisYear = _sumPayments(
      payments,
      start: startOfYear,
      end: DateTime(now.year + 1),
    );
    final total = payments.fold<int>(
      0,
      (sum, payment) => sum + payment.amountInCents,
    );

    final categoryTotals = <SubscriptionCategory, int>{};
    for (final subscription in active) {
      final normalized = _monthlyEstimate(subscription, now);
      if (normalized == 0) continue;
      categoryTotals.update(
        subscription.category,
        (value) => value + normalized,
        ifAbsent: () => normalized,
      );
    }
    final categorySpending =
        categoryTotals.entries
            .map(
              (entry) => CategorySpend(
                category: entry.key,
                amountInCents: entry.value,
              ),
            )
            .toList()
          ..sort(
            (left, right) => right.amountInCents.compareTo(left.amountInCents),
          );

    return AnalyticsMetrics(
      thisMonthInCents: thisMonthActual == 0
          ? recurringMonthly
          : thisMonthActual,
      thisYearInCents: thisYear,
      totalSpentInCents: total,
      monthlySpending: _sixMonthSpending(
        payments,
        now,
        fallback: recurringMonthly,
      ),
      categorySpending: categorySpending,
      insights: _buildInsights(
        subscriptions: subscriptions,
        totalSpentInCents: total,
        categories: categorySpending,
        now: now,
      ),
    );
  }

  final int thisMonthInCents;
  final int thisYearInCents;
  final int totalSpentInCents;
  final List<MonthlySpendPoint> monthlySpending;
  final List<CategorySpend> categorySpending;
  final List<AnalyticsInsight> insights;

  static int _monthlyEstimate(Subscription subscription, DateTime now) {
    if (subscription.renewalMode == RenewalMode.manual) {
      return subscription.nextPaymentDate.year == now.year &&
              subscription.nextPaymentDate.month == now.month
          ? subscription.priceInCents
          : 0;
    }
    return subscription.billingCycle == BillingCycle.monthly
        ? subscription.priceInCents
        : (subscription.priceInCents / 12).round();
  }

  static List<MonthlySpendPoint> _sixMonthSpending(
    List<Payment> payments,
    DateTime now, {
    required int fallback,
  }) {
    final currentMonth = DateTime(now.year, now.month);
    return <MonthlySpendPoint>[
      for (var offset = 5; offset >= 0; offset--)
        (() {
          final month = _addMonths(currentMonth, -offset);
          final amount = _sumPayments(
            payments,
            start: month,
            end: _addMonths(month, 1),
          );
          return MonthlySpendPoint(
            month: month,
            amountInCents: amount == 0 && offset == 0 ? fallback : amount,
          );
        })(),
    ];
  }

  static List<AnalyticsInsight> _buildInsights({
    required List<Subscription> subscriptions,
    required int totalSpentInCents,
    required List<CategorySpend> categories,
    required DateTime now,
  }) {
    final insights = <AnalyticsInsight>[];
    final active = subscriptions
        .where((item) => item.status == SubscriptionStatus.active)
        .toList();
    if (active.isNotEmpty) {
      active.sort((left, right) => left.startDate.compareTo(right.startDate));
      final oldest = active.first;
      final months = _monthsBetween(oldest.startDate, now).clamp(0, 999);
      insights.add(
        AnalyticsInsight(
          type: AnalyticsInsightType.longevity,
          title:
              '${oldest.name} используется уже $months ${_monthWord(months)}',
          detail: 'Самая продолжительная активная подписка',
        ),
      );
    }

    insights.add(
      AnalyticsInsight(
        type: AnalyticsInsightType.totalSpent,
        title: 'Всего потрачено ${_formatRubles(totalSpentInCents)}',
        detail: 'За всё время по записанным платежам',
      ),
    );

    if (categories.isNotEmpty) {
      insights.add(
        AnalyticsInsight(
          type: AnalyticsInsightType.largestCategory,
          title:
              'Главная категория — ${_categoryName(categories.first.category)}',
          detail:
              '${_formatRubles(categories.first.amountInCents)} в среднем за месяц',
        ),
      );
    }
    return insights;
  }

  static int _sumPayments(
    List<Payment> payments, {
    required DateTime start,
    required DateTime end,
  }) {
    return payments
        .where(
          (payment) =>
              !payment.date.isBefore(start) && payment.date.isBefore(end),
        )
        .fold<int>(0, (sum, payment) => sum + payment.amountInCents);
  }

  static int _monthsBetween(DateTime start, DateTime end) {
    var months = (end.year - start.year) * 12 + end.month - start.month;
    if (end.day < start.day) months--;
    return months;
  }

  static DateTime _addMonths(DateTime date, int offset) {
    return DateTime(date.year, date.month + offset);
  }

  static String _formatRubles(int cents) {
    final rubles = (cents / 100).round().toString();
    final buffer = StringBuffer();
    for (var index = 0; index < rubles.length; index++) {
      if (index > 0 && (rubles.length - index) % 3 == 0) buffer.write(' ');
      buffer.write(rubles[index]);
    }
    return '${buffer.toString()} ₽';
  }

  static String _monthWord(int months) {
    final last = months % 10;
    final lastTwo = months % 100;
    if (last == 1 && lastTwo != 11) return 'месяц';
    if (last >= 2 && last <= 4 && (lastTwo < 12 || lastTwo > 14)) {
      return 'месяца';
    }
    return 'месяцев';
  }

  static String _categoryName(SubscriptionCategory category) =>
      switch (category) {
        SubscriptionCategory.entertainment => 'развлечения',
        SubscriptionCategory.music => 'музыка',
        SubscriptionCategory.work => 'работа',
        SubscriptionCategory.cloud => 'облако',
        SubscriptionCategory.gaming => 'игры',
        SubscriptionCategory.education => 'образование',
        SubscriptionCategory.health => 'здоровье',
        SubscriptionCategory.other => 'другое',
      };
}

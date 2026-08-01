import '../../../core/models/monthly_spend_point.dart';
import '../../overview/application/overview_metrics.dart';
import '../../subscriptions/domain/entities/payment.dart';
import '../../subscriptions/domain/entities/subscription.dart';

class CategorySpend {
  const CategorySpend({required this.category, required this.amountInCents});

  final SubscriptionCategory category;
  final int amountInCents;
}

enum AnalyticsInsightType { longevity, totalSpent, largestCategory, ai }

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
    required this.plannedThisMonthInCents,
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

    final monthlySpending = OverviewMetrics.buildSixMonthSpending(
      subscriptions: active,
      payments: payments,
      now: now,
    );
    final plannedThisMonthInCents = monthlySpending.last.plannedAmountInCents;
    return AnalyticsMetrics(
      thisMonthInCents: thisMonthActual,
      plannedThisMonthInCents: plannedThisMonthInCents,
      thisYearInCents: thisYear,
      totalSpentInCents: total,
      monthlySpending: monthlySpending,
      categorySpending: categorySpending,
      insights: _buildInsights(
        subscriptions: subscriptions,
        totalSpentInCents: total,
        categories: categorySpending,
        monthlySpending: monthlySpending,
        thisMonthInCents: thisMonthActual,
        now: now,
      ),
    );
  }

  final int thisMonthInCents;
  final int plannedThisMonthInCents;
  final int thisYearInCents;
  final int totalSpentInCents;
  final List<MonthlySpendPoint> monthlySpending;
  final List<CategorySpend> categorySpending;
  final List<AnalyticsInsight> insights;

  static int _monthlyEstimate(Subscription subscription, DateTime now) {
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

  static List<AnalyticsInsight> _buildInsights({
    required List<Subscription> subscriptions,
    required int totalSpentInCents,
    required List<CategorySpend> categories,
    required List<MonthlySpendPoint> monthlySpending,
    required int thisMonthInCents,
    required DateTime now,
  }) {
    final insights = <AnalyticsInsight>[];
    final active = subscriptions
        .where((item) => item.status == SubscriptionStatus.active)
        .toList();
    final paused = subscriptions
        .where((item) => item.status == SubscriptionStatus.paused)
        .length;
    final cancelled = subscriptions
        .where((item) => item.status == SubscriptionStatus.cancelled)
        .length;

    if (active.isNotEmpty) {
      final monthlyLoad = active.fold<int>(
        0,
        (total, item) => total + _monthlyEstimate(item, now),
      );
      final yearlyProjection = monthlyLoad * 12;
      insights.add(
        AnalyticsInsight(
          type: AnalyticsInsightType.totalSpent,
          title: 'Месячная нагрузка ${_formatRubles(monthlyLoad)}',
          detail:
              'Активно ${active.length}, пауза $paused, отменено $cancelled. '
              'В год это около ${_formatRubles(yearlyProjection)}',
        ),
      );

      final pricey = List<Subscription>.from(active)
        ..sort(
          (left, right) => _monthlyEstimate(
            right,
            now,
          ).compareTo(_monthlyEstimate(left, now)),
        );
      final topSub = pricey.first;
      final topShare = monthlyLoad == 0
          ? 0
          : ((_monthlyEstimate(topSub, now) / monthlyLoad) * 100).round();
      insights.add(
        AnalyticsInsight(
          type: AnalyticsInsightType.longevity,
          title: '${topSub.name} тянет на $topShare%',
          detail:
              '${_formatRubles(_monthlyEstimate(topSub, now))} из месячного бюджета. '
              'Если редко пользуетесь — кандидат на паузу',
        ),
      );
    } else {
      insights.add(
        AnalyticsInsight(
          type: AnalyticsInsightType.totalSpent,
          title: 'Нет активных подписок',
          detail: 'Добавьте сервисы или возобновите приостановленные',
        ),
      );
    }

    var addedDynamicsInsight = false;
    if (monthlySpending.length >= 2) {
      final previous =
          monthlySpending[monthlySpending.length - 2].amountInCents;
      final delta = thisMonthInCents - previous;
      if (previous > 0 || thisMonthInCents > 0) {
        final direction = delta > 0
            ? 'выросли'
            : delta < 0
            ? 'снизились'
            : 'на том же уровне';
        insights.add(
          AnalyticsInsight(
            type: AnalyticsInsightType.largestCategory,
            title: 'Расходы $direction к прошлому месяцу',
            detail: delta == 0
                ? 'Сейчас ${_formatRubles(thisMonthInCents)} — как месяц назад'
                : '${delta > 0 ? '+' : ''}${_formatRubles(delta)} '
                      '(${_formatRubles(previous)} → ${_formatRubles(thisMonthInCents)})',
          ),
        );
        addedDynamicsInsight = true;
      }
    }
    if (!addedDynamicsInsight && categories.isNotEmpty) {
      final top = categories.first;
      final share = categories.fold<int>(0, (s, c) => s + c.amountInCents);
      final percent = share == 0
          ? 0
          : ((top.amountInCents / share) * 100).round();
      insights.add(
        AnalyticsInsight(
          type: AnalyticsInsightType.largestCategory,
          title: '${_categoryName(top.category)} — $percent% нагрузки',
          detail:
              '${_formatRubles(top.amountInCents)} в среднем за месяц. '
              'Всего по платежам ${_formatRubles(totalSpentInCents)}',
        ),
      );
    } else if (!addedDynamicsInsight && totalSpentInCents > 0) {
      insights.add(
        AnalyticsInsight(
          type: AnalyticsInsightType.largestCategory,
          title: 'Всего потрачено ${_formatRubles(totalSpentInCents)}',
          detail: 'Записей по категориям пока мало — копите историю платежей',
        ),
      );
    }
    return insights.take(3).toList(growable: false);
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

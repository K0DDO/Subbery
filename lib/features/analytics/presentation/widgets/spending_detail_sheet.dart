import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/monthly_spend_point.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../overview/presentation/widgets/spending_bar_chart.dart';
import '../../../shell/presentation/hotbar_morph_sheet.dart';
import '../../../subscriptions/domain/entities/payment.dart';
import '../../../subscriptions/domain/entities/subscription.dart';
import '../../../subscriptions/presentation/subscription_ui_extensions.dart';
import '../../../subscriptions/presentation/widgets/service_logo.dart';
import '../../application/analytics_breakdown.dart';
import '../../application/analytics_metrics.dart';
import 'category_spending_chart.dart';

Future<void> _showDropletSheet({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showHotbarMorphSheet<void>(context: context, builder: builder);
}

Future<void> showPeriodSpendingSheet({
  required BuildContext context,
  required AnalyticsPeriod period,
  required List<Payment> payments,
  required List<Subscription> subscriptions,
  required DateTime now,
  int? plannedInCents,
  String? footnote,
}) {
  final rows = AnalyticsBreakdown.paymentRows(
    payments: payments,
    subscriptions: subscriptions,
    period: period,
    now: now,
  );
  return showSpendingRowsSheet(
    context: context,
    title: AnalyticsBreakdown.periodTitle(period, now),
    subtitle: AppFormatters.money(AnalyticsBreakdown.sumRows(rows)),
    rows: rows,
    plannedInCents: plannedInCents,
    footnote: footnote,
    period: period,
    periodDate: now,
  );
}

Future<void> showMonthSpendingSheet({
  required BuildContext context,
  required DateTime month,
  required List<Payment> payments,
  required List<Subscription> subscriptions,
  int plannedInCents = 0,
}) {
  final rows = AnalyticsBreakdown.rowsForMonth(
    payments: payments,
    subscriptions: subscriptions,
    month: month,
  );
  return showSpendingRowsSheet(
    context: context,
    title: AnalyticsBreakdown.monthLabel(month),
    subtitle: AppFormatters.money(AnalyticsBreakdown.sumRows(rows)),
    rows: rows,
    plannedInCents: plannedInCents,
    period: AnalyticsPeriod.month,
    periodDate: month,
  );
}

Future<void> showSpendingRowsSheet({
  required BuildContext context,
  required String title,
  required String subtitle,
  required List<PaymentSpendRow> rows,
  int? plannedInCents,
  String? footnote,
  AnalyticsPeriod? period,
  DateTime? periodDate,
}) {
  final actualInCents = AnalyticsBreakdown.sumRows(rows);
  final summary = switch (period) {
    AnalyticsPeriod.month => _PaymentCategorySummary(rows: rows),
    AnalyticsPeriod.year => _YearSpendingSummary(
      rows: rows,
      year: periodDate?.year ?? DateTime.now().year,
    ),
    AnalyticsPeriod.total => _TopSubscriptionsSummary(rows: rows),
    null => null,
  };
  return _showDropletSheet(
    context: context,
    builder: (sheetContext) => _SpendingDetailSheet(
      title: title,
      subtitle: subtitle,
      actualInCents: plannedInCents == null ? null : actualInCents,
      plannedInCents: plannedInCents,
      footnote: footnote,
      summary: summary,
      child: rows.isEmpty
          ? const _EmptyDetail(message: 'За этот период платежей пока нет')
          : Column(
              children: <Widget>[
                for (final row in rows)
                  _PaymentTile(
                    row: row,
                    onTap: row.subscription == null
                        ? null
                        : () {
                            Navigator.pop(sheetContext);
                            context.push(
                              '/subscriptions/${row.subscription!.id}',
                            );
                          },
                  ),
              ],
            ),
    ),
  );
}

Future<void> showDynamicsDetailSheet({
  required BuildContext context,
  required List<MonthlySpendPoint> points,
  required List<Payment> payments,
  required List<Subscription> subscriptions,
}) {
  return _showDropletSheet(
    context: context,
    builder: (sheetContext) => _SpendingDetailSheet(
      title: 'Динамика расходов',
      subtitle: 'Последние ${points.length} месяцев',
      child: _DynamicsSheetContent(
        points: points,
        onPointSelected: (point) {
          Navigator.pop(sheetContext);
          showMonthSpendingSheet(
            context: context,
            month: point.month,
            payments: payments,
            subscriptions: subscriptions,
            plannedInCents: point.plannedAmountInCents,
          );
        },
      ),
    ),
  );
}

Future<void> showCategoriesDetailSheet({
  required BuildContext context,
  required List<CategorySpend> categories,
  required List<Subscription> subscriptions,
  required DateTime now,
}) {
  return _showDropletSheet(
    context: context,
    builder: (sheetContext) {
      final total = categories.fold<int>(
        0,
        (sum, item) => sum + item.amountInCents,
      );
      return _SpendingDetailSheet(
        title: 'По категориям',
        subtitle: 'Средняя нагрузка ${AppFormatters.money(total)} / мес',
        child: categories.isEmpty
            ? const _EmptyDetail(message: 'Нет активных подписок')
            : Column(
                children: <Widget>[
                  CategorySpendingChart(
                    categories: categories,
                    onCategorySelected: (category) {
                      Navigator.pop(sheetContext);
                      showCategorySubscriptionsSheet(
                        context: context,
                        category: category.category,
                        amountInCents: category.amountInCents,
                        subscriptions: subscriptions,
                        now: now,
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  for (final category in categories)
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      leading: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: category.category.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      title: Text(category.category.label),
                      subtitle: Text(
                        total == 0
                            ? '0%'
                            : '${((category.amountInCents / total) * 100).round()}% нагрузки',
                      ),
                      trailing: Text(
                        AppFormatters.money(category.amountInCents),
                        style: Theme.of(sheetContext).textTheme.titleMedium,
                      ),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        showCategorySubscriptionsSheet(
                          context: context,
                          category: category.category,
                          amountInCents: category.amountInCents,
                          subscriptions: subscriptions,
                          now: now,
                        );
                      },
                    ),
                ],
              ),
      );
    },
  );
}

Future<void> showCategorySubscriptionsSheet({
  required BuildContext context,
  required SubscriptionCategory category,
  required int amountInCents,
  required List<Subscription> subscriptions,
  required DateTime now,
}) {
  final rows = AnalyticsBreakdown.activeInCategory(
    subscriptions: subscriptions,
    category: category,
    now: now,
  );
  return _showDropletSheet(
    context: context,
    builder: (sheetContext) => _SpendingDetailSheet(
      title: category.label,
      subtitle: 'Около ${AppFormatters.money(amountInCents)} в месяц',
      child: rows.isEmpty
          ? const _EmptyDetail(message: 'В категории пока пусто')
          : Column(
              children: <Widget>[
                for (final row in rows)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    leading: ServiceLogo(
                      name: row.subscription.name,
                      logoKey: row.subscription.logo,
                      category: row.subscription.category,
                      size: 40,
                    ),
                    title: Text(row.subscription.name),
                    trailing: Text(
                      AppFormatters.money(row.monthlyEstimateInCents),
                      style: Theme.of(sheetContext).textTheme.titleMedium,
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      context.push('/subscriptions/${row.subscription.id}');
                    },
                  ),
              ],
            ),
    ),
  );
}

class _SpendingDetailSheet extends StatelessWidget {
  const _SpendingDetailSheet({
    required this.title,
    required this.subtitle,
    required this.child,
    this.actualInCents,
    this.plannedInCents,
    this.footnote,
    this.summary,
  });

  final String title;
  final String subtitle;
  final int? actualInCents;
  final int? plannedInCents;
  final String? footnote;
  final Widget? summary;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      children: <Widget>[
        Center(
          child: Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        if (actualInCents != null && plannedInCents != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: _AmountSummary(
                  label: 'Фактически',
                  amountInCents: actualInCents!,
                  color: Theme.of(context).colorScheme.primary,
                  filled: true,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _AmountSummary(
                  label: 'По плану',
                  amountInCents: plannedInCents!,
                  color: Theme.of(context).colorScheme.secondary,
                  filled: false,
                ),
              ),
            ],
          ),
        ],
        if (footnote != null) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(
            footnote!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (summary != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          summary!,
        ],
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }
}

class _DynamicsSheetContent extends StatefulWidget {
  const _DynamicsSheetContent({
    required this.points,
    required this.onPointSelected,
  });

  final List<MonthlySpendPoint> points;
  final ValueChanged<MonthlySpendPoint> onPointSelected;

  @override
  State<_DynamicsSheetContent> createState() => _DynamicsSheetContentState();
}

class _DynamicsSheetContentState extends State<_DynamicsSheetContent> {
  int _period = 6;

  @override
  Widget build(BuildContext context) {
    final count = _period.clamp(1, widget.points.length);
    final visible = widget.points.sublist(widget.points.length - count);
    final latest = visible.last.amountInCents;
    final previous = visible.length > 1
        ? visible[visible.length - 2].amountInCents
        : latest;
    final difference = latest - previous;
    final differenceColor = difference <= 0
        ? const Color(0xFF63C987)
        : Theme.of(context).colorScheme.primary;

    return Column(
      children: <Widget>[
        Align(
          alignment: Alignment.centerLeft,
          child: SegmentedButton<int>(
            segments: const <ButtonSegment<int>>[
              ButtonSegment<int>(value: 3, label: Text('3 мес')),
              ButtonSegment<int>(value: 6, label: Text('6 мес')),
            ],
            selected: <int>{_period},
            showSelectedIcon: false,
            onSelectionChanged: (selection) {
              setState(() => _period = selection.first);
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SpendingBarChart(
          points: visible,
          height: 240,
          onBarSelected: widget.onPointSelected,
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: differenceColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: differenceColor.withValues(alpha: 0.28)),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                difference <= 0
                    ? Icons.trending_down_rounded
                    : Icons.trending_up_rounded,
                color: differenceColor,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  difference == 0
                      ? 'Без изменений к прошлому месяцу'
                      : '${difference > 0 ? '+' : '−'}${AppFormatters.money(difference.abs())} к прошлому месяцу',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: differenceColor),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final point in visible.reversed)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
            ),
            title: Text(AnalyticsBreakdown.monthLabel(point.month)),
            trailing: Text(
              'Факт ${AppFormatters.money(point.amountInCents)}\n'
              'План ${AppFormatters.money(point.plannedAmountInCents)}',
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.45,
              ),
            ),
            onTap: () => widget.onPointSelected(point),
          ),
      ],
    );
  }
}

class _PaymentCategorySummary extends StatelessWidget {
  const _PaymentCategorySummary({required this.rows});

  final List<PaymentSpendRow> rows;

  @override
  Widget build(BuildContext context) {
    final totals = <SubscriptionCategory, int>{};
    for (final row in rows) {
      totals.update(
        row.category,
        (amount) => amount + row.payment.amountInCents,
        ifAbsent: () => row.payment.amountInCents,
      );
    }
    final categories = totals.entries.toList(growable: false)
      ..sort((left, right) => right.value.compareTo(left.value));
    if (categories.isEmpty) return const SizedBox.shrink();
    final total = categories.fold<int>(0, (sum, item) => sum + item.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Категории', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        for (final category in categories) ...<Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: category.key.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(child: Text(category.key.label)),
              Text(
                '${((category.value / total) * 100).round()}% · '
                '${AppFormatters.money(category.value)}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
      ],
    );
  }
}

class _YearSpendingSummary extends StatelessWidget {
  const _YearSpendingSummary({required this.rows, required this.year});

  final List<PaymentSpendRow> rows;
  final int year;

  @override
  Widget build(BuildContext context) {
    final points = <MonthlySpendPoint>[
      for (var month = 1; month <= 12; month++)
        MonthlySpendPoint(
          month: DateTime(year, month),
          amountInCents: rows
              .where(
                (row) =>
                    row.payment.date.year == year &&
                    row.payment.date.month == month,
              )
              .fold<int>(0, (sum, row) => sum + row.payment.amountInCents),
        ),
    ];
    final now = DateTime.now();
    final comparisonMonth = now.year == year ? now.month : 12;
    final current = points[comparisonMonth - 1].amountInCents;
    final previous = comparisonMonth > 1
        ? points[comparisonMonth - 2].amountInCents
        : 0;
    final difference = current - previous;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Расходы по месяцам',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        SpendingBarChart(points: points, height: 220),
        const SizedBox(height: AppSpacing.sm),
        Text(
          difference == 0
              ? 'Текущий месяц без изменений'
              : 'Текущий месяц: ${difference > 0 ? '+' : '−'}'
                    '${AppFormatters.money(difference.abs())} к предыдущему',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _TopSubscriptionsSummary extends StatelessWidget {
  const _TopSubscriptionsSummary({required this.rows});

  final List<PaymentSpendRow> rows;

  @override
  Widget build(BuildContext context) {
    final totals = <String, ({PaymentSpendRow row, int amount})>{};
    for (final row in rows) {
      final key = row.subscription?.id ?? row.name;
      final previous = totals[key];
      totals[key] = (
        row: row,
        amount: (previous?.amount ?? 0) + row.payment.amountInCents,
      );
    }
    final top = totals.values.toList(growable: false)
      ..sort((left, right) => right.amount.compareTo(left.amount));
    if (top.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Самые дорогие подписки',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final item in top.take(5))
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
            ),
            leading: ServiceLogo(
              name: item.row.name,
              logoKey: item.row.logoKey,
              category: item.row.category,
              size: 38,
            ),
            title: Text(item.row.name),
            trailing: Text(
              AppFormatters.money(item.amount),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        const Divider(),
        Text(
          'История платежей',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}

class _AmountSummary extends StatelessWidget {
  const _AmountSummary({
    required this.label,
    required this.amountInCents,
    required this.color,
    required this.filled,
  });

  final String label;
  final int amountInCents;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: filled ? 0.16 : 0.07),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: color.withValues(alpha: filled ? 0.28 : 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              AppFormatters.money(amountInCents),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({required this.row, this.onTap});

  final PaymentSpendRow row;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      leading: ServiceLogo(
        name: row.name,
        logoKey: row.logoKey,
        category: row.category,
        size: 40,
      ),
      title: Text(row.name),
      subtitle: Text(AppFormatters.shortDate(row.payment.date)),
      trailing: Text(
        AppFormatters.money(row.payment.amountInCents),
        style: Theme.of(context).textTheme.titleMedium,
      ),
      onTap: onTap,
    );
  }
}

class _EmptyDetail extends StatelessWidget {
  const _EmptyDetail({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

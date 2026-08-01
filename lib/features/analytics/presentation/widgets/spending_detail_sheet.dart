import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/monthly_spend_point.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../shell/presentation/hotbar_morph_sheet.dart';
import '../../../subscriptions/domain/entities/payment.dart';
import '../../../subscriptions/domain/entities/subscription.dart';
import '../../../subscriptions/presentation/subscription_ui_extensions.dart';
import '../../../subscriptions/presentation/widgets/service_logo.dart';
import '../../application/analytics_breakdown.dart';
import '../../application/analytics_metrics.dart';

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
  );
}

Future<void> showSpendingRowsSheet({
  required BuildContext context,
  required String title,
  required String subtitle,
  required List<PaymentSpendRow> rows,
  int? plannedInCents,
  String? footnote,
}) {
  final actualInCents = AnalyticsBreakdown.sumRows(rows);
  return _showDropletSheet(
    context: context,
    builder: (sheetContext) => _SpendingDetailSheet(
      title: title,
      subtitle: subtitle,
      actualInCents: plannedInCents == null ? null : actualInCents,
      plannedInCents: plannedInCents,
      footnote: footnote,
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
      child: Column(
        children: <Widget>[
          for (final point in points.reversed)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
              ),
              title: Text(AnalyticsBreakdown.monthLabel(point.month)),
              trailing: Text(
                'Факт ${AppFormatters.money(point.amountInCents)}\n'
                'План ${AppFormatters.money(point.plannedAmountInCents)}',
                textAlign: TextAlign.end,
                style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.45,
                ),
              ),
              onTap: () {
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
        ],
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
  });

  final String title;
  final String subtitle;
  final int? actualInCents;
  final int? plannedInCents;
  final String? footnote;
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
        const SizedBox(height: AppSpacing.sm),
        child,
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

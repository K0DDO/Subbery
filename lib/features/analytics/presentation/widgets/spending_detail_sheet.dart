import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/monthly_spend_point.dart';
import '../../../../core/theme/app_accent_theme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/glass_theme.dart';
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
  return switch (period) {
    AnalyticsPeriod.month => _showDropletSheet(
      context: context,
      builder: (sheetContext) => _MonthAnalyticsSheet(
        now: now,
        rows: rows,
        plannedInCents: plannedInCents ?? 0,
        footnote: footnote,
        onPaymentTap: (row) => _openSubscription(context, sheetContext, row),
      ),
    ),
    AnalyticsPeriod.year => _showDropletSheet(
      context: context,
      builder: (sheetContext) => _YearAnalyticsSheet(
        year: now.year,
        now: now,
        points: AnalyticsBreakdown.yearSpending(
          subscriptions: subscriptions,
          payments: payments,
          year: now.year,
        ),
        onMonthTap: (point) {
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
    AnalyticsPeriod.total => _showDropletSheet(
      context: context,
      builder: (sheetContext) => _TotalAnalyticsSheet(
        rows: rows,
        onPaymentTap: (row) => _openSubscription(context, sheetContext, row),
      ),
    ),
  };
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
  final now = DateTime.now();
  return _showDropletSheet(
    context: context,
    builder: (sheetContext) => _MonthAnalyticsSheet(
      now: now,
      month: month,
      rows: rows,
      plannedInCents: plannedInCents,
      onPaymentTap: (row) => _openSubscription(context, sheetContext, row),
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
    builder: (sheetContext) => _DynamicsAnalyticsSheet(
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
    builder: (sheetContext) => _CategoriesAnalyticsSheet(
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
    builder: (sheetContext) => _SheetScaffold(
      title: category.label,
      subtitle: 'Около ${AppFormatters.money(amountInCents)} в месяц',
      accent: category.color(context),
      children: <Widget>[
        if (rows.isEmpty)
          const _EmptyDetail(message: 'В категории пока пусто')
        else
          for (final row in rows)
            _GlassPaymentRow(
              leading: ServiceLogo(
                name: row.subscription.name,
                logoKey: row.subscription.logo,
                category: row.subscription.category,
                size: 40,
              ),
              title: row.subscription.name,
              trailing: AppFormatters.money(row.monthlyEstimateInCents),
              onTap: () {
                Navigator.pop(sheetContext);
                context.push('/subscriptions/${row.subscription.id}');
              },
            ),
      ],
    ),
  );
}

void _openSubscription(
  BuildContext context,
  BuildContext sheetContext,
  PaymentSpendRow row,
) {
  if (row.subscription == null) return;
  Navigator.pop(sheetContext);
  context.push('/subscriptions/${row.subscription!.id}');
}

enum _MonthKind { past, current, future }

_MonthKind _monthKind(DateTime month, DateTime now) {
  final current = DateTime(now.year, now.month);
  final target = DateTime(month.year, month.month);
  if (target.isBefore(current)) return _MonthKind.past;
  if (target.isAfter(current)) return _MonthKind.future;
  return _MonthKind.current;
}

class _SheetScaffold extends StatelessWidget {
  const _SheetScaffold({
    required this.title,
    required this.subtitle,
    required this.children,
    this.accent,
    this.hero,
  });

  final String title;
  final String subtitle;
  final Color? accent;
  final Widget? hero;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final effectiveAccent = accent ?? context.subberryTheme.primary;
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        52,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      children: <Widget>[
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: effectiveAccent,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (hero != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          hero!,
        ],
        const SizedBox(height: AppSpacing.md),
        ...children,
      ],
    );
  }
}

class _MonthAnalyticsSheet extends StatelessWidget {
  const _MonthAnalyticsSheet({
    required this.now,
    required this.rows,
    required this.plannedInCents,
    required this.onPaymentTap,
    this.month,
    this.footnote,
  });

  final DateTime now;
  final DateTime? month;
  final List<PaymentSpendRow> rows;
  final int plannedInCents;
  final String? footnote;
  final ValueChanged<PaymentSpendRow> onPaymentTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.subberryTheme;
    final target = month ?? DateTime(now.year, now.month);
    final kind = _monthKind(target, now);
    final actual = AnalyticsBreakdown.sumRows(rows);
    final expected = math.max(0, plannedInCents - actual);
    final forecast = actual + expected;

    return _SheetScaffold(
      title: AnalyticsBreakdown.monthLabel(target),
      subtitle: switch (kind) {
        _MonthKind.past => 'Фактические расходы',
        _MonthKind.current => 'Факт, ожидание и прогноз',
        _MonthKind.future => 'Ожидаемые расходы',
      },
      accent: kind == _MonthKind.future
          ? palette.primaryLight
          : palette.primary,
      hero: switch (kind) {
        _MonthKind.past => _SpendHeroCard(
          label: 'Фактически',
          amountInCents: actual,
          color: palette.primary,
        ),
        _MonthKind.current => _CurrentMonthHero(
          actualInCents: actual,
          expectedInCents: expected,
          forecastInCents: forecast,
        ),
        _MonthKind.future => _SpendHeroCard(
          label: 'Ожидается',
          amountInCents: plannedInCents,
          color: palette.primaryLight,
        ),
      },
      children: <Widget>[
        if (footnote != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              footnote!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        _SectionLabel('Категории месяца'),
        const SizedBox(height: AppSpacing.sm),
        _PaymentCategoryChips(rows: rows),
        const SizedBox(height: AppSpacing.md),
        _SectionLabel('Подписки и платежи'),
        const SizedBox(height: AppSpacing.sm),
        if (rows.isEmpty)
          const _EmptyDetail(message: 'За этот период платежей пока нет')
        else
          for (final row in rows)
            _GlassPaymentRow(
              leading: ServiceLogo(
                name: row.name,
                logoKey: row.logoKey,
                category: row.category,
                size: 40,
              ),
              title: row.name,
              subtitle: AppFormatters.shortDate(row.payment.date),
              trailing: AppFormatters.money(row.payment.amountInCents),
              trailingColor: palette.primary,
              onTap: () => onPaymentTap(row),
            ),
      ],
    );
  }
}

class _YearAnalyticsSheet extends StatelessWidget {
  const _YearAnalyticsSheet({
    required this.year,
    required this.now,
    required this.points,
    required this.onMonthTap,
  });

  final int year;
  final DateTime now;
  final List<MonthlySpendPoint> points;
  final ValueChanged<MonthlySpendPoint> onMonthTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.subberryTheme;
    final visible = points
        .where((point) {
          final kind = _monthKind(point.month, now);
          return switch (kind) {
            _MonthKind.past => point.amountInCents > 0,
            _MonthKind.current =>
              point.amountInCents > 0 || point.plannedAmountInCents > 0,
            _MonthKind.future => point.plannedAmountInCents > 0,
          };
        })
        .toList(growable: false);
    final maxValue = visible.fold<int>(
      0,
      (max, point) => math.max(
        max,
        math.max(point.amountInCents, point.plannedAmountInCents),
      ),
    );
    final yearActual = points.fold<int>(
      0,
      (sum, point) => sum + point.amountInCents,
    );

    return _SheetScaffold(
      title: 'Траты за $year',
      subtitle: 'Помесячная картина года',
      accent: palette.primary,
      hero: _SpendHeroCard(
        label: 'Факт за год',
        amountInCents: yearActual,
        color: palette.primary,
      ),
      children: <Widget>[
        _SectionLabel('Месяцы'),
        const SizedBox(height: AppSpacing.sm),
        if (visible.isEmpty)
          const _EmptyDetail(message: 'За этот год расходов пока нет')
        else
          for (final point in visible) ...<Widget>[
            _YearMonthGlassRow(
              point: point,
              now: now,
              maxAmountInCents: math.max(maxValue, 1),
              onTap: () => onMonthTap(point),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
      ],
    );
  }
}

class _YearMonthGlassRow extends StatelessWidget {
  const _YearMonthGlassRow({
    required this.point,
    required this.now,
    required this.maxAmountInCents,
    required this.onTap,
  });

  final MonthlySpendPoint point;
  final DateTime now;
  final int maxAmountInCents;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.subberryTheme;
    final glass = Theme.of(context).extension<GlassTheme>()!;
    final kind = _monthKind(point.month, now);
    final actual = point.amountInCents;
    final expected = math.max(0, point.plannedAmountInCents - actual);
    final displayAmount = switch (kind) {
      _MonthKind.past => actual,
      _MonthKind.current => actual + expected,
      _MonthKind.future => point.plannedAmountInCents,
    };
    final barColor = kind == _MonthKind.future
        ? palette.primaryLight
        : palette.primary;
    final ratio = (displayAmount / maxAmountInCents).clamp(0.0, 1.0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: glass.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: glass.border),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: barColor.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      AnalyticsBreakdown.monthName(point.month),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    AppFormatters.money(displayAmount),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: barColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: SizedBox(
                  height: 12,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      if (kind == _MonthKind.current) {
                        final actualWidth =
                            width * (actual / maxAmountInCents).clamp(0.0, 1.0);
                        final expectedWidth =
                            width *
                            (expected / maxAmountInCents).clamp(0.0, 1.0);
                        return Stack(
                          children: <Widget>[
                            Positioned.fill(
                              child: ColoredBox(
                                color: palette.primaryLight.withValues(
                                  alpha: 0.14,
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              width: actualWidth,
                              child: ColoredBox(color: palette.primary),
                            ),
                            Positioned(
                              left: actualWidth,
                              top: 0,
                              bottom: 0,
                              width: expectedWidth,
                              child: ColoredBox(
                                color: palette.primaryLight.withValues(
                                  alpha: 0.85,
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                      return Stack(
                        children: <Widget>[
                          Positioned.fill(
                            child: ColoredBox(
                              color: barColor.withValues(alpha: 0.12),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            width: width * ratio,
                            child: ColoredBox(
                              color: barColor.withValues(
                                alpha: kind == _MonthKind.future ? 0.72 : 1,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              if (kind == _MonthKind.current) ...<Widget>[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Факт ${AppFormatters.money(actual)} · '
                  'Ожидается ${AppFormatters.money(expected)}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TotalAnalyticsSheet extends StatelessWidget {
  const _TotalAnalyticsSheet({required this.rows, required this.onPaymentTap});

  final List<PaymentSpendRow> rows;
  final ValueChanged<PaymentSpendRow> onPaymentTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.subberryTheme;
    final total = AnalyticsBreakdown.sumRows(rows);
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

    return _SheetScaffold(
      title: 'Все траты',
      subtitle: 'История и самые дорогие подписки',
      accent: palette.primary,
      hero: _SpendHeroCard(
        label: 'Всего потрачено',
        amountInCents: total,
        color: palette.primary,
      ),
      children: <Widget>[
        _SectionLabel('Топ подписок'),
        const SizedBox(height: AppSpacing.sm),
        if (top.isEmpty)
          const _EmptyDetail(message: 'История платежей пока пуста')
        else
          for (final item in top.take(5))
            _GlassPaymentRow(
              leading: ServiceLogo(
                name: item.row.name,
                logoKey: item.row.logoKey,
                category: item.row.category,
                size: 40,
              ),
              title: item.row.name,
              trailing: AppFormatters.money(item.amount),
              trailingColor: palette.primary,
              onTap: item.row.subscription == null
                  ? null
                  : () => onPaymentTap(item.row),
            ),
        const SizedBox(height: AppSpacing.md),
        _SectionLabel('История платежей'),
        const SizedBox(height: AppSpacing.sm),
        for (final row in rows.take(20))
          _GlassPaymentRow(
            leading: ServiceLogo(
              name: row.name,
              logoKey: row.logoKey,
              category: row.category,
              size: 36,
            ),
            title: row.name,
            subtitle: AppFormatters.shortDate(row.payment.date),
            trailing: AppFormatters.money(row.payment.amountInCents),
            trailingColor: palette.primary,
            onTap: () => onPaymentTap(row),
          ),
      ],
    );
  }
}

class _DynamicsAnalyticsSheet extends StatefulWidget {
  const _DynamicsAnalyticsSheet({
    required this.points,
    required this.onPointSelected,
  });

  final List<MonthlySpendPoint> points;
  final ValueChanged<MonthlySpendPoint> onPointSelected;

  @override
  State<_DynamicsAnalyticsSheet> createState() =>
      _DynamicsAnalyticsSheetState();
}

class _DynamicsAnalyticsSheetState extends State<_DynamicsAnalyticsSheet> {
  int _period = 6;

  @override
  Widget build(BuildContext context) {
    final palette = context.subberryTheme;
    final count = _period.clamp(1, widget.points.length);
    final visible = widget.points.sublist(widget.points.length - count);
    final latest = visible.last.amountInCents;
    final previous = visible.length > 1
        ? visible[visible.length - 2].amountInCents
        : latest;
    final difference = latest - previous;
    final differenceColor = difference <= 0 ? palette.success : palette.primary;

    return _SheetScaffold(
      title: 'Динамика расходов',
      subtitle: 'Большой график и фильтр периода',
      accent: palette.primary,
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
        DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).extension<GlassTheme>()!.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: Theme.of(context).extension<GlassTheme>()!.border,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            child: SpendingBarChart(
              points: visible,
              height: 260,
              onBarSelected: widget.onPointSelected,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: differenceColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.lg),
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
                      : '${difference > 0 ? '+' : '−'}'
                            '${AppFormatters.money(difference.abs())} к прошлому месяцу',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: differenceColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final point in visible.reversed)
          _GlassPaymentRow(
            leading: Icon(
              Icons.calendar_month_rounded,
              color: palette.primary.withValues(alpha: 0.9),
            ),
            title: AnalyticsBreakdown.monthLabel(point.month),
            subtitle:
                'Факт ${AppFormatters.money(point.amountInCents)} · '
                'План ${AppFormatters.money(point.plannedAmountInCents)}',
            trailing: '',
            onTap: () => widget.onPointSelected(point),
          ),
      ],
    );
  }
}

class _CategoriesAnalyticsSheet extends StatelessWidget {
  const _CategoriesAnalyticsSheet({
    required this.categories,
    required this.onCategorySelected,
  });

  final List<CategorySpend> categories;
  final ValueChanged<CategorySpend> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    final total = categories.fold<int>(
      0,
      (sum, item) => sum + item.amountInCents,
    );
    return _SheetScaffold(
      title: 'По категориям',
      subtitle: 'Средняя нагрузка ${AppFormatters.money(total)} / мес',
      accent: Theme.of(context).colorScheme.secondary,
      children: <Widget>[
        if (categories.isEmpty)
          const _EmptyDetail(message: 'Нет активных подписок')
        else ...<Widget>[
          CategorySpendingChart(
            categories: categories,
            onCategorySelected: onCategorySelected,
          ),
          const SizedBox(height: AppSpacing.md),
          for (final category in categories)
            _GlassPaymentRow(
              leading: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: category.category.color(context),
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: category.category
                          .color(context)
                          .withValues(alpha: 0.35),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              title: category.category.label,
              subtitle: total == 0
                  ? '0%'
                  : '${((category.amountInCents / total) * 100).round()}% нагрузки',
              trailing: AppFormatters.money(category.amountInCents),
              trailingColor: category.category.color(context),
              onTap: () => onCategorySelected(category),
            ),
        ],
      ],
    );
  }
}

class _CurrentMonthHero extends StatelessWidget {
  const _CurrentMonthHero({
    required this.actualInCents,
    required this.expectedInCents,
    required this.forecastInCents,
  });

  final int actualInCents;
  final int expectedInCents;
  final int forecastInCents;

  @override
  Widget build(BuildContext context) {
    final palette = context.subberryTheme;
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _SpendHeroCard(
                label: 'Фактически',
                amountInCents: actualInCents,
                color: palette.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _SpendHeroCard(
                label: 'Ожидается',
                amountInCents: expectedInCents,
                color: palette.primaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _SpendHeroCard(
          label: 'Прогноз',
          amountInCents: forecastInCents,
          color: Color.lerp(palette.primary, palette.primaryLight, 0.35)!,
        ),
      ],
    );
  }
}

class _SpendHeroCard extends StatelessWidget {
  const _SpendHeroCard({
    required this.label,
    required this.amountInCents,
    required this.color,
  });

  final String label;
  final int amountInCents;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            color.withValues(alpha: 0.20),
            color.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              AppFormatters.money(amountInCents),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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

class _PaymentCategoryChips extends StatelessWidget {
  const _PaymentCategoryChips({required this.rows});

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
    if (categories.isEmpty) {
      return const _EmptyDetail(message: 'Категорий пока нет');
    }
    final total = categories.fold<int>(0, (sum, item) => sum + item.value);

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        for (final category in categories)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: category.key.color(context).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: category.key.color(context).withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              '${category.key.label} · '
              '${((category.value / total) * 100).round()}% · '
              '${AppFormatters.money(category.value)}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: category.key.color(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _GlassPaymentRow extends StatelessWidget {
  const _GlassPaymentRow({
    required this.leading,
    required this.title,
    required this.trailing,
    this.subtitle,
    this.trailingColor,
    this.onTap,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final String trailing;
  final Color? trailingColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<GlassTheme>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Ink(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: glass.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: glass.border),
            ),
            child: Row(
              children: <Widget>[
                leading,
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                    ],
                  ),
                ),
                if (trailing.isNotEmpty)
                  Text(
                    trailing,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: trailingColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}

class _EmptyDetail extends StatelessWidget {
  const _EmptyDetail({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
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

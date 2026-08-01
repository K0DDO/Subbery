import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_accent_theme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/screen_header.dart';
import '../../overview/presentation/widgets/spending_bar_chart.dart';
import '../../shell/application/tab_reset_provider.dart';
import '../../subscriptions/application/subscription_providers.dart';
import '../../subscriptions/domain/entities/payment.dart';
import '../../subscriptions/domain/entities/subscription.dart';
import '../application/ai_insights_provider.dart';
import '../application/analytics_breakdown.dart';
import '../application/analytics_metrics.dart';
import 'widgets/category_spending_chart.dart';
import 'widgets/spending_detail_sheet.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptions = ref.watch(subscriptionsProvider);
    final payments = ref.watch(allPaymentsProvider);
    final resetRevision = ref.watch(tabResetRevisionProvider(2));

    return SafeArea(
      bottom: false,
      child: Column(
        children: <Widget>[
          const ScreenHeader(
            title: 'Аналитика',
            subtitle: 'Понятная картина ваших расходов',
          ),
          Expanded(
            child: subscriptions.when(
              data: (items) => payments.when(
                data: (paymentItems) => _AnalyticsContent(
                  subscriptions: items,
                  payments: paymentItems,
                  resetRevision: resetRevision,
                ),
                loading: _AnalyticsLoading.new,
                error: (error, stackTrace) => const _AnalyticsError(),
              ),
              loading: _AnalyticsLoading.new,
              error: (error, stackTrace) => const _AnalyticsError(),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsContent extends ConsumerWidget {
  const _AnalyticsContent({
    required this.subscriptions,
    required this.payments,
    required this.resetRevision,
  });

  final List<Subscription> subscriptions;
  final List<Payment> payments;
  final int resetRevision;

  void _openPeriod(
    BuildContext context,
    AnalyticsPeriod period,
    DateTime now, {
    int? plannedThisMonthInCents,
  }) {
    final hasMonthPayments =
        period == AnalyticsPeriod.month &&
        AnalyticsBreakdown.paymentRows(
          payments: payments,
          subscriptions: subscriptions,
          period: AnalyticsPeriod.month,
          now: now,
        ).isEmpty;
    showPeriodSpendingSheet(
      context: context,
      period: period,
      payments: payments,
      subscriptions: subscriptions,
      now: now,
      plannedInCents: period == AnalyticsPeriod.month
          ? plannedThisMonthInCents
          : null,
      footnote: hasMonthPayments
          ? 'Фактических списаний пока нет. План рассчитан по активным подпискам и их графику.'
          : null,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = context.accentTheme;
    if (subscriptions.isEmpty) {
      return EmptyState(
        title: 'Здесь появится аналитика',
        description:
            'Добавьте подписки, и Subberry покажет\n'
            'динамику и структуру расходов',
        actionLabel: 'Добавить подписку',
        icon: Icons.auto_graph_rounded,
        onAction: () => context.push('/subscriptions/add'),
      );
    }

    final now = DateTime.now();
    final metrics = AnalyticsMetrics.calculate(
      subscriptions: subscriptions,
      payments: payments,
      now: now,
    );
    final aiRequest = buildAiInsightsRequest(
      subscriptions: subscriptions,
      payments: payments,
      metrics: metrics,
      now: now,
    );
    final aiInsights = ref.watch(aiInsightsProvider(aiRequest));

    return ListView(
      key: ValueKey<String>('analytics-$resetRevision'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        128,
      ),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _AnalyticsMetricCard(
                label: 'Этот месяц',
                value: AppFormatters.money(metrics.thisMonthInCents),
                icon: Icons.calendar_month_rounded,
                color: accent.primary,
                onTap: () => _openPeriod(
                  context,
                  AnalyticsPeriod.month,
                  now,
                  plannedThisMonthInCents: metrics.plannedThisMonthInCents,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _AnalyticsMetricCard(
                label: 'Этот год',
                value: AppFormatters.money(metrics.thisYearInCents),
                icon: Icons.date_range_rounded,
                color: accent.secondary,
                onTap: () => _openPeriod(context, AnalyticsPeriod.year, now),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _AnalyticsMetricCard(
          label: 'Всего потрачено',
          value: AppFormatters.money(metrics.totalSpentInCents),
          icon: Icons.savings_rounded,
          color: accent.tertiary,
          horizontal: true,
          onTap: () => _openPeriod(context, AnalyticsPeriod.total, now),
        ),
        const SizedBox(height: AppSpacing.lg),
        _SectionTitle(
          title: 'Динамика расходов',
          subtitle: 'План и факт за последние 6 месяцев',
          onTap: () => showDynamicsDetailSheet(
            context: context,
            points: metrics.monthlySpending,
            payments: payments,
            subscriptions: subscriptions,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        GlassCard(
          child: SpendingBarChart(
            points: metrics.monthlySpending,
            onBarSelected: (point) => showMonthSpendingSheet(
              context: context,
              month: point.month,
              payments: payments,
              subscriptions: subscriptions,
              plannedInCents: point.plannedAmountInCents,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _SectionTitle(
          title: 'По категориям',
          subtitle: 'Нажмите для детализации',
          onTap: () => showCategoriesDetailSheet(
            context: context,
            categories: metrics.categorySpending,
            subscriptions: subscriptions,
            now: now,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        GlassCard(
          child: metrics.categorySpending.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Center(child: Text('Нет активных подписок')),
                )
              : CategorySpendingChart(
                  categories: metrics.categorySpending,
                  onCategorySelected: (category) =>
                      showCategorySubscriptionsSheet(
                        context: context,
                        category: category.category,
                        amountInCents: category.amountInCents,
                        subscriptions: subscriptions,
                        now: now,
                      ),
                ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const _SectionTitle(
          title: 'Умные подсказки',
          subtitle: 'На основе ваших подписок и платежей',
        ),
        const SizedBox(height: AppSpacing.sm),
        ...aiInsights.when(
          data: (insights) => <Widget>[
            for (final insight in insights) ...<Widget>[
              _InsightCard(insight: insight),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
          loading: () => <Widget>[
            for (final insight in metrics.insights) ...<Widget>[
              _InsightCard(insight: insight),
              const SizedBox(height: AppSpacing.sm),
            ],
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.xs),
              child: Center(
                child: SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ],
          error: (_, _) => <Widget>[
            for (final insight in metrics.insights) ...<Widget>[
              _InsightCard(insight: insight),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ],
    );
  }
}

class _AnalyticsMetricCard extends StatelessWidget {
  const _AnalyticsMetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.horizontal = false,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool horizontal;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final iconWidget = Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(icon, color: color, size: 21),
    );
    final content = Column(
      crossAxisAlignment: horizontal
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: <Widget>[
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value, style: Theme.of(context).textTheme.titleLarge),
        ),
      ],
    );

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: horizontal
          ? Row(
              children: <Widget>[
                iconWidget,
                const SizedBox(width: AppSpacing.md),
                Expanded(child: content),
                if (onTap != null)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              ],
            )
          : Column(
              children: <Widget>[
                iconWidget,
                const SizedBox(height: AppSpacing.sm),
                content,
              ],
            ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});

  final AnalyticsInsight insight;

  @override
  Widget build(BuildContext context) {
    final accent = context.accentTheme;
    final (icon, color) = switch (insight.type) {
      AnalyticsInsightType.longevity => (
        Icons.workspace_premium_rounded,
        accent.warning,
      ),
      AnalyticsInsightType.totalSpent => (
        Icons.payments_rounded,
        accent.primary,
      ),
      AnalyticsInsightType.largestCategory => (
        Icons.pie_chart_rounded,
        accent.tertiary,
      ),
      AnalyticsInsightType.ai => (Icons.auto_awesome_rounded, accent.secondary),
    };

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  insight.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  insight.detail,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );

    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: <Widget>[
            Expanded(child: content),
            Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsLoading extends StatelessWidget {
  const _AnalyticsLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _AnalyticsError extends StatelessWidget {
  const _AnalyticsError();

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      title: 'Не удалось собрать аналитику',
      description: 'Попробуйте открыть экран ещё раз',
      icon: Icons.query_stats_rounded,
    );
  }
}

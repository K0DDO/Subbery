import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_accent_theme.dart';
import '../../../core/theme/app_colors.dart';
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
import '../application/analytics_metrics.dart';
import 'widgets/category_spending_chart.dart';

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

class _AnalyticsContent extends StatelessWidget {
  const _AnalyticsContent({
    required this.subscriptions,
    required this.payments,
    required this.resetRevision,
  });

  final List<Subscription> subscriptions;
  final List<Payment> payments;
  final int resetRevision;

  @override
  Widget build(BuildContext context) {
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

    final metrics = AnalyticsMetrics.calculate(
      subscriptions: subscriptions,
      payments: payments,
      now: DateTime.now(),
    );

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
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _AnalyticsMetricCard(
                label: 'Этот год',
                value: AppFormatters.money(metrics.thisYearInCents),
                icon: Icons.date_range_rounded,
                color: accent.secondary,
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
        ),
        const SizedBox(height: AppSpacing.lg),
        const _SectionTitle(
          title: 'Динамика расходов',
          subtitle: 'Последние 6 месяцев',
        ),
        const SizedBox(height: AppSpacing.sm),
        GlassCard(child: SpendingBarChart(points: metrics.monthlySpending)),
        const SizedBox(height: AppSpacing.lg),
        const _SectionTitle(
          title: 'По категориям',
          subtitle: 'Средняя нагрузка в месяц',
        ),
        const SizedBox(height: AppSpacing.sm),
        GlassCard(
          child: metrics.categorySpending.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Center(child: Text('Нет активных подписок')),
                )
              : CategorySpendingChart(categories: metrics.categorySpending),
        ),
        const SizedBox(height: AppSpacing.lg),
        const _SectionTitle(
          title: 'Умные подсказки',
          subtitle: 'Subberry анализирует данные локально',
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final insight in metrics.insights) ...<Widget>[
          _InsightCard(insight: insight),
          const SizedBox(height: AppSpacing.sm),
        ],
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
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool horizontal;

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
      padding: const EdgeInsets.all(AppSpacing.md),
      child: horizontal
          ? Row(
              children: <Widget>[
                iconWidget,
                const SizedBox(width: AppSpacing.md),
                Expanded(child: content),
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
        AppColors.education,
      ),
      AnalyticsInsightType.totalSpent => (
        Icons.payments_rounded,
        accent.primary,
      ),
      AnalyticsInsightType.largestCategory => (
        Icons.pie_chart_rounded,
        accent.tertiary,
      ),
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
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
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

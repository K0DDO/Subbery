import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/screen_header.dart';
import '../../subscriptions/application/subscription_providers.dart';
import '../../subscriptions/domain/entities/payment.dart';
import '../../subscriptions/domain/entities/subscription.dart';
import '../../subscriptions/presentation/widgets/service_logo.dart';
import '../application/overview_metrics.dart';
import 'widgets/berry_calendar_ring.dart';
import 'widgets/spending_bar_chart.dart';

class OverviewScreen extends ConsumerStatefulWidget {
  const OverviewScreen({super.key});

  @override
  ConsumerState<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends ConsumerState<OverviewScreen> {
  int _selectedMonth = DateTime.now().month;

  @override
  Widget build(BuildContext context) {
    final subscriptions = ref.watch(subscriptionsProvider);
    final payments = ref.watch(allPaymentsProvider);

    return SafeArea(
      bottom: false,
      child: Column(
        children: <Widget>[
          const ScreenHeader(
            title: 'Привет, Дима 👋',
            subtitle: 'Ваши подписки под контролем',
          ),
          Expanded(
            child: subscriptions.when(
              data: (items) => payments.when(
                data: (paymentItems) => _buildContent(items, paymentItems),
                loading: _LoadingOverview.new,
                error: (error, stackTrace) => const _OverviewError(),
              ),
              loading: _LoadingOverview.new,
              error: (error, stackTrace) => const _OverviewError(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    List<Subscription> subscriptions,
    List<Payment> payments,
  ) {
    if (subscriptions.isEmpty) {
      return EmptyState(
        title: 'Пока нет подписок 🍓',
        description:
            'Добавьте первый сервис,\n'
            'чтобы начать контролировать расходы',
        actionLabel: 'Добавить подписку',
        onAction: () => context.push('/subscriptions/add'),
      );
    }

    final now = DateTime.now();
    final metrics = OverviewMetrics.calculate(
      subscriptions: subscriptions,
      payments: payments,
      now: now,
    );
    final selectedOccurrences = metrics.yearOccurrences
        .where((occurrence) => occurrence.date.month == _selectedMonth)
        .toList(growable: false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        128,
      ),
      children: <Widget>[
        _MonthlySummary(metrics: metrics),
        const SizedBox(height: AppSpacing.lg),
        GlassCard(
          strong: true,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Календарь платежей на ${now.year} год',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.coral.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        '${metrics.yearOccurrences.length}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.coral,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              BerryCalendarRing(
                year: now.year,
                occurrences: metrics.yearOccurrences,
                selectedMonth: _selectedMonth,
                onMonthSelected: (month) {
                  setState(() => _selectedMonth = month);
                },
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  child: _SelectedMonthPayments(
                    key: ValueKey<int>(_selectedMonth),
                    occurrences: selectedOccurrences,
                    onTap: (subscription) {
                      context.push('/subscriptions/${subscription.id}');
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _SectionTitle(
          title: 'Ближайшие платежи',
          subtitle: 'Сначала самые близкие',
          action: TextButton(
            onPressed: () => context.go('/subscriptions'),
            child: const Text('Все'),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final occurrence in metrics.upcomingPayments.take(4)) ...<Widget>[
          _UpcomingPaymentCard(
            occurrence: occurrence,
            onTap: () {
              context.push('/subscriptions/${occurrence.subscription.id}');
            },
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.sm),
        const _SectionTitle(
          title: 'Расходы за 6 месяцев',
          subtitle: 'Фактические платежи',
        ),
        const SizedBox(height: AppSpacing.sm),
        GlassCard(child: SpendingBarChart(points: metrics.spendingByMonth)),
      ],
    );
  }
}

class _MonthlySummary extends StatelessWidget {
  const _MonthlySummary({required this.metrics});

  final OverviewMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final next = metrics.upcomingPayments.firstOrNull;

    return GlassCard(
      strong: true,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'В этом месяце',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            AppFormatters.money(metrics.monthlyRecurringInCents),
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: <Widget>[
              Expanded(
                child: _SummaryCaption(
                  label: 'В среднем',
                  value:
                      '${AppFormatters.money(metrics.averageMonthlyInCents)} / мес',
                ),
              ),
              if (next != null) ...<Widget>[
                Container(
                  width: 1,
                  height: 38,
                  color: Theme.of(context).dividerColor,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _SummaryCaption(
                    label: 'Следующий',
                    value:
                        '${next.subscription.name} · '
                        '${AppFormatters.shortDate(next.date)}',
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCaption extends StatelessWidget {
  const _SummaryCaption({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _SelectedMonthPayments extends StatelessWidget {
  const _SelectedMonthPayments({
    required this.occurrences,
    required this.onTap,
    super.key,
  });

  final List<PaymentOccurrence> occurrences;
  final ValueChanged<Subscription> onTap;

  @override
  Widget build(BuildContext context) {
    if (occurrences.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Center(
          child: Text(
            'В этом месяце списаний нет',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Column(
      children: <Widget>[
        for (final occurrence in occurrences.take(3))
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
            ),
            leading: ServiceLogo(
              name: occurrence.subscription.name,
              logoKey: occurrence.subscription.logo,
              category: occurrence.subscription.category,
              size: 40,
            ),
            title: Text(occurrence.subscription.name),
            subtitle: Text(AppFormatters.shortDate(occurrence.date)),
            trailing: Text(
              AppFormatters.money(occurrence.subscription.priceInCents),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            onTap: () => onTap(occurrence.subscription),
          ),
        if (occurrences.length > 3)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(
              'Ещё ${occurrences.length - 3}',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: AppColors.coral),
            ),
          ),
      ],
    );
  }
}

class _UpcomingPaymentCard extends StatelessWidget {
  const _UpcomingPaymentCard({required this.occurrence, required this.onTap});

  final PaymentOccurrence occurrence;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subscription = occurrence.subscription;

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: <Widget>[
          ServiceLogo(
            name: subscription.name,
            logoKey: subscription.logo,
            category: subscription.category,
            size: 52,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  subscription.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  AppFormatters.shortDate(occurrence.date),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            AppFormatters.money(subscription.priceInCents),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(width: AppSpacing.xs),
          const Icon(Icons.chevron_right_rounded, size: 20),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
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
          ),
        ),
        ?action,
      ],
    );
  }
}

class _LoadingOverview extends StatelessWidget {
  const _LoadingOverview();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _OverviewError extends StatelessWidget {
  const _OverviewError();

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      title: 'Не удалось собрать обзор',
      description: 'Данные остались в безопасности на устройстве',
      icon: Icons.sync_problem_rounded,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/money_text.dart';
import '../application/subscription_providers.dart';
import '../domain/entities/subscription.dart';
import '../domain/subscription_schedule.dart';
import 'subscription_ui_extensions.dart';
import 'widgets/service_logo.dart';

class SubscriptionPaymentScheduleScreen extends ConsumerWidget {
  const SubscriptionPaymentScheduleScreen({
    required this.subscriptionId,
    super.key,
  });

  final String subscriptionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(subscriptionProvider(subscriptionId));
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('График платежей'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: AppBackground(
        child: subscription.when(
          data: (value) => value == null
              ? const EmptyState(
                  title: 'Подписка не найдена',
                  description: 'Возможно, она уже была удалена',
                  icon: Icons.event_busy_rounded,
                )
              : _ScheduleContent(subscription: value),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => const EmptyState(
            title: 'Не удалось загрузить график',
            description: 'Попробуйте открыть его ещё раз',
            icon: Icons.error_outline_rounded,
          ),
        ),
      ),
    );
  }
}

class _ScheduleContent extends StatelessWidget {
  const _ScheduleContent({required this.subscription});

  final Subscription subscription;

  @override
  Widget build(BuildContext context) {
    final dates =
        subscription.renewalMode == RenewalMode.manual &&
            subscription.status != SubscriptionStatus.active
        ? const <DateTime>[]
        : SubscriptionSchedule.upcomingDates(
            subscription,
            DateTime.now(),
            count: switch (subscription.billingCycle) {
              BillingCycle.monthly => 12,
              BillingCycle.quarterly => 8,
              BillingCycle.semiannual => 6,
              BillingCycle.yearly => 5,
              BillingCycle.biennial => 4,
              BillingCycle.custom => 12,
            },
          );
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: <Widget>[
          GlassCard(
            strong: true,
            child: Row(
              children: <Widget>[
                ServiceLogo(
                  name: subscription.name,
                  logoKey: subscription.logo,
                  category: subscription.category,
                  size: 58,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        subscription.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          MoneyText(
                            cents: subscription.priceInCents,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          Text(
                            subscription.renewalMode == RenewalMode.manual
                                ? ' · единично'
                                : ' / ${subscription.billingCycle.periodLabel(customIntervalDays: subscription.customIntervalDays)}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            subscription.renewalMode == RenewalMode.manual
                ? 'Запланированная оплата'
                : 'Предстоящие платежи',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: dates.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Text(
                      'Новая оплата пока не запланирована. '
                      'Возобновите подписку, когда она снова понадобится.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : Column(
                    children: <Widget>[
                      for (var index = 0; index < dates.length; index++)
                        _ScheduleRow(
                          date: dates[index],
                          amountInCents: subscription.priceInCents,
                          isFirst: index == 0,
                          isLast: index == dates.length - 1,
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({
    required this.date,
    required this.amountInCents,
    required this.isFirst,
    required this.isLast,
  });

  final DateTime date;
  final int amountInCents;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      children: <Widget>[
        SizedBox(
          width: 28,
          height: 72,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Positioned(
                top: isFirst ? 36 : 0,
                bottom: isLast ? 36 : 0,
                child: Container(width: 2, color: primary),
              ),
              Container(
                width: isFirst ? 14 : 10,
                height: isFirst ? 14 : 10,
                decoration: BoxDecoration(
                  color: isFirst
                      ? primary
                      : Theme.of(context).colorScheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: primary, width: 2),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  isFirst ? 'Ближайший платёж' : 'Следующий платёж',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isFirst
                        ? primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppFormatters.fullDate(date),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 108),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: MoneyText(
              cents: amountInCents,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      ],
    );
  }
}

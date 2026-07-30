import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/screen_header.dart';
import '../../shell/application/tab_reset_provider.dart';
import '../application/subscription_providers.dart';
import '../domain/entities/subscription.dart';
import 'subscription_ui_extensions.dart';
import 'widgets/service_logo.dart';

enum SubscriptionListFilter { all, upcoming, yearly }

final subscriptionListFilterProvider = StateProvider<SubscriptionListFilter>(
  (ref) => SubscriptionListFilter.all,
);

List<Subscription> filterSubscriptions(
  List<Subscription> subscriptions,
  SubscriptionListFilter filter, {
  SubscriptionCategory? category,
  DateTime? now,
}) {
  final today = now ?? DateTime.now();
  final upcomingLimit = today.add(const Duration(days: 30));

  return subscriptions
      .where((subscription) {
        if (category != null && subscription.category != category) {
          return false;
        }
        return switch (filter) {
          SubscriptionListFilter.all => true,
          SubscriptionListFilter.upcoming =>
            subscription.status == SubscriptionStatus.active &&
                !subscription.nextPaymentDate.isBefore(today) &&
                subscription.nextPaymentDate.isBefore(upcomingLimit),
          SubscriptionListFilter.yearly =>
            subscription.billingCycle == BillingCycle.yearly,
        };
      })
      .toList(growable: false);
}

class SubscriptionsScreen extends ConsumerWidget {
  const SubscriptionsScreen({this.initialCategory, super.key});

  final SubscriptionCategory? initialCategory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptions = ref.watch(subscriptionsProvider);
    final selectedFilter = ref.watch(subscriptionListFilterProvider);
    final resetRevision = ref.watch(tabResetRevisionProvider(1));

    return SafeArea(
      bottom: false,
      child: Column(
        children: <Widget>[
          ScreenHeader(
            title: 'Подписки',
            subtitle: initialCategory == null
                ? 'Все сервисы в одном месте'
                : 'Категория: ${initialCategory!.label}',
            trailing: IconButton.filled(
              tooltip: 'Добавить подписку',
              onPressed: () => context.push('/subscriptions/add'),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.coral,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.add_rounded),
            ),
          ),
          _FilterBar(
            selected: selectedFilter,
            category: initialCategory,
            onSelected: (filter) {
              ref.read(subscriptionListFilterProvider.notifier).state = filter;
            },
            onCategorySelected: (category) {
              context.goNamed(
                'subscriptions',
                queryParameters: category == null
                    ? const <String, String>{}
                    : <String, String>{'category': category.name},
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: subscriptions.when(
              data: (items) {
                if (items.isEmpty) {
                  return EmptyState(
                    title: 'Пока нет подписок 🍓',
                    description:
                        'Добавьте первый сервис,\n'
                        'чтобы начать контролировать расходы',
                    actionLabel: 'Добавить подписку',
                    onAction: () => context.push('/subscriptions/add'),
                  );
                }

                final filtered = filterSubscriptions(
                  items,
                  selectedFilter,
                  category: initialCategory,
                );
                if (filtered.isEmpty) {
                  return const EmptyState(
                    title: 'Ничего не найдено',
                    description: 'В этой подборке пока нет подписок',
                    icon: Icons.filter_alt_off_rounded,
                  );
                }

                return ListView.separated(
                  key: ValueKey<String>('subscriptions-$resetRevision'),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.xs,
                    AppSpacing.lg,
                    128,
                  ),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final subscription = filtered[index];
                    return _SubscriptionCard(
                      subscription: subscription,
                      animationIndex: index,
                      onTap: () {
                        context.push('/subscriptions/${subscription.id}');
                      },
                    );
                  },
                );
              },
              loading: _SubscriptionsLoading.new,
              error: (error, stackTrace) => _SubscriptionsError(
                onRetry: () => ref.invalidate(subscriptionsProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryFilterButton extends StatelessWidget {
  const _CategoryFilterButton({
    required this.selected,
    required this.onSelected,
  });

  final SubscriptionCategory? selected;
  final ValueChanged<SubscriptionCategory?> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Фильтр по категории',
      padding: EdgeInsets.zero,
      initialValue: selected?.name,
      onSelected: (value) {
        SubscriptionCategory? category;
        for (final item in SubscriptionCategory.values) {
          if (item.name == value) category = item;
        }
        onSelected(category);
      },
      itemBuilder: (context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: '',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.apps_rounded),
            title: Text('Все категории'),
          ),
        ),
        for (final category in SubscriptionCategory.values)
          PopupMenuItem<String>(
            value: category.name,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Text(category.emoji),
              title: Text(category.label),
            ),
          ),
      ],
      icon: Badge(
        isLabelVisible: selected != null,
        smallSize: 8,
        child: Icon(
          selected == null
              ? Icons.filter_alt_outlined
              : Icons.filter_alt_rounded,
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.selected,
    required this.category,
    required this.onSelected,
    required this.onCategorySelected,
  });

  final SubscriptionListFilter selected;
  final SubscriptionCategory? category;
  final ValueChanged<SubscriptionListFilter> onSelected;
  final ValueChanged<SubscriptionCategory?> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        children: <Widget>[
          _FilterChip(
            label: 'Все',
            selected: selected == SubscriptionListFilter.all,
            onTap: () => onSelected(SubscriptionListFilter.all),
          ),
          const SizedBox(width: AppSpacing.xs),
          _FilterChip(
            label: 'Скоро',
            selected: selected == SubscriptionListFilter.upcoming,
            onTap: () => onSelected(SubscriptionListFilter.upcoming),
          ),
          const SizedBox(width: AppSpacing.xs),
          _FilterChip(
            label: 'Годовые',
            selected: selected == SubscriptionListFilter.yearly,
            onTap: () => onSelected(SubscriptionListFilter.yearly),
          ),
          const SizedBox(width: AppSpacing.xs),
          _CategoryFilterButton(
            selected: category,
            onSelected: onCategorySelected,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        gradient: selected ? AppColors.brandGradient : null,
        color: selected
            ? null
            : Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        border: Border.all(
          color: selected ? Colors.white30 : Theme.of(context).dividerColor,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? Colors.white : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({
    required this.subscription,
    required this.animationIndex,
    required this.onTap,
  });

  final Subscription subscription;
  final int animationIndex;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isActive = subscription.status == SubscriptionStatus.active;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + animationIndex.clamp(0, 5) * 55),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - value)),
            child: child,
          ),
        );
      },
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: <Widget>[
            Hero(
              tag: 'subscription-logo-${subscription.id}',
              child: ServiceLogo(
                name: subscription.name,
                logoKey: subscription.logo,
                category: subscription.category,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          subscription.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive
                              ? const Color(0xFF63C987)
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Следующее списание',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    AppFormatters.shortDate(subscription.nextPaymentDate),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  AppFormatters.money(subscription.priceInCents),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  subscription.renewalMode == RenewalMode.manual
                      ? 'единично'
                      : '/ ${subscription.billingCycle.shortLabel}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.xxs),
            const Icon(Icons.chevron_right_rounded, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionsLoading extends StatelessWidget {
  const _SubscriptionsLoading();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        128,
      ),
      itemCount: 3,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        return const GlassCard(
          child: SizedBox(
            height: 56,
            child: Center(child: LinearProgressIndicator()),
          ),
        );
      },
    );
  }
}

class _SubscriptionsError extends StatelessWidget {
  const _SubscriptionsError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.cloud_off_rounded, size: 42),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Не удалось загрузить подписки',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            GlassButton(
              label: 'Попробовать снова',
              expanded: false,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

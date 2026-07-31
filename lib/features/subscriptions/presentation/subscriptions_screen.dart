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
import '../domain/subscription_schedule.dart';
import 'subscription_ui_extensions.dart';
import 'widgets/service_logo.dart';

enum SubscriptionListFilter { all, upcoming, yearly }

class SubscriptionFilterState {
  const SubscriptionFilterState({
    this.quick = SubscriptionListFilter.all,
    this.categories = const <SubscriptionCategory>{},
    this.statuses = const <SubscriptionStatus>{},
  });

  final SubscriptionListFilter quick;
  final Set<SubscriptionCategory> categories;
  final Set<SubscriptionStatus> statuses;

  bool get hasAdvancedFilters =>
      categories.isNotEmpty || statuses.isNotEmpty;

  SubscriptionFilterState copyWith({
    SubscriptionListFilter? quick,
    Set<SubscriptionCategory>? categories,
    Set<SubscriptionStatus>? statuses,
  }) {
    return SubscriptionFilterState(
      quick: quick ?? this.quick,
      categories: categories ?? this.categories,
      statuses: statuses ?? this.statuses,
    );
  }
}

final subscriptionFilterProvider =
    StateProvider<SubscriptionFilterState>((ref) => const SubscriptionFilterState());

List<Subscription> filterSubscriptions(
  List<Subscription> subscriptions,
  SubscriptionListFilter filter, {
  SubscriptionCategory? category,
  Set<SubscriptionCategory> categories = const <SubscriptionCategory>{},
  Set<SubscriptionStatus> statuses = const <SubscriptionStatus>{},
  DateTime? now,
}) {
  final today = SubscriptionSchedule.dateOnly(now ?? DateTime.now());
  final upcomingLimit = today.add(const Duration(days: 30));
  final selectedCategories = categories.isNotEmpty
      ? categories
      : (category == null
            ? const <SubscriptionCategory>{}
            : <SubscriptionCategory>{category});

  return subscriptions
      .where((subscription) {
        if (selectedCategories.isNotEmpty &&
            !selectedCategories.contains(subscription.category)) {
          return false;
        }
        if (statuses.isNotEmpty && !statuses.contains(subscription.status)) {
          return false;
        }
        return switch (filter) {
          SubscriptionListFilter.all => true,
          SubscriptionListFilter.upcoming =>
            subscription.status == SubscriptionStatus.active &&
                !subscription.nextPaymentDate.isBefore(today) &&
                subscription.nextPaymentDate.isBefore(upcomingLimit) &&
                !(subscription.renewalMode == RenewalMode.manual &&
                    subscription.nextPaymentDate.isBefore(today)),
          SubscriptionListFilter.yearly =>
            subscription.billingCycle == BillingCycle.yearly ||
                subscription.billingCycle == BillingCycle.biennial,
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
    final filterState = ref.watch(subscriptionFilterProvider);
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
            state: filterState,
            routeCategory: initialCategory,
            onQuickSelected: (filter) {
              ref.read(subscriptionFilterProvider.notifier).state =
                  filterState.copyWith(quick: filter);
            },
            onAdvancedChanged: (next) {
              ref.read(subscriptionFilterProvider.notifier).state = next;
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
                  filterState.quick,
                  category: initialCategory,
                  categories: filterState.categories,
                  statuses: filterState.statuses,
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

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.state,
    required this.routeCategory,
    required this.onQuickSelected,
    required this.onAdvancedChanged,
  });

  final SubscriptionFilterState state;
  final SubscriptionCategory? routeCategory;
  final ValueChanged<SubscriptionListFilter> onQuickSelected;
  final ValueChanged<SubscriptionFilterState> onAdvancedChanged;

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
            selected: state.quick == SubscriptionListFilter.all,
            onTap: () => onQuickSelected(SubscriptionListFilter.all),
          ),
          const SizedBox(width: AppSpacing.xs),
          _FilterChip(
            label: 'Скоро',
            selected: state.quick == SubscriptionListFilter.upcoming,
            onTap: () => onQuickSelected(SubscriptionListFilter.upcoming),
          ),
          const SizedBox(width: AppSpacing.xs),
          _FilterChip(
            label: 'Годовые',
            selected: state.quick == SubscriptionListFilter.yearly,
            onTap: () => onQuickSelected(SubscriptionListFilter.yearly),
          ),
          const SizedBox(width: AppSpacing.xs),
          _AdvancedFilterButton(
            state: state,
            routeCategory: routeCategory,
            onChanged: onAdvancedChanged,
          ),
        ],
      ),
    );
  }
}

class _AdvancedFilterButton extends StatelessWidget {
  const _AdvancedFilterButton({
    required this.state,
    required this.routeCategory,
    required this.onChanged,
  });

  final SubscriptionFilterState state;
  final SubscriptionCategory? routeCategory;
  final ValueChanged<SubscriptionFilterState> onChanged;

  @override
  Widget build(BuildContext context) {
    final active =
        state.hasAdvancedFilters || routeCategory != null;
    return IconButton(
      tooltip: 'Фильтры',
      onPressed: () async {
        final next = await showModalBottomSheet<SubscriptionFilterState>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (context) => _FilterSheet(initial: state),
        );
        if (next != null) onChanged(next);
      },
      icon: Badge(
        isLabelVisible: active,
        smallSize: 8,
        child: Icon(
          active ? Icons.filter_alt_rounded : Icons.filter_alt_outlined,
        ),
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial});

  final SubscriptionFilterState initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late Set<SubscriptionCategory> _categories;
  late Set<SubscriptionStatus> _statuses;

  @override
  void initState() {
    super.initState();
    _categories = {...widget.initial.categories};
    _statuses = {...widget.initial.statuses};
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Фильтры', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            Text('Категории', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: <Widget>[
                for (final category in SubscriptionCategory.values)
                  FilterChip(
                    label: Text('${category.emoji} ${category.label}'),
                    selected: _categories.contains(category),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _categories.add(category);
                        } else {
                          _categories.remove(category);
                        }
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Статус', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: <Widget>[
                for (final status in const <SubscriptionStatus>[
                  SubscriptionStatus.active,
                  SubscriptionStatus.paused,
                  SubscriptionStatus.cancelled,
                  SubscriptionStatus.expired,
                ])
                  FilterChip(
                    label: Text(status.label),
                    selected: _statuses.contains(status),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _statuses.add(status);
                        } else {
                          _statuses.remove(status);
                        }
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: <Widget>[
                TextButton(
                  onPressed: () {
                    setState(() {
                      _categories.clear();
                      _statuses.clear();
                    });
                  },
                  child: const Text('Сбросить'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      widget.initial.copyWith(
                        categories: _categories,
                        statuses: _statuses,
                      ),
                    );
                  },
                  child: const Text('Готово'),
                ),
              ],
            ),
          ],
        ),
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

  Color get _statusDotColor {
    return switch (subscription.status) {
      SubscriptionStatus.active => const Color(0xFF63C987),
      SubscriptionStatus.paused => const Color(0xFFF0C14E),
      SubscriptionStatus.cancelled => const Color(0xFFE57373),
      SubscriptionStatus.expired => const Color(0xFF9E9E9E),
    };
  }

  @override
  Widget build(BuildContext context) {
    final today = SubscriptionSchedule.dateOnly(DateTime.now());
    final isPastOneTime =
        subscription.renewalMode == RenewalMode.manual &&
        subscription.nextPaymentDate.isBefore(today);

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
        child: Row(
          children: <Widget>[
            ServiceLogo(
              name: subscription.name,
              logoKey: subscription.logo,
              category: subscription.category,
              size: 48,
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
                          color: _statusDotColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    isPastOneTime ? 'Дата оплаты' : 'Следующее списание',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    isPastOneTime
                        ? '${AppFormatters.shortDate(subscription.nextPaymentDate)} · прошло'
                        : AppFormatters.shortDate(subscription.nextPaymentDate),
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
                      : '/ ${subscription.billingCycle.periodLabel(customIntervalDays: subscription.customIntervalDays)}',
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
              label: 'Повторить',
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

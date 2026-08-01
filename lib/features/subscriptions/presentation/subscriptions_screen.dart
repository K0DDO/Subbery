import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_accent_theme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../widgets/morphing_sheet/morphing_glass_sheet.dart';
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
    this.oneTime = false,
  });

  final SubscriptionListFilter quick;
  final Set<SubscriptionCategory> categories;
  final Set<SubscriptionStatus> statuses;
  final bool oneTime;

  bool get hasAdvancedFilters =>
      categories.isNotEmpty || statuses.isNotEmpty || oneTime;

  SubscriptionFilterState copyWith({
    SubscriptionListFilter? quick,
    Set<SubscriptionCategory>? categories,
    Set<SubscriptionStatus>? statuses,
    bool? oneTime,
  }) {
    return SubscriptionFilterState(
      quick: quick ?? this.quick,
      categories: categories ?? this.categories,
      statuses: statuses ?? this.statuses,
      oneTime: oneTime ?? this.oneTime,
    );
  }
}

final subscriptionFilterProvider = StateProvider<SubscriptionFilterState>(
  (ref) => const SubscriptionFilterState(),
);

List<Subscription> filterSubscriptions(
  List<Subscription> subscriptions,
  SubscriptionListFilter filter, {
  SubscriptionCategory? category,
  Set<SubscriptionCategory> categories = const <SubscriptionCategory>{},
  Set<SubscriptionStatus> statuses = const <SubscriptionStatus>{},
  bool oneTime = false,
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
        if (statuses.isNotEmpty || oneTime) {
          final matchesStatus = statuses.contains(subscription.status);
          final matchesOneTime =
              oneTime && subscription.renewalMode == RenewalMode.manual;
          if (!matchesStatus && !matchesOneTime) return false;
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
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.add_rounded),
            ),
          ),
          _FilterBar(
            state: filterState,
            routeCategory: initialCategory,
            onQuickSelected: (filter) {
              ref.read(subscriptionFilterProvider.notifier).state = filterState
                  .copyWith(quick: filter);
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
                  oneTime: filterState.oneTime,
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

class _AdvancedFilterButton extends StatefulWidget {
  const _AdvancedFilterButton({
    required this.state,
    required this.routeCategory,
    required this.onChanged,
  });

  final SubscriptionFilterState state;
  final SubscriptionCategory? routeCategory;
  final ValueChanged<SubscriptionFilterState> onChanged;

  @override
  State<_AdvancedFilterButton> createState() => _AdvancedFilterButtonState();
}

class _AdvancedFilterButtonState extends State<_AdvancedFilterButton> {
  final _buttonKey = GlobalKey();

  Future<void> _openFilters() async {
    final renderBox =
        _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final origin = renderBox.localToGlobal(Offset.zero);
    final anchor = origin & renderBox.size;
    final next = await showSubscriptionFilterSheet(
      context: context,
      startRect: anchor,
      initial: widget.state,
    );
    if (next != null) widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final active =
        widget.state.hasAdvancedFilters || widget.routeCategory != null;
    return IconButton(
      key: _buttonKey,
      tooltip: 'Фильтры',
      onPressed: _openFilters,
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

Future<SubscriptionFilterState?> showSubscriptionFilterSheet({
  required BuildContext context,
  required Rect startRect,
  required SubscriptionFilterState initial,
}) {
  final media = MediaQuery.of(context);
  return MorphingGlassSheet.show<SubscriptionFilterState>(
    context: context,
    startRect: startRect,
    endPosition: Offset(AppSpacing.md, media.padding.top + 72),
    maximumHeight: math.min(660, media.size.height * 0.82),
    source: Material(
      type: MaterialType.transparency,
      child: Center(
        child: Icon(
          Icons.filter_alt_rounded,
          color: context.subberryTheme.primary,
        ),
      ),
    ),
    builder: (_) => SubscriptionFilterSheet(initial: initial),
  );
}

class SubscriptionFilterSheet extends StatefulWidget {
  const SubscriptionFilterSheet({required this.initial, super.key});

  final SubscriptionFilterState initial;

  @override
  State<SubscriptionFilterSheet> createState() =>
      _SubscriptionFilterSheetState();
}

class _SubscriptionFilterSheetState extends State<SubscriptionFilterSheet> {
  late Set<SubscriptionCategory> _categories;
  late Set<SubscriptionStatus> _statuses;
  late bool _oneTime;

  @override
  void initState() {
    super.initState();
    _categories = {...widget.initial.categories};
    _statuses = {...widget.initial.statuses};
    _oneTime = widget.initial.oneTime;
  }

  void _toggleCategory(SubscriptionCategory category, bool selected) {
    setState(() {
      selected ? _categories.add(category) : _categories.remove(category);
    });
  }

  void _toggleStatus(SubscriptionStatus status, bool selected) {
    setState(() {
      selected ? _statuses.add(status) : _statuses.remove(status);
    });
  }

  void _reset() {
    setState(() {
      _categories.clear();
      _statuses.clear();
      _oneTime = false;
    });
  }

  void _done() {
    Navigator.pop(
      context,
      widget.initial.copyWith(
        categories: _categories,
        statuses: _statuses,
        oneTime: _oneTime,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      type: MaterialType.transparency,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          52,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Фильтры',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Категории', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: <Widget>[
                for (final category in SubscriptionCategory.values)
                  _GlassSelectionChip(
                    key: ValueKey<String>(
                      'subscription-filter-category-${category.name}',
                    ),
                    label: '${category.emoji} ${category.label}',
                    selected: _categories.contains(category),
                    onSelected: (selected) =>
                        _toggleCategory(category, selected),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Статус', style: theme.textTheme.titleSmall),
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
                  _GlassSelectionChip(
                    key: ValueKey<String>(
                      'subscription-filter-status-${status.name}',
                    ),
                    label: status.label,
                    selected: _statuses.contains(status),
                    onSelected: (selected) => _toggleStatus(status, selected),
                  ),
                _GlassSelectionChip(
                  key: const ValueKey<String>(
                    'subscription-filter-status-one-time',
                  ),
                  label: 'Единовременная',
                  selected: _oneTime,
                  onSelected: (selected) => setState(() => _oneTime = selected),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: <Widget>[
                TextButton(
                  key: const ValueKey<String>('subscription-filter-reset'),
                  onPressed: _reset,
                  child: const Text('Сбросить'),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: GlassButton(
                    key: const ValueKey<String>('subscription-filter-done'),
                    label: 'Готово',
                    icon: Icons.check_rounded,
                    onPressed: _done,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassSelectionChip extends StatelessWidget {
  const _GlassSelectionChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subberry = context.subberryTheme;
    return Semantics(
      button: true,
      selected: selected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          color: selected
              ? subberry.primary.withValues(alpha: 0.2)
              : subberry.glassTint.withValues(alpha: 0.42),
          border: Border.all(
            color: selected ? subberry.primary : subberry.borderColor,
          ),
          boxShadow: selected
              ? <BoxShadow>[
                  BoxShadow(
                    color: subberry.glowColor.withValues(alpha: 0.34),
                    blurRadius: 14,
                  ),
                ]
              : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            onTap: () => onSelected(!selected),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: selected
                      ? subberry.primary
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          ),
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
    final accent = context.accentTheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        gradient: selected ? accent.gradient : null,
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

  Color _statusDotColor(BuildContext context) {
    final palette = context.subberryTheme;
    return switch (subscription.status) {
      SubscriptionStatus.active => palette.success,
      SubscriptionStatus.paused => palette.warning,
      SubscriptionStatus.cancelled => palette.error,
      SubscriptionStatus.expired => palette.mutedTextColor,
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
                          color: _statusDotColor(context),
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
            GlassButton(label: 'Повторить', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}

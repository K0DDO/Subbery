import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../core/widgets/app_background.dart';
import '../../subscriptions/presentation/subscriptions_screen.dart';
import '../application/tab_reset_provider.dart';

class AppShell extends ConsumerWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  void _openBranch(WidgetRef ref, int index) {
    unawaited(HapticFeedback.selectionClick());
    ref.read(subscriptionListFilterProvider.notifier).state =
        SubscriptionListFilter.all;
    ref.read(tabResetRevisionProvider(index).notifier).state++;
    navigationShell.goBranch(index, initialLocation: true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: AppBackground(
        child: Stack(
          children: <Widget>[
            Positioned.fill(child: navigationShell),
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.sm,
              child: _GlassNavigationBar(
                currentIndex: navigationShell.currentIndex,
                onSelected: (index) => _openBranch(ref, index),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassNavigationBar extends StatelessWidget {
  const _GlassNavigationBar({
    required this.currentIndex,
    required this.onSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;

  static const _items = <_NavigationItem>[
    _NavigationItem('Обзор', Icons.space_dashboard_rounded),
    _NavigationItem('Подписки', Icons.layers_rounded),
    _NavigationItem('Аналитика', Icons.auto_graph_rounded),
    _NavigationItem('Настройки', Icons.tune_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<GlassTheme>()!;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: glass.shadow,
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: glass.blur, sigmaY: glass.blur),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: glass.strongSurface,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: glass.border),
                ),
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final itemWidth = constraints.maxWidth / _items.length;

                    return Stack(
                      children: <Widget>[
                        AnimatedPositioned(
                          left: currentIndex * itemWidth + 4,
                          top: 4,
                          bottom: 4,
                          width: itemWidth - 8,
                          duration: const Duration(milliseconds: 360),
                          curve: Curves.easeOutBack,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: AppColors.brandGradient,
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: AppColors.coral.withValues(alpha: 0.3),
                                  blurRadius: 18,
                                  offset: const Offset(0, 7),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Row(
                          children: <Widget>[
                            for (var index = 0; index < _items.length; index++)
                              Expanded(
                                child: _NavigationButton(
                                  item: _items[index],
                                  selected: currentIndex == index,
                                  onTap: () => onSelected(index),
                                ),
                              ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationButton extends StatelessWidget {
  const _NavigationButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavigationItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Colors.white
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Semantics(
      selected: selected,
      button: true,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            AnimatedScale(
              scale: selected ? 1.08 : 1,
              duration: const Duration(milliseconds: 240),
              child: Icon(item.icon, color: color, size: 23),
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              maxLines: 1,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationItem {
  const _NavigationItem(this.label, this.icon);

  final String label;
  final IconData icon;
}

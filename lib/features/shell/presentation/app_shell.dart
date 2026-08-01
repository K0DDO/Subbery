import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_accent_theme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../core/widgets/app_background.dart';
import '../../settings/application/privacy_settings_controller.dart';
import '../../subscriptions/presentation/subscriptions_screen.dart';
import '../application/tab_reset_provider.dart';

abstract final class AppShellHotbar {
  static final GlobalKey key = GlobalKey(debugLabel: 'app-shell-hotbar');
  static final ValueNotifier<bool> visible = ValueNotifier<bool>(true);
  static int _hiddenRoutes = 0;
  static int currentIndex = 0;

  static Rect? currentRect() {
    final context = key.currentContext;
    if (context == null) return null;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final origin = box.localToGlobal(Offset.zero);
    return origin & box.size;
  }

  static Rect fallbackRect(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    const height = 72.0;
    return Rect.fromLTWH(
      AppSpacing.md,
      size.height - padding.bottom - AppSpacing.sm - height,
      size.width - AppSpacing.md * 2,
      height,
    );
  }

  static void hide() {
    _hiddenRoutes++;
    visible.value = false;
  }

  static void show() {
    _hiddenRoutes = (_hiddenRoutes - 1).clamp(0, 999);
    if (_hiddenRoutes == 0) visible.value = true;
  }
}

class AppShell extends ConsumerWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  void _openBranch(WidgetRef ref, int index) {
    unawaited(HapticFeedback.selectionClick());
    ref.read(subscriptionFilterProvider.notifier).state =
        const SubscriptionFilterState();
    ref.read(moneyRevealEpochProvider.notifier).hideAll();
    ref.read(tabResetRevisionProvider(index).notifier).state++;
    navigationShell.goBranch(index, initialLocation: true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AppShellHotbar.currentIndex = navigationShell.currentIndex;
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: AppBackground(
        child: Stack(
          children: <Widget>[
            Positioned.fill(child: navigationShell),
            ValueListenableBuilder<bool>(
              valueListenable: AppShellHotbar.visible,
              builder: (context, visible, child) => Positioned(
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.sm,
                child: IgnorePointer(
                  ignoring: !visible,
                  child: Opacity(opacity: visible ? 1 : 0, child: child),
                ),
              ),
              child: KeyedSubtree(
                key: AppShellHotbar.key,
                child: _GlassNavigationBar(
                  currentIndex: navigationShell.currentIndex,
                  onSelected: (index) => _openBranch(ref, index),
                ),
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
                child: AppHotbarContents(
                  currentIndex: currentIndex,
                  onSelected: onSelected,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppHotbarContents extends StatelessWidget {
  const AppHotbarContents({
    required this.currentIndex,
    required this.onSelected,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final accent = context.accentTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth =
            constraints.maxWidth / _GlassNavigationBar._items.length;
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
                  gradient: accent.gradient,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: accent.primary.withValues(alpha: 0.3),
                      blurRadius: 18,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: <Widget>[
                for (
                  var index = 0;
                  index < _GlassNavigationBar._items.length;
                  index++
                )
                  Expanded(
                    child: _NavigationButton(
                      item: _GlassNavigationBar._items[index],
                      selected: currentIndex == index,
                      onTap: () => onSelected(index),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
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

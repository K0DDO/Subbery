import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/glass_theme.dart';
import 'app_shell.dart';

Future<T?> showHotbarMorphSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) async {
  final origin =
      AppShellHotbar.currentRect() ?? AppShellHotbar.fallbackRect(context);
  AppShellHotbar.hide();
  try {
    return await Navigator.of(
      context,
      rootNavigator: true,
    ).push<T>(_HotbarMorphRoute<T>(origin: origin, builder: builder));
  } finally {
    AppShellHotbar.show();
  }
}

class _HotbarMorphRoute<T> extends PopupRoute<T> {
  _HotbarMorphRoute({required this.origin, required this.builder});

  final Rect origin;
  final WidgetBuilder builder;

  @override
  Color? get barrierColor => Colors.black.withValues(alpha: 0.42);

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => 'Закрыть';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 520);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 380);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return AnimatedBuilder(
      animation: curved,
      builder: (context, _) {
        final t = curved.value;
        final size = MediaQuery.sizeOf(context);
        final padding = MediaQuery.paddingOf(context);
        final end = Rect.fromLTRB(
          AppSpacing.md,
          padding.top + AppSpacing.lg,
          size.width - AppSpacing.md,
          size.height - AppSpacing.md,
        );
        // Keep the bottom edge anchored so the bar grows upward.
        final bottom = origin.bottom;
        final top = lerpDouble(origin.top, end.top, t)!;
        final left = lerpDouble(origin.left, end.left, t)!;
        final right = lerpDouble(origin.right, end.right, t)!;
        final height = (bottom - top).clamp(origin.height, size.height);
        final rect = Rect.fromLTRB(left, bottom - height, right, bottom);
        final radius = lerpDouble(AppRadius.pill, AppRadius.lg, t)!;
        final navOpacity = (1 - t / 0.32).clamp(0.0, 1.0);
        final contentOpacity = ((t - 0.22) / 0.42).clamp(0.0, 1.0);
        final glass = Theme.of(context).extension<GlassTheme>()!;

        return Stack(
          children: <Widget>[
            Positioned(
              left: rect.left,
              top: rect.top,
              width: rect.width,
              height: rect.height,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: glass.blur,
                    sigmaY: glass.blur,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: glass.strongSurface,
                      borderRadius: BorderRadius.circular(radius),
                      border: Border.all(color: glass.border),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: glass.shadow,
                          blurRadius: 28 + 10 * t,
                          offset: Offset(0, 14 - 4 * t),
                        ),
                      ],
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        IgnorePointer(
                          child: Opacity(
                            opacity: navOpacity,
                            child: const _MorphingHotbarGhost(),
                          ),
                        ),
                        Opacity(
                          opacity: contentOpacity,
                          child: Material(
                            type: MaterialType.transparency,
                            child: child,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MorphingHotbarGhost extends StatelessWidget {
  const _MorphingHotbarGhost();

  static const _items = <(String, IconData)>[
    ('Обзор', Icons.space_dashboard_rounded),
    ('Подписки', Icons.layers_rounded),
    ('Аналитика', Icons.auto_graph_rounded),
    ('Настройки', Icons.tune_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        height: 72,
        child: Row(
          children: <Widget>[
            for (final item in _items)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(item.$2, color: muted, size: 23),
                    const SizedBox(height: 3),
                    Text(
                      item.$1,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

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

  void updateFromDrag(double delta, double travel) {
    final animationController = controller;
    if (animationController == null) return;
    animationController.stop();
    final distance = travel.clamp(160.0, 900.0);
    animationController.value = (animationController.value - delta / distance)
        .clamp(0.0, 1.0);
  }

  void endDrag(double velocity) {
    final animationController = controller;
    if (animationController == null) return;
    if (velocity > 650 ||
        (velocity >= -650 && animationController.value < 0.72)) {
      navigator?.pop();
      return;
    }
    animationController.forward();
  }

  @override
  Color? get barrierColor => Colors.black.withValues(alpha: 0.42);

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => 'Закрыть';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 760);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 520);

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
    return _MeasuredHotbarMorph(
      route: this,
      origin: origin,
      animation: animation,
      child: child,
    );
  }
}

class _MeasuredHotbarMorph extends StatefulWidget {
  const _MeasuredHotbarMorph({
    required this.route,
    required this.origin,
    required this.animation,
    required this.child,
  });

  final _HotbarMorphRoute<dynamic> route;
  final Rect origin;
  final Animation<double> animation;
  final Widget child;

  @override
  State<_MeasuredHotbarMorph> createState() => _MeasuredHotbarMorphState();
}

class _MeasuredHotbarMorphState extends State<_MeasuredHotbarMorph> {
  final GlobalKey _contentKey = GlobalKey();
  double? _targetHeight;

  void _measureContent() {
    if (_targetHeight != null || !mounted) return;
    final box = _contentKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    setState(() => _targetHeight = box.size.height);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final maxHeight = widget.origin.bottom - padding.top - AppSpacing.lg;

    if (_targetHeight == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureContent());
      return Stack(
        children: <Widget>[
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: size.height - widget.origin.bottom,
            child: Offstage(
              child: UnconstrainedBox(
                constrainedAxis: Axis.horizontal,
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  width: size.width - AppSpacing.md * 2,
                  child: KeyedSubtree(key: _contentKey, child: widget.child),
                ),
              ),
            ),
          ),
          Positioned.fromRect(
            rect: widget.origin,
            child: const _MorphingSurface(
              progress: 0,
              navOpacity: 1,
              contentOpacity: 0,
              dragTravel: 160,
              child: SizedBox.shrink(),
            ),
          ),
        ],
      );
    }

    final targetHeight = _targetHeight!.clamp(widget.origin.height, maxHeight);
    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, _) {
        final raw = widget.animation.value;
        // Keep geometry linear so it follows the finger without drift.
        final t = raw;
        final left = lerpDouble(widget.origin.left, AppSpacing.md, t)!;
        final right = lerpDouble(
          widget.origin.right,
          size.width - AppSpacing.md,
          t,
        )!;
        final height = lerpDouble(widget.origin.height, targetHeight, t)!;
        final navOpacity = (1 - raw / 0.38).clamp(0.0, 1.0);
        final contentOpacity = Curves.easeInOut.transform(
          ((raw - 0.22) / 0.62).clamp(0.0, 1.0),
        );

        return Stack(
          children: <Widget>[
            Positioned(
              left: left,
              right: size.width - right,
              bottom: size.height - widget.origin.bottom,
              height: height,
              child: _MorphingSurface(
                progress: t,
                navOpacity: navOpacity,
                contentOpacity: contentOpacity,
                dragTravel: targetHeight - widget.origin.height,
                onDragUpdate: widget.route.updateFromDrag,
                onDragEnd: widget.route.endDrag,
                child: widget.child,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MorphingSurface extends StatelessWidget {
  const _MorphingSurface({
    required this.progress,
    required this.navOpacity,
    required this.contentOpacity,
    required this.dragTravel,
    this.onDragUpdate,
    this.onDragEnd,
    required this.child,
  });

  final double progress;
  final double navOpacity;
  final double contentOpacity;
  final double dragTravel;
  final void Function(double delta, double travel)? onDragUpdate;
  final ValueChanged<double>? onDragEnd;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<GlassTheme>()!;
    final radius = lerpDouble(AppRadius.pill, AppRadius.lg, progress)!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: glass.blur, sigmaY: glass.blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: glass.strongSurface,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: glass.border),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: glass.shadow,
                blurRadius: 28 + 10 * progress,
                offset: Offset(0, 14 - 4 * progress),
              ),
            ],
          ),
          child: Stack(
            children: <Widget>[
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 72,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: navOpacity,
                    child: const _MorphingHotbarGhost(),
                  ),
                ),
              ),
              Opacity(
                opacity: contentOpacity,
                child: Material(type: MaterialType.transparency, child: child),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 36,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragUpdate: onDragUpdate == null
                      ? null
                      : (details) => onDragUpdate!(
                          details.primaryDelta ?? 0,
                          dragTravel,
                        ),
                  onVerticalDragEnd: onDragEnd == null
                      ? null
                      : (details) => onDragEnd!(details.primaryVelocity ?? 0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MorphingHotbarGhost extends StatelessWidget {
  const _MorphingHotbarGhost();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AppHotbarContents(
        currentIndex: AppShellHotbar.currentIndex,
        onSelected: (_) {},
      ),
    );
  }
}

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/glass_theme.dart';
import 'sheet_animation.dart';
import 'sheet_controller.dart';
import 'sheet_gesture_handler.dart';

abstract final class MorphingGlassSheetKeys {
  static const barrier = ValueKey<String>('morphing-glass-sheet-barrier');
  static const surface = ValueKey<String>('morphing-glass-sheet-surface');
  static const content = ValueKey<String>('morphing-glass-sheet-content');
}

class MorphingGlassSheet<T> extends PopupRoute<T> {
  MorphingGlassSheet({
    required this.startRect,
    required this.builder,
    this.endSize,
    this.endPosition,
    this.maximumHeight,
    this.source,
    this.animationSettings = const MorphingSheetAnimationSettings(),
  }) : sheetController = MorphingSheetController(settings: animationSettings);

  final Rect startRect;
  final WidgetBuilder builder;
  final Size? endSize;
  final Offset? endPosition;
  final double? maximumHeight;
  final Widget? source;
  final MorphingSheetAnimationSettings animationSettings;
  final MorphingSheetController sheetController;

  static Future<T?> show<T>({
    required BuildContext context,
    required Rect startRect,
    required WidgetBuilder builder,
    Size? endSize,
    Offset? endPosition,
    double? maximumHeight,
    Widget? source,
    MorphingSheetAnimationSettings animationSettings =
        const MorphingSheetAnimationSettings(),
    bool useRootNavigator = true,
  }) {
    return Navigator.of(context, rootNavigator: useRootNavigator).push<T>(
      MorphingGlassSheet<T>(
        startRect: startRect,
        builder: builder,
        endSize: endSize,
        endPosition: endPosition,
        maximumHeight: maximumHeight,
        source: source,
        animationSettings: animationSettings,
      ),
    );
  }

  void _attachController() {
    final animationController = controller;
    if (animationController == null) return;
    sheetController.attach(
      animationController: animationController,
      dismiss: () {
        final nav = navigator;
        if (nav == null || !isCurrent) return;
        nav.pop();
      },
    );
  }

  @override
  Color? get barrierColor => Colors.transparent;

  @override
  bool get barrierDismissible => false;

  @override
  String? get barrierLabel => 'Закрыть';

  @override
  Duration get transitionDuration => animationSettings.minimumDuration;

  @override
  Duration get reverseTransitionDuration => animationSettings.minimumDuration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return Material(type: MaterialType.transparency, child: builder(context));
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    _attachController();
    return _MeasuredMorphingGlassSheet<T>(
      route: this,
      animation: animation,
      child: child,
    );
  }

  @override
  void dispose() {
    sheetController.dispose();
    super.dispose();
  }
}

class _MeasuredMorphingGlassSheet<T> extends StatefulWidget {
  const _MeasuredMorphingGlassSheet({
    required this.route,
    required this.animation,
    required this.child,
  });

  final MorphingGlassSheet<T> route;
  final Animation<double> animation;
  final Widget child;

  @override
  State<_MeasuredMorphingGlassSheet<T>> createState() =>
      _MeasuredMorphingGlassSheetState<T>();
}

class _MeasuredMorphingGlassSheetState<T>
    extends State<_MeasuredMorphingGlassSheet<T>> {
  final GlobalKey _measurementKey = GlobalKey();
  double? _contentHeight;

  void _measure(double maximumHeight) {
    if (_contentHeight != null || !mounted) return;
    final box =
        _measurementKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    setState(() {
      _contentHeight = box.size.height.clamp(
        widget.route.startRect.height,
        maximumHeight,
      );
    });
  }

  Rect _endRect({
    required Size screenSize,
    required EdgeInsets safePadding,
    required double keyboardHeight,
    required double contentHeight,
  }) {
    final route = widget.route;
    final targetBottom = keyboardHeight == 0
        ? route.startRect.bottom
        : (screenSize.height - keyboardHeight - AppSpacing.md).clamp(
            safePadding.top + route.startRect.height + AppSpacing.lg,
            route.startRect.bottom,
          );
    final availableHeight = targetBottom - safePadding.top - AppSpacing.lg;
    final maximumHeight = route.maximumHeight == null
        ? availableHeight
        : route.maximumHeight!.clamp(route.startRect.height, availableHeight);
    final height = (route.endSize?.height ?? contentHeight).clamp(
      route.startRect.height,
      maximumHeight,
    );
    final width = (route.endSize?.width ?? screenSize.width - AppSpacing.md * 2)
        .clamp(route.startRect.width, screenSize.width);
    final defaultLeft = (screenSize.width - width) / 2;
    final defaultTop = targetBottom - height;
    final requestedPosition =
        route.endPosition ?? Offset(defaultLeft, defaultTop);
    return Rect.fromLTWH(
      requestedPosition.dx.clamp(0, screenSize.width - width),
      requestedPosition.dy.clamp(
        safePadding.top + AppSpacing.sm,
        screenSize.height - safePadding.bottom - height,
      ),
      width,
      height,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final safePadding = MediaQuery.paddingOf(context);
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    final targetBottom = keyboardHeight == 0
        ? widget.route.startRect.bottom
        : screenSize.height - keyboardHeight - AppSpacing.md;
    final screenMaximumHeight = targetBottom - safePadding.top - AppSpacing.lg;
    final maximumHeight = widget.route.maximumHeight == null
        ? screenMaximumHeight
        : widget.route.maximumHeight!.clamp(
            widget.route.startRect.height,
            screenMaximumHeight,
          );
    final targetWidth =
        widget.route.endSize?.width ?? screenSize.width - AppSpacing.md * 2;

    if (_contentHeight == null && widget.route.endSize?.height == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _measure(maximumHeight),
      );
      return Stack(
        children: <Widget>[
          Positioned(
            left: (screenSize.width - targetWidth) / 2,
            width: targetWidth,
            bottom: screenSize.height - widget.route.startRect.bottom,
            child: Offstage(
              child: UnconstrainedBox(
                constrainedAxis: Axis.horizontal,
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  width: targetWidth,
                  child: KeyedSubtree(
                    key: _measurementKey,
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ),
          Positioned.fromRect(
            rect: widget.route.startRect,
            child: _LiquidGlassSurface(
              progress: 0,
              sourceOpacity: 1,
              contentOpacity: 0,
              settings: widget.route.animationSettings,
              source: widget.route.source,
              child: const SizedBox.shrink(),
            ),
          ),
        ],
      );
    }

    final endRect = _endRect(
      screenSize: screenSize,
      safePadding: safePadding,
      keyboardHeight: keyboardHeight,
      contentHeight:
          widget.route.endSize?.height ??
          _contentHeight ??
          widget.route.startRect.height,
    );
    widget.route.sheetController.configure(
      startRect: widget.route.startRect,
      endRect: endRect,
    );

    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[
        widget.animation,
        widget.route.sheetController,
      ]),
      builder: (context, _) {
        final rawProgress = widget.animation.value;
        final progress = widget.route.sheetController.hasInteracted
            ? rawProgress
            : widget.route.animationSettings.openingCurve.transform(
                rawProgress,
              );
        final currentRect = MorphingSheetGeometry.interpolate(
          widget.route.startRect,
          endRect,
          progress,
        );
        final overlayProgress = Curves.easeOut.transform(rawProgress);
        final sourceOpacity = (1 - rawProgress / 0.34).clamp(0.0, 1.0);
        final contentOpacity = Curves.easeInOut.transform(
          ((rawProgress - 0.20) / 0.62).clamp(0.0, 1.0),
        );

        return Stack(
          children: <Widget>[
            Positioned.fill(
              child: IgnorePointer(
                ignoring: widget.route.sheetController.isClosing,
                child: GestureDetector(
                  key: MorphingGlassSheetKeys.barrier,
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.route.sheetController.dismiss,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX:
                          widget.route.animationSettings.backgroundBlur *
                          overlayProgress,
                      sigmaY:
                          widget.route.animationSettings.backgroundBlur *
                          overlayProgress,
                    ),
                    child: ColoredBox(
                      color: Colors.black.withValues(
                        alpha:
                            widget.route.animationSettings.overlayOpacity *
                            overlayProgress,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fromRect(
              rect: currentRect,
              child: _LiquidGlassSurface(
                key: MorphingGlassSheetKeys.surface,
                progress: progress,
                sourceOpacity: sourceOpacity,
                contentOpacity: contentOpacity,
                settings: widget.route.animationSettings,
                source: widget.route.source,
                child: SheetGestureHandler(
                  controller: widget.route.sheetController,
                  child: KeyedSubtree(
                    key: MorphingGlassSheetKeys.content,
                    child: widget.child,
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

class _LiquidGlassSurface extends StatelessWidget {
  const _LiquidGlassSurface({
    required this.progress,
    required this.sourceOpacity,
    required this.contentOpacity,
    required this.settings,
    required this.source,
    required this.child,
    super.key,
  });

  final double progress;
  final double sourceOpacity;
  final double contentOpacity;
  final MorphingSheetAnimationSettings settings;
  final Widget? source;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = theme.extension<GlassTheme>()!;
    const coral = Color(0xFFDC586D);
    final luxurySurface = theme.brightness == Brightness.dark
        ? const Color(0xF2171214)
        : const Color(0xF2F8EDEB);
    final surface = Color.lerp(glass.strongSurface, luxurySurface, progress)!;
    final radius = MorphingSheetGeometry.value(
      settings.startRadius,
      settings.endRadius,
      progress,
    );
    final blur = MorphingSheetGeometry.value(
      settings.startBlur,
      settings.endBlur,
      progress,
    );
    final shadowBlur = MorphingSheetGeometry.value(28, 52, progress);
    final shadowOffset = MorphingSheetGeometry.value(14, 20, progress);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color.lerp(
              glass.shadow,
              coral.withValues(alpha: 0.28),
              progress,
            )!,
            blurRadius: shadowBlur,
            spreadRadius: 1 + progress * 3,
            offset: Offset(0, shadowOffset),
          ),
          BoxShadow(
            color: coral.withValues(alpha: 0.10 * progress),
            blurRadius: 36,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  Color.alphaBlend(
                    coral.withValues(alpha: 0.14 * progress),
                    surface,
                  ),
                  Color.alphaBlend(
                    Colors.white.withValues(
                      alpha: theme.brightness == Brightness.dark
                          ? 0.02 * progress
                          : 0.18 * progress,
                    ),
                    surface,
                  ),
                ],
              ),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: Color.lerp(
                  glass.border,
                  Color.lerp(
                    Colors.white.withValues(
                      alpha: theme.brightness == Brightness.dark ? 0.18 : 0.72,
                    ),
                    coral.withValues(alpha: 0.35),
                    0.18,
                  ),
                  progress,
                )!,
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                if (source != null)
                  IgnorePointer(
                    child: Opacity(opacity: sourceOpacity, child: source),
                  ),
                IgnorePointer(
                  ignoring: contentOpacity < 0.82,
                  child: Opacity(opacity: contentOpacity, child: child),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: IgnorePointer(
                    child: Container(
                      height: 1.2,
                      margin: const EdgeInsets.fromLTRB(
                        AppSpacing.xl,
                        1,
                        AppSpacing.xl,
                        0,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: <Color>[
                            Colors.transparent,
                            glass.highlight.withValues(alpha: 0.9),
                            coral.withValues(alpha: 0.35 * progress),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

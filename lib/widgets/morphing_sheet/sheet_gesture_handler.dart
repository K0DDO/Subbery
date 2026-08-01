import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_accent_theme.dart';
import 'sheet_controller.dart';

class SheetGestureHandler extends StatefulWidget {
  const SheetGestureHandler({
    required this.controller,
    required this.child,
    this.dragHandleHeight = 52,
    super.key,
  });

  final MorphingSheetController controller;
  final Widget child;
  final double dragHandleHeight;

  @override
  State<SheetGestureHandler> createState() => _SheetGestureHandlerState();
}

class _SheetGestureHandlerState extends State<SheetGestureHandler> {
  bool _pointerDrivenSheet = false;
  VelocityTracker? _velocityTracker;

  bool get _atTop {
    final positions = widget.controller.scrollController.positions;
    if (positions.isEmpty) return true;
    final position = positions.single;
    return position.pixels <= position.minScrollExtent + 0.5;
  }

  void _resetScrollPosition() {
    final positions = widget.controller.scrollController.positions;
    if (positions.length != 1) return;
    final position = positions.single;
    if (position.pixels > position.minScrollExtent) {
      position.jumpTo(position.minScrollExtent);
    }
  }

  void _onPointerDown(PointerDownEvent event) {
    _velocityTracker = VelocityTracker.withKind(event.kind)
      ..addPosition(event.timeStamp, event.position);
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (widget.controller.isClosing) return;
    _velocityTracker?.addPosition(event.timeStamp, event.position);
    final dy = event.delta.dy;
    if (dy == 0) return;

    if (_pointerDrivenSheet || widget.controller.sheetDragging.value) {
      if (widget.controller.progress >= 0.999 && dy < 0 && !_atTop) {
        _pointerDrivenSheet = false;
        widget.controller.sheetDragging.value = false;
        return;
      }
      _pointerDrivenSheet = true;
      _resetScrollPosition();
      widget.controller.updateDrag(dy);
      return;
    }

    if (_atTop && dy > 0) {
      _pointerDrivenSheet = true;
      _resetScrollPosition();
      widget.controller.updateDrag(dy);
    }
  }

  void _onPointerEnd(PointerEvent event) {
    if (!_pointerDrivenSheet && !widget.controller.sheetDragging.value) {
      _velocityTracker = null;
      return;
    }
    final velocity = _velocityTracker?.getVelocity().pixelsPerSecond.dy ?? 0;
    _velocityTracker = null;
    _pointerDrivenSheet = false;
    if (!widget.controller.isClosing) {
      widget.controller.endDrag(velocity);
    }
  }

  bool _handleScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    if (widget.controller.isClosing) return false;
    if (_pointerDrivenSheet) return true;

    if (notification is OverscrollNotification && notification.overscroll < 0) {
      widget.controller.updateDrag(-notification.overscroll);
      return true;
    }

    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0;
      final atTop =
          notification.metrics.pixels <=
          notification.metrics.minScrollExtent + 0.5;
      if ((atTop && delta < 0) ||
          (widget.controller.sheetDragging.value &&
              widget.controller.progress < 1)) {
        _resetScrollPosition();
        widget.controller.updateDrag(-delta);
        return true;
      }
    }

    if (notification is ScrollEndNotification &&
        widget.controller.sheetDragging.value) {
      widget.controller.endDrag(notification.dragDetails?.primaryVelocity ?? 0);
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.subberryTheme;
    return PrimaryScrollController(
      controller: widget.controller.scrollController,
      child: NotificationListener<ScrollNotification>(
        onNotification: _handleScroll,
        child: ValueListenableBuilder<bool>(
          valueListenable: widget.controller.sheetDragging,
          builder: (context, dragging, child) {
            return ScrollConfiguration(
              behavior: dragging
                  ? const _LockedScrollBehavior()
                  : ScrollConfiguration.of(context),
              child: child!,
            );
          },
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Positioned.fill(child: widget.child),
              Positioned(
                left: 0,
                right: 0,
                top: widget.dragHandleHeight,
                bottom: 0,
                child: Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: _onPointerDown,
                  onPointerMove: _onPointerMove,
                  onPointerUp: _onPointerEnd,
                  onPointerCancel: _onPointerEnd,
                  child: const SizedBox.expand(),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: widget.dragHandleHeight,
                child: GestureDetector(
                  key: const ValueKey<String>('morphing-sheet-drag-handle'),
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragUpdate: (details) {
                    widget.controller.updateDrag(details.primaryDelta ?? 0);
                  },
                  onVerticalDragEnd: (details) {
                    widget.controller.endDrag(details.primaryVelocity ?? 0);
                  },
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.35,
                          ),
                          borderRadius: BorderRadius.circular(99),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: palette.glowColor.withValues(alpha: 0.18),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LockedScrollBehavior extends ScrollBehavior {
  const _LockedScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const NeverScrollableScrollPhysics();
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

import 'package:flutter/material.dart';

import 'sheet_controller.dart';

class SheetGestureHandler extends StatefulWidget {
  const SheetGestureHandler({
    required this.controller,
    required this.child,
    this.dragHandleHeight = 44,
    super.key,
  });

  final MorphingSheetController controller;
  final Widget child;
  final double dragHandleHeight;

  @override
  State<SheetGestureHandler> createState() => _SheetGestureHandlerState();
}

class _SheetGestureHandlerState extends State<SheetGestureHandler> {
  bool _scrollHandoffActive = false;

  bool _handleScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;

    if (notification is OverscrollNotification && notification.overscroll < 0) {
      _scrollHandoffActive = true;
      widget.controller.updateDrag(-notification.overscroll);
      return true;
    }

    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0;
      final atTop =
          notification.metrics.pixels <=
          notification.metrics.minScrollExtent + 0.5;
      if ((atTop && delta < 0) ||
          (_scrollHandoffActive && widget.controller.progress < 1)) {
        _scrollHandoffActive = true;
        _resetScrollPosition();
        widget.controller.updateDrag(-delta);
        return true;
      }
    }

    if (notification is ScrollEndNotification && _scrollHandoffActive) {
      _scrollHandoffActive = false;
      widget.controller.endDrag(notification.dragDetails?.primaryVelocity ?? 0);
      return true;
    }
    return false;
  }

  void _resetScrollPosition() {
    final positions = widget.controller.scrollController.positions;
    if (positions.length != 1) return;
    final position = positions.single;
    if (position.pixels > position.minScrollExtent) {
      position.jumpTo(position.minScrollExtent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryScrollController(
      controller: widget.controller.scrollController,
      child: NotificationListener<ScrollNotification>(
        onNotification: _handleScroll,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            widget.child,
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: widget.dragHandleHeight,
              child: GestureDetector(
                key: const ValueKey<String>('morphing-sheet-drag-handle'),
                behavior: HitTestBehavior.translucent,
                onVerticalDragUpdate: (details) {
                  widget.controller.updateDrag(details.primaryDelta ?? 0);
                },
                onVerticalDragEnd: (details) {
                  widget.controller.endDrag(details.primaryVelocity ?? 0);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

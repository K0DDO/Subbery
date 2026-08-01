import 'dart:async';

import 'package:flutter/material.dart';

import '../haptics/haptic_manager.dart';
import '../theme/app_spacing.dart';
import 'liquid_glass_material.dart';

class GlassCard extends StatefulWidget {
  const GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.radius = AppRadius.lg,
    this.onTap,
    this.onLongPress,
    this.strong = false,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool strong;

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if ((widget.onTap == null && widget.onLongPress == null) ||
        _isPressed == value) {
      return;
    }
    setState(() => _isPressed = value);
  }

  void _handleTap() {
    unawaited(HapticManager.instance.selection());
    widget.onTap?.call();
  }

  void _handleLongPress() {
    unawaited(HapticManager.instance.longPress());
    widget.onLongPress?.call();
  }

  @override
  Widget build(BuildContext context) {
    final interactive = widget.onTap != null || widget.onLongPress != null;

    return AnimatedScale(
      scale: _isPressed ? 0.985 : 1,
      duration: const Duration(milliseconds: 130),
      curve: Curves.easeOutCubic,
      child: LiquidGlassMaterial(
        margin: widget.margin,
        radius: widget.radius,
        strong: widget.strong,
        padding: EdgeInsets.zero,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onTap == null ? null : _handleTap,
            onLongPress: widget.onLongPress == null ? null : _handleLongPress,
            onTapDown: interactive ? (_) => _setPressed(true) : null,
            onTapUp: interactive ? (_) => _setPressed(false) : null,
            onTapCancel: interactive ? () => _setPressed(false) : null,
            borderRadius: BorderRadius.circular(widget.radius),
            child: Padding(padding: widget.padding, child: widget.child),
          ),
        ),
      ),
    );
  }
}

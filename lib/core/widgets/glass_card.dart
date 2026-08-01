import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_spacing.dart';
import '../theme/glass_theme.dart';

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
    unawaited(HapticFeedback.selectionClick());
    widget.onTap?.call();
  }

  void _handleLongPress() {
    unawaited(HapticFeedback.mediumImpact());
    widget.onLongPress?.call();
  }

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<GlassTheme>()!;
    final borderRadius = BorderRadius.circular(widget.radius);
    final interactive = widget.onTap != null || widget.onLongPress != null;

    return AnimatedScale(
      scale: _isPressed ? 0.985 : 1,
      duration: const Duration(milliseconds: 130),
      curve: Curves.easeOutCubic,
      child: RepaintBoundary(
        child: Container(
          margin: widget.margin,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: glass.shadow,
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: borderRadius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: glass.blur, sigmaY: glass.blur),
              child: Material(
                color: widget.strong ? glass.strongSurface : glass.surface,
                child: InkWell(
                  onTap: widget.onTap == null ? null : _handleTap,
                  onLongPress: widget.onLongPress == null
                      ? null
                      : _handleLongPress,
                  onTapDown: interactive ? (_) => _setPressed(true) : null,
                  onTapUp: interactive ? (_) => _setPressed(false) : null,
                  onTapCancel: interactive ? () => _setPressed(false) : null,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: borderRadius,
                      border: Border.all(color: glass.border),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[
                          glass.highlight.withValues(alpha: 0.22),
                          Colors.transparent,
                          glass.highlight.withValues(alpha: 0.06),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: widget.padding,
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

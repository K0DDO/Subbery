import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_accent_theme.dart';
import '../theme/app_spacing.dart';

class GlassButton extends StatefulWidget {
  const GlassButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (widget.onPressed == null || _isPressed == value) return;
    setState(() => _isPressed = value);
  }

  void _handleTap() {
    unawaited(HapticFeedback.lightImpact());
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.accentTheme;
    final button = AnimatedScale(
      scale: _isPressed ? 0.975 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          gradient: widget.onPressed == null
              ? const LinearGradient(colors: <Color>[Colors.grey, Colors.grey])
              : accent.gradient,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: accent.primary.withValues(alpha: 0.28),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.28),
              blurRadius: 0,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            onTap: widget.onPressed == null ? null : _handleTap,
            onTapDown: (_) => _setPressed(true),
            onTapUp: (_) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: 17,
              ),
              child: Row(
                mainAxisSize: widget.expanded
                    ? MainAxisSize.max
                    : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (widget.icon case final icon?) ...<Widget>[
                    Icon(icon, size: 20, color: Colors.white),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Text(
                    widget.label,
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return widget.expanded
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}

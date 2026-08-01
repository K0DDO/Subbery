import 'dart:async';

import 'package:flutter/material.dart';

import '../haptics/haptic_manager.dart';
import '../theme/app_accent_theme.dart';
import '../theme/app_spacing.dart';
import 'liquid_glass_material.dart';

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
    unawaited(HapticManager.instance.create());
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.accentTheme;
    final foreground = Theme.of(context).colorScheme.onPrimary;
    final glassStrength = LiquidGlassConfig.of(context);
    final opticalT = Curves.easeInOutCubic.transform(glassStrength);
    final legacyOpacity = 1 - opticalT * 0.88;
    final buttonSurface = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        gradient: widget.onPressed == null
            ? LinearGradient(
                colors: <Color>[
                  accent.mutedTextColor.withValues(alpha: 0.55 * legacyOpacity),
                  accent.mutedTextColor.withValues(alpha: 0.38 * legacyOpacity),
                ],
              )
            : _isPressed
            ? LinearGradient(
                colors: <Color>[
                  accent.primaryDark.withValues(alpha: legacyOpacity),
                  accent.primary.withValues(alpha: legacyOpacity),
                ],
              )
            : LinearGradient(
                colors: accent.gradient.colors
                    .map((color) => color.withValues(alpha: legacyOpacity))
                    .toList(growable: false),
              ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: accent.glowColor.withValues(
              alpha: accent.glowColor.a * (1 - opticalT),
            ),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.28 * (1 - opticalT)),
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
                  Icon(icon, size: 20, color: foreground),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Text(
                  widget.label,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: foreground),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final opticalButton = glassStrength <= 0
        ? buttonSurface
        : LiquidGlassMaterial(
            radius: AppRadius.pill,
            strong: true,
            child: buttonSurface,
          );
    final button = AnimatedScale(
      scale: _isPressed ? 0.975 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: opticalButton,
    );

    return widget.expanded
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_accent_theme.dart';
import '../theme/glass_theme.dart';
import '../theme/liquid_glass_tokens.dart';
import 'liquid_glass_sheen.dart';

/// Provides the current glass-effect strength to the widget tree.
class LiquidGlassConfig extends InheritedWidget {
  const LiquidGlassConfig({
    required this.strength,
    required super.child,
    super.key,
  });

  final double strength;

  static double of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<LiquidGlassConfig>()
            ?.strength ??
        0;
  }

  @override
  bool updateShouldNotify(covariant LiquidGlassConfig oldWidget) {
    return oldWidget.strength != strength;
  }
}

/// Unified Subberry liquid-glass surface used by cards, hotbar, and sheets.
class LiquidGlassMaterial extends StatelessWidget {
  const LiquidGlassMaterial({
    required this.child,
    this.radius = 28,
    this.padding = EdgeInsets.zero,
    this.strong = false,
    this.progress = 1,
    this.margin,
    this.clipBehavior = Clip.antiAlias,
    this.strengthOverride,
    super.key,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final bool strong;

  /// Morph progress for sheets (0 = source chrome, 1 = settled sheet).
  final double progress;
  final Clip clipBehavior;

  /// Optional override; otherwise reads [LiquidGlassConfig].
  final double? strengthOverride;

  @override
  Widget build(BuildContext context) {
    final strength = (strengthOverride ?? LiquidGlassConfig.of(context)).clamp(
      0.0,
      1.0,
    );
    final glass = Theme.of(context).extension<GlassTheme>()!;
    final palette = context.subberryTheme;
    final brightness = Theme.of(context).brightness;
    final tokens = LiquidGlassTokens.resolve(
      strength: strength,
      glass: glass,
      palette: palette,
      brightness: brightness,
      strong: strong,
      progress: progress,
    );
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final sheenOn = tokens.sheenEnabled && !disableAnimations;

    final borderRadius = BorderRadius.circular(radius);
    final filter = ImageFilter.blur(sigmaX: tokens.blur, sigmaY: tokens.blur);

    final surface = ClipRRect(
      borderRadius: borderRadius,
      clipBehavior: clipBehavior,
      child: BackdropFilter(
        filter: filter,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            color: tokens.fill,
          ),
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _GlassDepthPainter(
                      radius: radius,
                      innerGlow: tokens.innerGlow,
                      edgeShade: tokens.edgeShade,
                      strength: strength,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _SpecularRimPainter(
                      radius: radius,
                      highlight: tokens.rimHighlight,
                      shadow: tokens.rimShadow,
                      strength: tokens.highlightStrength,
                    ),
                  ),
                ),
              ),
              if (sheenOn)
                Positioned.fill(
                  child: IgnorePointer(
                    child: ListenableBuilder(
                      listenable: LiquidGlassSheen.instance,
                      builder: (context, _) {
                        final phase = LiquidGlassSheen.instance.phase;
                        return CustomPaint(
                          painter: _LocalReflectionPainter(
                            radius: radius,
                            phase: phase,
                            color: tokens.reflectionTint.withValues(
                              alpha: tokens.sheenAlpha,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              Padding(padding: padding, child: child),
            ],
          ),
        ),
      ),
    );

    return RepaintBoundary(
      child: Container(
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: tokens.shadowColor,
              blurRadius: tokens.shadowBlur,
              spreadRadius: tokens.shadowSpread,
              offset: Offset(0, tokens.shadowOffsetY),
            ),
          ],
        ),
        child: surface,
      ),
    );
  }
}

class _GlassDepthPainter extends CustomPainter {
  const _GlassDepthPainter({
    required this.radius,
    required this.innerGlow,
    required this.edgeShade,
    required this.strength,
  });

  final double radius;
  final Color innerGlow;
  final Color edgeShade;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    final edgeDepth = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.08),
        radius: 0.94,
        colors: <Color>[
          Colors.transparent,
          Colors.transparent,
          edgeShade.withValues(alpha: edgeShade.a * (0.55 + strength * 0.45)),
        ],
        stops: const <double>[0, 0.68, 1],
      ).createShader(rect);
    canvas.drawRRect(rrect, edgeDepth);

    final verticalDepth = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          innerGlow.withValues(alpha: innerGlow.a * (0.55 + strength * 0.25)),
          Colors.transparent,
          Colors.transparent,
          edgeShade.withValues(alpha: edgeShade.a * 0.52),
        ],
        stops: const <double>[0, 0.2, 0.68, 1],
      ).createShader(rect);
    canvas.drawRRect(rrect, verticalDepth);
  }

  @override
  bool shouldRepaint(covariant _GlassDepthPainter oldDelegate) {
    return oldDelegate.radius != radius ||
        oldDelegate.innerGlow != innerGlow ||
        oldDelegate.edgeShade != edgeShade ||
        oldDelegate.strength != strength;
  }
}

class _SpecularRimPainter extends CustomPainter {
  const _SpecularRimPainter({
    required this.radius,
    required this.highlight,
    required this.shadow,
    required this.strength,
  });

  final double radius;
  final Color highlight;
  final Color shadow;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final path = Path()..addRRect(rrect);

    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.62 + strength * 0.14
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          highlight,
          highlight.withValues(alpha: highlight.a * 0.12),
          Colors.transparent,
          shadow.withValues(alpha: shadow.a * 0.14),
          shadow,
        ],
        stops: const <double>[0, 0.22, 0.5, 0.76, 1],
      ).createShader(rect);
    canvas.drawPath(path, rim);
  }

  @override
  bool shouldRepaint(covariant _SpecularRimPainter oldDelegate) {
    return oldDelegate.radius != radius ||
        oldDelegate.highlight != highlight ||
        oldDelegate.shadow != shadow ||
        oldDelegate.strength != strength;
  }
}

class _LocalReflectionPainter extends CustomPainter {
  const _LocalReflectionPainter({
    required this.radius,
    required this.phase,
    required this.color,
  });

  final double radius;
  final double phase;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    canvas.save();
    canvas.clipRRect(rrect);

    final angle = phase * math.pi * 2;
    final driftX = math.sin(angle) * size.width * 0.025;
    final driftY = math.cos(angle * 0.73) * size.height * 0.018;
    final reflection = Rect.fromCenter(
      center: Offset(size.width * 0.24 + driftX, size.height * 0.12 + driftY),
      width: size.width * 0.72,
      height: size.height * 0.5,
    );
    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.18, -0.12),
        radius: 0.78,
        colors: <Color>[color, color.withValues(alpha: 0)],
        stops: const <double>[0, 1],
      ).createShader(reflection);
    canvas.drawOval(reflection, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LocalReflectionPainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.color != color ||
        oldDelegate.radius != radius;
  }
}

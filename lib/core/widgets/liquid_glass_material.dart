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
              if (tokens.refractionStrength > 0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: _RefractiveEdgeLayer(
                      radius: radius,
                      thickness: tokens.edgeThickness,
                      strength: tokens.refractionStrength,
                    ),
                  ),
                ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _GlassDepthPainter(
                      radius: radius,
                      innerGlow: tokens.innerGlow,
                      edgeShade: tokens.edgeShade,
                      edgeThickness: tokens.edgeThickness,
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
                      opticalStrength: tokens.refractionStrength,
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

class _RefractiveEdgeLayer extends StatelessWidget {
  const _RefractiveEdgeLayer({
    required this.radius,
    required this.thickness,
    required this.strength,
  });

  final double radius;
  final double thickness;
  final double strength;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        if (!width.isFinite || !height.isFinite || width <= 0 || height <= 0) {
          return const SizedBox.shrink();
        }

        // A near-circular surface behaves more like a lens, while a large
        // panel receives gentler edge refraction.
        final shapeFactor = ((radius * 2) / math.min(width, height)).clamp(
          0.0,
          1.0,
        );
        final scale = 1 + strength * (0.006 + shapeFactor * 0.012);
        final matrix = Matrix4.identity()
          ..translateByDouble(width / 2, height / 2, 0, 1)
          ..scaleByDouble(scale, scale, 1, 1)
          ..translateByDouble(-width / 2, -height / 2, 0, 1);

        return ClipPath(
          clipper: _EdgeBandClipper(radius: radius, thickness: thickness),
          child: BackdropFilter(
            filter: ImageFilter.matrix(
              matrix.storage,
              filterQuality: FilterQuality.medium,
            ),
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }
}

class _EdgeBandClipper extends CustomClipper<Path> {
  const _EdgeBandClipper({required this.radius, required this.thickness});

  final double radius;
  final double thickness;

  @override
  Path getClip(Size size) {
    final rect = Offset.zero & size;
    final outer = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    final innerRect = rect.deflate(thickness);
    if (innerRect.isEmpty) return outer;
    final inner = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          innerRect,
          Radius.circular(math.max(0, radius - thickness * 0.72)),
        ),
      );
    return Path.combine(PathOperation.difference, outer, inner);
  }

  @override
  bool shouldReclip(covariant _EdgeBandClipper oldClipper) {
    return oldClipper.radius != radius || oldClipper.thickness != thickness;
  }
}

class _GlassDepthPainter extends CustomPainter {
  const _GlassDepthPainter({
    required this.radius,
    required this.innerGlow,
    required this.edgeShade,
    required this.edgeThickness,
    required this.strength,
  });

  final double radius;
  final Color innerGlow;
  final Color edgeShade;
  final double edgeThickness;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final innerRect = rect.deflate(edgeThickness);

    if (!innerRect.isEmpty) {
      final outerPath = Path()..addRRect(rrect);
      final innerPath = Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            innerRect,
            Radius.circular(math.max(0, radius - edgeThickness * 0.72)),
          ),
        );
      final edgeBand = Path.combine(
        PathOperation.difference,
        outerPath,
        innerPath,
      );
      final thicknessPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            innerGlow.withValues(alpha: innerGlow.a * (0.72 + strength * 0.28)),
            innerGlow.withValues(alpha: innerGlow.a * 0.24),
            edgeShade.withValues(alpha: edgeShade.a * 0.32),
            edgeShade.withValues(alpha: edgeShade.a * 0.92),
          ],
          stops: const <double>[0, 0.28, 0.68, 1],
        ).createShader(rect)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.4);
      canvas.drawPath(edgeBand, thicknessPaint);
    }

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
        oldDelegate.edgeThickness != edgeThickness ||
        oldDelegate.strength != strength;
  }
}

class _SpecularRimPainter extends CustomPainter {
  const _SpecularRimPainter({
    required this.radius,
    required this.highlight,
    required this.shadow,
    required this.strength,
    required this.opticalStrength,
  });

  final double radius;
  final Color highlight;
  final Color shadow;
  final double strength;
  final double opticalStrength;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final resolvedRadius = math.min(radius, math.min(width, height) / 2);
    const inset = 0.8;

    if (opticalStrength < 1) {
      final rect = Offset.zero & size;
      final legacyPath = Path()
        ..addRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(resolvedRadius)),
        );
      final legacyRim = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.62 + strength * 0.14
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            highlight.withValues(alpha: highlight.a * (1 - opticalStrength)),
            highlight.withValues(
              alpha: highlight.a * 0.12 * (1 - opticalStrength),
            ),
            Colors.transparent,
            shadow.withValues(alpha: shadow.a * 0.14 * (1 - opticalStrength)),
            shadow.withValues(alpha: shadow.a * (1 - opticalStrength)),
          ],
          stops: const <double>[0, 0.22, 0.5, 0.76, 1],
        ).createShader(rect);
      canvas.drawPath(legacyPath, legacyRim);
    }

    final topPath = Path()
      ..moveTo(inset, resolvedRadius)
      ..quadraticBezierTo(inset, inset, resolvedRadius, inset)
      ..lineTo(width - resolvedRadius, inset)
      ..quadraticBezierTo(width - inset, inset, width - inset, resolvedRadius);
    final topRim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 0.7 + strength * 0.7
      ..color = highlight.withValues(alpha: highlight.a * opticalStrength)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.45);
    canvas.drawPath(topPath, topRim);

    final sidePath = Path()
      ..moveTo(inset, resolvedRadius)
      ..lineTo(inset, height - resolvedRadius)
      ..moveTo(width - inset, resolvedRadius)
      ..lineTo(width - inset, height - resolvedRadius);
    final sideRim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.55 + strength * 0.32
      ..color = highlight.withValues(
        alpha: highlight.a * 0.34 * opticalStrength,
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.7);
    canvas.drawPath(sidePath, sideRim);

    final bottomPath = Path()
      ..moveTo(inset, height - resolvedRadius)
      ..quadraticBezierTo(inset, height - inset, resolvedRadius, height - inset)
      ..lineTo(width - resolvedRadius, height - inset)
      ..quadraticBezierTo(
        width - inset,
        height - inset,
        width - inset,
        height - resolvedRadius,
      );
    final bottomRim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 0.65 + strength * 0.42
      ..color = shadow.withValues(alpha: shadow.a * opticalStrength)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.65);
    canvas.drawPath(bottomPath, bottomRim);
  }

  @override
  bool shouldRepaint(covariant _SpecularRimPainter oldDelegate) {
    return oldDelegate.radius != radius ||
        oldDelegate.highlight != highlight ||
        oldDelegate.shadow != shadow ||
        oldDelegate.strength != strength ||
        oldDelegate.opticalStrength != opticalStrength;
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

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
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: borderRadius,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          tokens.innerGlow.withValues(
                            alpha: tokens.innerGlow.a * tokens.highlightStrength,
                          ),
                          Colors.transparent,
                          tokens.rimShadow.withValues(
                            alpha: tokens.rimShadow.a * 0.45,
                          ),
                        ],
                        stops: const <double>[0, 0.45, 1],
                      ),
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
                          painter: _DriftingSheenPainter(
                            radius: radius,
                            phase: phase,
                            color: Color.lerp(
                              Colors.white,
                              palette.primaryLight,
                              brightness == Brightness.dark ? 0.4 : 0.15,
                            )!.withValues(alpha: tokens.sheenAlpha),
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
            if (strength > 0.2)
              BoxShadow(
                color: palette.primary.withValues(alpha: 0.08 * strength),
                blurRadius: 28,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: surface,
      ),
    );
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
      ..strokeWidth = 1.1 + strength * 0.5
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          highlight,
          highlight.withValues(alpha: highlight.a * 0.15),
          shadow.withValues(alpha: shadow.a * 0.35),
          shadow,
        ],
        stops: const <double>[0, 0.28, 0.72, 1],
      ).createShader(rect);
    canvas.drawPath(path, rim);

    final topGlow = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          highlight.withValues(alpha: highlight.a * 0.55 * strength),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.35));
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.28),
      topGlow,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SpecularRimPainter oldDelegate) {
    return oldDelegate.radius != radius ||
        oldDelegate.highlight != highlight ||
        oldDelegate.shadow != shadow ||
        oldDelegate.strength != strength;
  }
}

class _DriftingSheenPainter extends CustomPainter {
  const _DriftingSheenPainter({
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

    final x = -size.width * 0.35 + (size.width * 1.7) * phase;
    final band = Rect.fromLTWH(
      x,
      -size.height * 0.2,
      size.width * 0.38,
      size.height * 1.4,
    );
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[Colors.transparent, color, Colors.transparent],
        stops: const <double>[0.2, 0.5, 0.8],
      ).createShader(band);
    canvas.drawRect(band, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DriftingSheenPainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.color != color ||
        oldDelegate.radius != radius;
  }
}

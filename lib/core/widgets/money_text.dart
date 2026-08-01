import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/application/privacy_settings_controller.dart';
import '../theme/app_accent_theme.dart';
import '../utils/app_formatters.dart';

/// Formats money with privacy: kopecks, Telegram-style spoiler, optional frost.
class MoneyText extends ConsumerStatefulWidget {
  const MoneyText({
    required this.cents,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.compact = false,
    this.frost = false,
    this.prefix,
    this.suffix,
    this.revealKey,
    super.key,
  });

  final int cents;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool compact;

  /// Applies frosted glass fill when transparent-balance privacy is on.
  /// Only intended for the overview planned block and payment ring.
  final bool frost;

  final String? prefix;
  final String? suffix;

  /// Stable id so multiple widgets showing the same amount can share reveal.
  final String? revealKey;

  @override
  ConsumerState<MoneyText> createState() => _MoneyTextState();
}

class _MoneyTextState extends ConsumerState<MoneyText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _revealController;
  var _revealed = false;
  var _seenEpoch = 0;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  void _syncEpoch(int epoch) {
    if (epoch == _seenEpoch) return;
    _seenEpoch = epoch;
    if (_revealed) {
      _revealed = false;
      _revealController.value = 0;
    }
  }

  Future<void> _reveal() async {
    if (_revealed) return;
    setState(() => _revealed = true);
    await _revealController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final privacy = ref.watch(privacySettingsProvider);
    final epoch = ref.watch(moneyRevealEpochProvider);
    _syncEpoch(epoch);

    final formatted = widget.compact
        ? AppFormatters.compactMoney(
            widget.cents,
            showKopecks: privacy.showKopecks,
          )
        : AppFormatters.money(widget.cents, showKopecks: privacy.showKopecks);
    final label = '${widget.prefix ?? ''}$formatted${widget.suffix ?? ''}';
    final style = widget.style ?? Theme.of(context).textTheme.bodyLarge;
    final hide = privacy.effectiveHideNumbers && !_revealed;
    final frost = widget.frost && privacy.effectiveTransparentBalance && !hide;

    Widget child = Text(
      label,
      style: style,
      textAlign: widget.textAlign,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
    );

    if (frost) {
      child = FrostedBalanceText(
        text: label,
        style: style,
        strength: privacy.transparencyStrength,
        textAlign: widget.textAlign,
        maxLines: widget.maxLines,
        overflow: widget.overflow,
      );
    }

    if (!privacy.effectiveHideNumbers) {
      return child;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: hide ? () => _reveal() : null,
      child: AnimatedBuilder(
        animation: _revealController,
        builder: (context, _) {
          final progress = Curves.easeOutCubic.transform(
            _revealController.value,
          );
          return Stack(
            alignment: Alignment.centerLeft,
            children: <Widget>[
              Opacity(opacity: progress, child: child),
              if (progress < 0.999)
                Positioned.fill(
                  child: Opacity(
                    opacity: 1 - progress,
                    child: IgnorePointer(
                      child: TelegramSpoilerMask(
                        style: style,
                        sampleText: label,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Engraved glass digits with directional bevels and a recessed center.
class FrostedBalanceText extends StatelessWidget {
  const FrostedBalanceText({
    required this.text,
    required this.style,
    required this.strength,
    this.textAlign,
    this.maxLines,
    this.overflow,
    super.key,
  });

  final String text;
  final TextStyle? style;
  final double strength;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.subberryTheme;
    final baseColor = style?.color ?? theme.colorScheme.onSurface;
    final resolvedStyle =
        style ?? theme.textTheme.bodyLarge ?? const TextStyle();
    return CustomPaint(
      painter: _EngravedGlassTextPainter(
        text: text,
        style: resolvedStyle,
        strength: strength.clamp(0.0, 1.0),
        baseColor: baseColor,
        highlightColor: Color.lerp(
          Colors.white,
          palette.primaryLight,
          theme.brightness == Brightness.dark ? 0.62 : 0.28,
        )!,
        recessColor: Color.lerp(
          theme.colorScheme.surface,
          palette.primaryDark,
          theme.brightness == Brightness.dark ? 0.55 : 0.2,
        )!,
        glowColor: palette.glowColor,
        textAlign: textAlign ?? TextAlign.start,
      ),
      child: Text(
        text,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        style: resolvedStyle.copyWith(color: Colors.transparent),
      ),
    );
  }
}

class _EngravedGlassTextPainter extends CustomPainter {
  const _EngravedGlassTextPainter({
    required this.text,
    required this.style,
    required this.strength,
    required this.baseColor,
    required this.highlightColor,
    required this.recessColor,
    required this.glowColor,
    required this.textAlign,
  });

  final String text;
  final TextStyle style;
  final double strength;
  final Color baseColor;
  final Color highlightColor;
  final Color recessColor;
  final Color glowColor;
  final TextAlign textAlign;

  TextPainter _painter(Paint foreground) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: style.copyWith(foreground: foreground),
      ),
      textDirection: TextDirection.ltr,
      textAlign: textAlign,
      maxLines: 1,
    );
  }

  void _paintText(Canvas canvas, Size size, Paint paint, Offset offset) {
    final painter = _painter(paint)..layout(maxWidth: size.width);
    final x = switch (textAlign) {
      TextAlign.center => (size.width - painter.width) / 2,
      TextAlign.right || TextAlign.end => size.width - painter.width,
      _ => 0.0,
    };
    painter.paint(
      canvas,
      Offset(x, (size.height - painter.height) / 2) + offset,
    );
  }

  void _paintDirectionalEdge({
    required Canvas canvas,
    required Size size,
    required Offset offset,
    required Color color,
    required double blur,
  }) {
    canvas.saveLayer(Offset.zero & size, Paint());
    _paintText(
      canvas,
      size,
      Paint()
        ..color = color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
      offset,
    );
    _paintText(
      canvas,
      size,
      Paint()
        ..color = Colors.black
        ..blendMode = BlendMode.dstOut,
      Offset.zero,
    );
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    // strength 0 = strongest glass (almost hidden), 1 = fully readable.
    final glassAmount = 1 - strength;
    final bounds = Offset.zero & size;

    // A diffuse halo gives the engraving volume without a uniform outline.
    _paintText(
      canvas,
      size,
      Paint()
        ..color = glowColor.withValues(alpha: 0.06 + glassAmount * 0.28)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          2.8 + glassAmount * 5.2,
        ),
      Offset.zero,
    );

    // Recessed lower-right wall inside each glyph.
    _paintText(
      canvas,
      size,
      Paint()
        ..color = recessColor.withValues(alpha: 0.14 + glassAmount * 0.52)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 0.55),
      Offset(0.85 + glassAmount * 0.85, 1.1 + glassAmount * 1.0),
    );

    // At minimum strength the vertical profile is 100→50→20→50→100, but
    // scaled down for a stronger dissolve. Raising strength flattens every
    // stop toward fully opaque readable text.
    double visibility(double glassStop) =>
        glassStop + (1 - glassStop) * strength;
    const edge = 0.42; // 100% of the glass profile
    const mid = 0.21; // 50%
    const center = 0.08; // 20%
    _paintText(
      canvas,
      size,
      Paint()
        ..shader = ui.Gradient.linear(
          bounds.topCenter,
          bounds.bottomCenter,
          <Color>[
            Color.lerp(
              baseColor,
              highlightColor,
              0.42 * glassAmount,
            )!.withValues(alpha: visibility(edge)),
            Color.lerp(
              baseColor,
              highlightColor,
              0.16 * glassAmount,
            )!.withValues(alpha: visibility(mid)),
            baseColor.withValues(alpha: visibility(center)),
            Color.lerp(
              baseColor,
              recessColor,
              0.12 * glassAmount,
            )!.withValues(alpha: visibility(mid)),
            Color.lerp(
              baseColor,
              recessColor,
              0.22 * glassAmount,
            )!.withValues(alpha: visibility(edge)),
          ],
          const <double>[0, 0.25, 0.5, 0.75, 1],
        ),
      Offset.zero,
    );

    // Differential masks leave bright and dark edges only where shifted
    // glyphs do not overlap, producing an asymmetric engraved bevel.
    _paintDirectionalEdge(
      canvas: canvas,
      size: size,
      offset: Offset(-0.75 - glassAmount * 0.85, -0.8 - glassAmount * 0.7),
      color: highlightColor.withValues(alpha: 0.28 + glassAmount * 0.55),
      blur: 0.25 + glassAmount * 0.55,
    );
    _paintDirectionalEdge(
      canvas: canvas,
      size: size,
      offset: Offset(0.75 + glassAmount * 0.65, 0.95 + glassAmount * 0.7),
      color: recessColor.withValues(alpha: 0.2 + glassAmount * 0.48),
      blur: 0.4 + glassAmount * 0.45,
    );
  }

  @override
  bool shouldRepaint(covariant _EngravedGlassTextPainter oldDelegate) {
    return oldDelegate.text != text ||
        oldDelegate.style != style ||
        oldDelegate.strength != strength ||
        oldDelegate.baseColor != baseColor ||
        oldDelegate.highlightColor != highlightColor ||
        oldDelegate.recessColor != recessColor ||
        oldDelegate.glowColor != glowColor ||
        oldDelegate.textAlign != textAlign;
  }
}

/// Animated Telegram-like spoiler made of drifting dots.
class TelegramSpoilerMask extends StatefulWidget {
  const TelegramSpoilerMask({
    required this.style,
    required this.sampleText,
    super.key,
  });

  final TextStyle? style;
  final String sampleText;

  @override
  State<TelegramSpoilerMask> createState() => _TelegramSpoilerMaskState();
}

class _TelegramSpoilerMaskState extends State<TelegramSpoilerMask>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      _elapsed = elapsed;
      setState(() {});
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.subberryTheme;
    final theme = Theme.of(context);
    final painter = TextPainter(
      text: TextSpan(text: widget.sampleText, style: widget.style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();

    return CustomPaint(
      size: Size(math.max(painter.width, 48), math.max(painter.height, 18)),
      painter: _SpoilerPainter(
        timeSeconds: _elapsed.inMilliseconds / 1000,
        seed: widget.sampleText.hashCode,
        dark: theme.brightness == Brightness.dark,
        primary: palette.primary,
        glow: palette.glowColor,
        muted: palette.mutedTextColor,
      ),
    );
  }
}

class _SpoilerPainter extends CustomPainter {
  _SpoilerPainter({
    required this.timeSeconds,
    required this.seed,
    required this.dark,
    required this.primary,
    required this.glow,
    required this.muted,
  });

  final double timeSeconds;
  final int seed;
  final bool dark;
  final Color primary;
  final Color glow;
  final Color muted;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    final count = math.max(28, (size.width * size.height / 18).round());
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < count; i++) {
      final baseX = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final speed = 0.55 + random.nextDouble() * 1.8;
      final radius = 0.7 + random.nextDouble() * 1.55;
      final phase = random.nextDouble() * math.pi * 2;
      final driftX =
          math.sin(timeSeconds * speed + phase) * (2.2 + random.nextDouble());
      final driftY =
          math.cos(timeSeconds * (speed * 0.85) + phase) *
          (1.6 + random.nextDouble());
      final pulse = 0.55 + 0.45 * math.sin(timeSeconds * 2.4 + phase * 1.7);
      final mix = random.nextDouble();
      final color = Color.lerp(
        muted,
        Color.lerp(primary, glow, mix)!,
        dark ? 0.35 + mix * 0.35 : 0.18 + mix * 0.28,
      )!;
      paint.color = color.withValues(alpha: (dark ? 0.42 : 0.55) * pulse);
      canvas.drawCircle(
        Offset((baseX + driftX) % size.width, (baseY + driftY) % size.height),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpoilerPainter oldDelegate) {
    return oldDelegate.timeSeconds != timeSeconds ||
        oldDelegate.dark != dark ||
        oldDelegate.primary != primary;
  }
}

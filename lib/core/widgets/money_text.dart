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

/// T-Bank-like frosted digits: outline stays, fill becomes milky glass.
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
    final t = strength.clamp(0.0, 1.0);
    // 0 → almost only contour/volume; 1 → fully readable fill.
    final fillAlpha = 0.06 + t * 0.94;
    final blurSigma = (1 - t) * 3.4;
    final outlineAlpha = 0.42 + (1 - t) * 0.28;
    final glassTint = Color.lerp(
      palette.glassTint,
      baseColor,
      0.35 + t * 0.45,
    )!;

    return Stack(
      alignment: Alignment.centerLeft,
      children: <Widget>[
        Text(
          text,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
          style: style?.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.35 + (1 - t) * 0.55
              ..color = Color.lerp(
                palette.borderColor,
                baseColor,
                0.55,
              )!.withValues(alpha: outlineAlpha),
          ),
        ),
        ImageFiltered(
          imageFilter: ui.ImageFilter.blur(
            sigmaX: blurSigma,
            sigmaY: blurSigma,
            tileMode: TileMode.decal,
          ),
          child: ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  glassTint.withValues(alpha: fillAlpha * 0.72),
                  baseColor.withValues(alpha: fillAlpha),
                  Color.lerp(
                    palette.primaryLight,
                    baseColor,
                    0.55,
                  )!.withValues(alpha: fillAlpha * 0.88),
                ],
                stops: const <double>[0, 0.48, 1],
              ).createShader(bounds);
            },
            child: Text(
              text,
              textAlign: textAlign,
              maxLines: maxLines,
              overflow: overflow,
              style: style?.copyWith(color: Colors.white),
            ),
          ),
        ),
        IgnorePointer(
          child: ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Colors.white.withValues(
                    alpha: theme.brightness == Brightness.dark
                        ? 0.08 + (1 - t) * 0.06
                        : 0.22 + (1 - t) * 0.12,
                  ),
                  Colors.transparent,
                  palette.primary.withValues(alpha: 0.04 + (1 - t) * 0.05),
                ],
              ).createShader(bounds);
            },
            child: Text(
              text,
              textAlign: textAlign,
              maxLines: maxLines,
              overflow: overflow,
              style: style?.copyWith(
                color: Colors.white.withValues(alpha: 0.01),
              ),
            ),
          ),
        ),
      ],
    );
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

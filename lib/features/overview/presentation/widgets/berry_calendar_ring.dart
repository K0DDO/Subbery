import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/color_palette.dart';
import '../../../subscriptions/presentation/subscription_visuals.dart';
import '../../../subscriptions/presentation/widgets/service_logo.dart';
import '../../application/overview_metrics.dart';

const _maxPeriodArcs = 4;

@visibleForTesting
class PeriodArcGroup {
  const PeriodArcGroup({required this.date, required this.occurrences});

  final DateTime date;
  final List<PaymentOccurrence> occurrences;

  int get count => occurrences.length;
  PaymentOccurrence get primary => occurrences.first;
}

@visibleForTesting
List<PeriodArcGroup> buildPeriodArcGroups(
  List<PaymentOccurrence> occurrences,
  DateTime now,
) {
  final today = DateTime(now.year, now.month, now.day);
  final firstBySubscription = <String, PaymentOccurrence>{};
  for (final occurrence in occurrences) {
    if (occurrence.date.isBefore(today)) continue;
    final current = firstBySubscription[occurrence.subscription.id];
    if (current == null || occurrence.date.isBefore(current.date)) {
      firstBySubscription[occurrence.subscription.id] = occurrence;
    }
  }

  final byDate = <DateTime, List<PaymentOccurrence>>{};
  for (final occurrence in firstBySubscription.values) {
    final date = DateTime(
      occurrence.date.year,
      occurrence.date.month,
      occurrence.date.day,
    );
    byDate.putIfAbsent(date, () => <PaymentOccurrence>[]).add(occurrence);
  }

  final groups =
      byDate.entries
          .map(
            (entry) =>
                PeriodArcGroup(date: entry.key, occurrences: entry.value),
          )
          .toList()
        ..sort((left, right) => left.date.compareTo(right.date));

  final visible = groups.take(_maxPeriodArcs).toList();
  // A payment due within three days pulses. Keep it last so its arc and icon
  // use the outermost radius and paint above every other subscription.
  visible.sort((left, right) {
    final leftIsSoon = left.date.difference(today).inDays <= 3;
    final rightIsSoon = right.date.difference(today).inDays <= 3;
    if (leftIsSoon != rightIsSoon) return leftIsSoon ? 1 : -1;
    return left.date.compareTo(right.date);
  });
  return visible;
}

class BerryCalendarRing extends StatefulWidget {
  const BerryCalendarRing({
    required this.year,
    required this.occurrences,
    required this.selectedMonth,
    required this.onMonthSelected,
    required this.now,
    this.periodArcOccurrences,
    this.showPeriodArcs = false,
    this.showCalendarLogos = true,
    super.key,
  });

  final int year;
  final List<PaymentOccurrence> occurrences;
  final int selectedMonth;
  final ValueChanged<int> onMonthSelected;
  final DateTime now;
  final List<PaymentOccurrence>? periodArcOccurrences;
  final bool showPeriodArcs;
  final bool showCalendarLogos;

  @override
  State<BerryCalendarRing> createState() => _BerryCalendarRingState();
}

class _BerryCalendarRingState extends State<BerryCalendarRing>
    with TickerProviderStateMixin {
  late final AnimationController _animationController;
  late final AnimationController _pulseController;
  bool _animationsDisabled = false;

  static const _monthNames = <String>[
    'январь',
    'февраль',
    'март',
    'апрель',
    'май',
    'июнь',
    'июль',
    'август',
    'сентябрь',
    'октябрь',
    'ноябрь',
    'декабрь',
  ];

  List<PaymentOccurrence> get _periodArcOccurrences =>
      widget.periodArcOccurrences ?? widget.occurrences;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animationsDisabled = MediaQuery.disableAnimationsOf(context);
    if (_animationsDisabled == animationsDisabled) {
      _syncPulseAnimation();
      return;
    }
    _animationsDisabled = animationsDisabled;
    _syncPulseAnimation();
  }

  @override
  void didUpdateWidget(covariant BerryCalendarRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameOccurrences(oldWidget.occurrences, widget.occurrences) ||
        !_sameOccurrences(
          oldWidget.periodArcOccurrences ?? oldWidget.occurrences,
          _periodArcOccurrences,
        )) {
      _animationController
        ..reset()
        ..forward();
    }
    _syncPulseAnimation();
  }

  void _syncPulseAnimation() {
    final today = DateTime(widget.now.year, widget.now.month, widget.now.day);
    final hasSoonPayment =
        widget.showPeriodArcs &&
        !_animationsDisabled &&
        _periodArcOccurrences.any((occurrence) {
          final days = occurrence.date.difference(today).inDays;
          return days >= 0 && days <= 3;
        });
    if (hasSoonPayment && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!hasSoonPayment &&
        (_pulseController.isAnimating || _pulseController.value != 0)) {
      _pulseController
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @visibleForTesting
  bool get debugPulseAnimating => _pulseController.isAnimating;

  ColorPalette _paletteFor(PaymentOccurrence occurrence) {
    final subscription = occurrence.subscription;
    return resolveSubscriptionVisual(
      name: subscription.name,
      logoKey: subscription.logo,
      category: subscription.category,
      brightness: Theme.of(context).brightness,
    ).palette;
  }

  Color _pulseColor(ColorPalette palette, double pulse) {
    if (pulse < 0.5) {
      return Color.lerp(palette.light, palette.primary, pulse * 2)!;
    }
    return Color.lerp(palette.primary, palette.dark, (pulse - 0.5) * 2)!;
  }

  void _handleTap(TapUpDetails details, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final delta = details.localPosition - center;
    var angle = -math.atan2(delta.dy, delta.dx) - math.pi / 2;
    if (angle < 0) angle += math.pi * 2;
    final month = (angle / (math.pi * 2) * 12).floor() + 1;
    widget.onMonthSelected(month.clamp(1, 12));
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final selected = widget.occurrences
        .where(
          (occurrence) =>
              occurrence.date.month == widget.selectedMonth &&
              occurrence.date.year == widget.year,
        )
        .toList(growable: false);
    final total = selected.fold<int>(
      0,
      (sum, occurrence) => sum + occurrence.subscription.priceInCents,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        var size = math.min(constraints.maxWidth, 340.0);
        if (constraints.maxHeight.isFinite) {
          size = math.min(size, constraints.maxHeight);
        }
        return Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) => _handleTap(details, Size.square(size)),
            child: SizedBox.square(
              dimension: size,
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: Listenable.merge(<Listenable>[
                        _animationController,
                        _pulseController,
                      ]),
                      builder: (context, child) {
                        final periodGroups = buildPeriodArcGroups(
                          _periodArcOccurrences,
                          widget.now,
                        );
                        final brandPalettes = <ColorPalette>[
                          for (final group in periodGroups)
                            _paletteFor(group.primary),
                        ];
                        return CustomPaint(
                          painter: _CalendarRingPainter(
                            year: widget.year,
                            occurrences: widget.occurrences,
                            periodArcOccurrences: _periodArcOccurrences,
                            selectedMonth: widget.selectedMonth,
                            now: widget.now,
                            showPeriodArcs: widget.showPeriodArcs,
                            progress: Curves.easeOutCubic.transform(
                              _animationController.value,
                            ),
                            pulse: _animationsDisabled
                                ? 0.5
                                : _pulseController.value,
                            textColor: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            trackColor: Theme.of(
                              context,
                            ).dividerColor.withValues(alpha: 0.45),
                            accentColor: primary,
                            brandPalettes: brandPalettes,
                          ),
                          child: child,
                        );
                      },
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 240),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(
                                scale: animation,
                                child: child,
                              ),
                            );
                          },
                          child: Column(
                            key: ValueKey<int>(widget.selectedMonth),
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                _monthNames[widget.selectedMonth - 1],
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${selected.length} '
                                '${_paymentWord(selected.length)}',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _compactMoney(total),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(color: primary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: Listenable.merge(<Listenable>[
                        _animationController,
                        _pulseController,
                      ]),
                      builder: (context, child) {
                        final progress = Curves.easeOutCubic.transform(
                          _animationController.value,
                        );
                        return Stack(
                          children: <Widget>[
                            if (widget.showCalendarLogos)
                              ..._buildCalendarIcons(size, progress),
                            if (widget.showPeriodArcs)
                              ..._buildPeriodIcons(
                                size,
                                progress,
                                _pulseController.value,
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildCalendarIcons(double size, double progress) {
    final center = Offset(size / 2, size / 2);
    final radius = size * 0.335;
    final today = DateTime(widget.now.year, widget.now.month, widget.now.day);
    final daysInYear = DateTime(
      widget.year + 1,
    ).difference(DateTime(widget.year)).inDays;
    final sameDayCount = <int, int>{};
    final icons = <Widget>[];
    for (final occurrence in widget.occurrences) {
      if (occurrence.date.isBefore(today)) continue;
      final day = occurrence.date.difference(DateTime(widget.year)).inDays;
      if (day < 0 || day >= daysInYear) continue;
      final stackIndex = sameDayCount.update(
        day,
        (value) => value + 1,
        ifAbsent: () => 0,
      );
      if (stackIndex > 2) continue;
      const iconSize = 14.0;
      // Same-day icons fan out along the ring instead of stacking outward.
      final angle =
          -math.pi / 2 -
          day / daysInYear * math.pi * 2 -
          stackIndex * iconSize * 0.85 / radius;
      final point =
          center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
      icons.add(
        Positioned(
          left: point.dx - iconSize / 2,
          top: point.dy - iconSize / 2,
          child: IgnorePointer(
            child: Opacity(
              opacity: progress,
              child: Transform.scale(
                scale: 0.65 + progress * 0.35,
                child: ServiceLogo(
                  name: occurrence.subscription.name,
                  logoKey: occurrence.subscription.logo,
                  category: occurrence.subscription.category,
                  size: iconSize,
                ),
              ),
            ),
          ),
        ),
      );
    }
    return icons;
  }

  List<Widget> _buildPeriodIcons(double size, double progress, double pulse) {
    final periods = buildPeriodArcGroups(_periodArcOccurrences, widget.now);
    if (periods.isEmpty) return const <Widget>[];
    final center = Offset(size / 2, size / 2);
    final outerRadius = size * 0.335;
    final innermostRadius = size * 0.205;
    final outermostRadius = outerRadius - 24;
    final spacing = periods.length == 1
        ? 0.0
        : (outermostRadius - innermostRadius) / (periods.length - 1);
    final daysInYear = DateTime(
      widget.year + 1,
    ).difference(DateTime(widget.year)).inDays;

    return <Widget>[
      for (var index = 0; index < periods.length; index++)
        _periodIcon(
          group: periods[index],
          center: center,
          radius: innermostRadius + spacing * index,
          daysInYear: daysInYear,
          progress: progress,
          pulse: pulse,
        ),
    ];
  }

  Widget _periodIcon({
    required PeriodArcGroup group,
    required Offset center,
    required double radius,
    required int daysInYear,
    required double progress,
    required double pulse,
  }) {
    final today = DateTime(widget.now.year, widget.now.month, widget.now.day);
    final todayIndex = today.difference(DateTime(widget.year)).inDays;
    final daysUntil = group.date.difference(today).inDays.clamp(0, daysInYear);
    final arcStart = -math.pi / 2 - todayIndex / daysInYear * math.pi * 2;
    final angle = arcStart - daysUntil / daysInYear * math.pi * 2 * progress;
    final point =
        center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
    const iconSize = 18.0;
    final isSoon = daysUntil <= 3;
    final palette = _paletteFor(group.primary);
    final pulsed = isSoon ? _pulseColor(palette, pulse) : palette.primary;
    final borderColor = isSoon
        ? pulsed.withValues(alpha: 0.7 + pulse * 0.3)
        : Colors.white.withValues(alpha: 0.72);
    final subscription = group.primary.subscription;
    return Positioned(
      left: point.dx - iconSize / 2,
      top: point.dy - iconSize / 2,
      child: IgnorePointer(
        child: Opacity(
          opacity: progress,
          child: Transform.scale(
            scale: 0.65 + progress * 0.35 + (isSoon ? pulse * 0.04 : 0),
            child: Container(
              width: iconSize,
              height: iconSize,
              padding: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: borderColor,
                  width: isSoon ? 1.4 + pulse * 0.8 : 1,
                ),
                color: group.count > 1
                    ? pulsed.withValues(alpha: 0.92)
                    : null,
                boxShadow: isSoon
                    ? <BoxShadow>[
                        BoxShadow(
                          color: palette.glow.withValues(
                            alpha: 0.25 + pulse * 0.35,
                          ),
                          blurRadius: 8 + pulse * 8,
                        ),
                      ]
                    : null,
              ),
              child: group.count > 1
                  ? Center(
                      child: Text(
                        '${group.count}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    )
                  : ServiceLogo(
                      name: subscription.name,
                      logoKey: subscription.logo,
                      category: subscription.category,
                      size: 13,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  bool _sameOccurrences(
    List<PaymentOccurrence> left,
    List<PaymentOccurrence> right,
  ) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index].subscription.id != right[index].subscription.id ||
          left[index].date != right[index].date) {
        return false;
      }
    }
    return true;
  }

  static String _paymentWord(int count) {
    final mod10 = count % 10;
    final mod100 = count % 100;
    if (mod10 == 1 && mod100 != 11) return 'платёж';
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
      return 'платежа';
    }
    return 'платежей';
  }

  static String _compactMoney(int cents) {
    final rubles = cents / 100;
    if (rubles >= 1000) {
      return '${(rubles / 1000).toStringAsFixed(rubles % 1000 == 0 ? 0 : 1)} тыс. ₽';
    }
    return '${rubles.toStringAsFixed(cents % 100 == 0 ? 0 : 2)} ₽';
  }
}

class _CalendarRingPainter extends CustomPainter {
  const _CalendarRingPainter({
    required this.year,
    required this.occurrences,
    required this.periodArcOccurrences,
    required this.selectedMonth,
    required this.now,
    required this.showPeriodArcs,
    required this.progress,
    required this.pulse,
    required this.textColor,
    required this.trackColor,
    required this.accentColor,
    required this.brandPalettes,
  });

  final int year;
  final List<PaymentOccurrence> occurrences;
  final List<PaymentOccurrence> periodArcOccurrences;
  final int selectedMonth;
  final DateTime now;
  final bool showPeriodArcs;
  final double progress;
  final double pulse;
  final Color textColor;
  final Color trackColor;
  final Color accentColor;
  final List<ColorPalette> brandPalettes;

  static const _shortMonths = <String>[
    'янв',
    'фев',
    'мар',
    'апр',
    'май',
    'июн',
    'июл',
    'авг',
    'сен',
    'окт',
    'ноя',
    'дек',
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.335;
    final ringRect = Rect.fromCircle(center: center, radius: radius);
    const start = -math.pi / 2;
    const segment = math.pi * 2 / 12;
    const gap = 0.045;

    for (var index = 0; index < 12; index++) {
      final selected = index + 1 == selectedMonth;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 24 : 18
        ..strokeCap = StrokeCap.round
        ..color = selected ? accentColor.withValues(alpha: 0.95) : trackColor;
      canvas.drawArc(
        ringRect,
        start - index * segment - gap,
        -(segment - gap * 2) * progress,
        false,
        paint,
      );

      final labelAngle = start - (index + 0.5) * segment;
      final labelOffset =
          center +
          Offset(
            math.cos(labelAngle) * (radius + 31),
            math.sin(labelAngle) * (radius + 31),
          );
      final textPainter = TextPainter(
        text: TextSpan(
          text: _shortMonths[index],
          style: TextStyle(
            color: selected ? accentColor : textColor,
            fontSize: 10,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        labelOffset - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }

    final daysInYear = DateTime(year + 1).difference(DateTime(year)).inDays;
    if (showPeriodArcs) {
      _paintPeriodArcs(
        canvas: canvas,
        size: size,
        center: center,
        outerRadius: radius,
        start: start,
        daysInYear: daysInYear,
      );
    }
  }

  void _paintPeriodArcs({
    required Canvas canvas,
    required Size size,
    required Offset center,
    required double outerRadius,
    required double start,
    required int daysInYear,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final periods = buildPeriodArcGroups(periodArcOccurrences, now);
    if (periods.isEmpty) return;

    final innermostRadius = size.width * 0.205;
    final outermostRadius = outerRadius - 24;
    final spacing = periods.length == 1
        ? 0.0
        : (outermostRadius - innermostRadius) / (periods.length - 1);
    final todayIndex = today
        .difference(DateTime(year))
        .inDays
        .clamp(0, daysInYear - 1);
    final arcStart = start - todayIndex / daysInYear * math.pi * 2;

    for (var index = 0; index < periods.length; index++) {
      final group = periods[index];
      final periodRadius = innermostRadius + spacing * index;
      final rect = Rect.fromCircle(center: center, radius: periodRadius);
      final daysUntil = group.date
          .difference(today)
          .inDays
          .clamp(0, daysInYear);
      final sweep = -daysUntil / daysInYear * math.pi * 2;
      final palette = index < brandPalettes.length
          ? brandPalettes[index]
          : ColorPalette.fromSeed(accentColor);
      final isSoon = daysUntil <= 3;
      final color = isSoon
          ? (pulse < 0.5
                ? Color.lerp(palette.light, palette.primary, pulse * 2)!
                : Color.lerp(palette.primary, palette.dark, (pulse - 0.5) * 2)!)
          : palette.primary;
      final strokeWidth = isSoon ? 4.2 + pulse * 1.4 : 4.0;

      canvas.drawArc(
        rect,
        arcStart,
        sweep * progress,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(
            alpha: (isSoon ? 0.72 + pulse * 0.2 : 0.82) * progress,
          )
          ..maskFilter = isSoon
              ? MaskFilter.blur(BlurStyle.normal, 1.5 + pulse * 2.5)
              : null,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CalendarRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.pulse != pulse ||
        oldDelegate.selectedMonth != selectedMonth ||
        oldDelegate.occurrences != occurrences ||
        oldDelegate.periodArcOccurrences != periodArcOccurrences ||
        oldDelegate.now != now ||
        oldDelegate.showPeriodArcs != showPeriodArcs ||
        oldDelegate.textColor != textColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.brandPalettes != brandPalettes;
  }
}

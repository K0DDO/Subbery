import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../subscriptions/presentation/subscription_ui_extensions.dart';
import '../../../subscriptions/presentation/widgets/service_logo.dart';
import '../../application/overview_metrics.dart';

const _maxPeriodArcs = 4;

List<PaymentOccurrence> _periodOccurrences(
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
  final periods = firstBySubscription.values.toList()
    ..sort((left, right) => left.date.compareTo(right.date));
  final nearest = periods.take(_maxPeriodArcs).toList()
    ..sort((left, right) => right.date.compareTo(left.date));
  return nearest;
}

class BerryCalendarRing extends StatefulWidget {
  const BerryCalendarRing({
    required this.year,
    required this.occurrences,
    required this.selectedMonth,
    required this.onMonthSelected,
    required this.now,
    this.showPeriodArcs = false,
    super.key,
  });

  final int year;
  final List<PaymentOccurrence> occurrences;
  final int selectedMonth;
  final ValueChanged<int> onMonthSelected;
  final DateTime now;
  final bool showPeriodArcs;

  @override
  State<BerryCalendarRing> createState() => _BerryCalendarRingState();
}

class _BerryCalendarRingState extends State<BerryCalendarRing>
    with TickerProviderStateMixin {
  late final AnimationController _animationController;
  late final AnimationController _pulseController;

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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _syncPulseAnimation();
  }

  @override
  void didUpdateWidget(covariant BerryCalendarRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameOccurrences(oldWidget.occurrences, widget.occurrences)) {
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
        widget.occurrences.any((occurrence) {
          final days = occurrence.date.difference(today).inDays;
          return days >= 0 && days <= 3;
        });
    if (hasSoonPayment && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!hasSoonPayment && _pulseController.isAnimating) {
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
    final selected = widget.occurrences
        .where((occurrence) => occurrence.date.month == widget.selectedMonth)
        .toList(growable: false);
    final total = selected.fold<int>(
      0,
      (sum, occurrence) => sum + occurrence.subscription.priceInCents,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, 340.0);
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
                      animation: _animationController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: _CalendarRingPainter(
                            year: widget.year,
                            occurrences: widget.occurrences,
                            selectedMonth: widget.selectedMonth,
                            now: widget.now,
                            showPeriodArcs: widget.showPeriodArcs,
                            progress: Curves.easeOutCubic.transform(
                              _animationController.value,
                            ),
                            textColor: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            trackColor: Theme.of(
                              context,
                            ).dividerColor.withValues(alpha: 0.45),
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
                                    ?.copyWith(color: AppColors.coral),
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
                          children: widget.showPeriodArcs
                              ? _buildPeriodIcons(
                                  size,
                                  progress,
                                  _pulseController.value,
                                )
                              : _buildCalendarIcons(size, progress),
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
    final daysInYear = DateTime(
      widget.year + 1,
    ).difference(DateTime(widget.year)).inDays;
    final sameDayCount = <int, int>{};
    final icons = <Widget>[];
    for (final occurrence in widget.occurrences) {
      final day = occurrence.date.difference(DateTime(widget.year)).inDays;
      if (day < 0 || day >= daysInYear) continue;
      final stackIndex = sameDayCount.update(
        day,
        (value) => value + 1,
        ifAbsent: () => 0,
      );
      if (stackIndex > 2) continue;
      final angle = -math.pi / 2 - day / daysInYear * math.pi * 2;
      final pointRadius = radius + 2 + stackIndex * 10;
      final point =
          center +
          Offset(math.cos(angle) * pointRadius, math.sin(angle) * pointRadius);
      const iconSize = 14.0;
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
    final periods = _periodOccurrences(widget.occurrences, widget.now);
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
          occurrence: periods[index],
          center: center,
          radius: innermostRadius + spacing * index,
          daysInYear: daysInYear,
          progress: progress,
          pulse: pulse,
        ),
    ];
  }

  Widget _periodIcon({
    required PaymentOccurrence occurrence,
    required Offset center,
    required double radius,
    required int daysInYear,
    required double progress,
    required double pulse,
  }) {
    final today = DateTime(widget.now.year, widget.now.month, widget.now.day);
    final todayIndex = today.difference(DateTime(widget.year)).inDays;
    final daysUntil = occurrence.date
        .difference(today)
        .inDays
        .clamp(0, daysInYear);
    final arcStart = -math.pi / 2 - todayIndex / daysInYear * math.pi * 2;
    final angle = arcStart - daysUntil / daysInYear * math.pi * 2 * progress;
    final point =
        center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
    const iconSize = 18.0;
    final isSoon = daysUntil <= 3;
    final borderColor = isSoon
        ? Color.lerp(const Color(0xFFFF8A80), const Color(0xFF8B1020), pulse)!
        : Colors.white.withValues(alpha: 0.72);
    return Positioned(
      left: point.dx - iconSize / 2,
      top: point.dy - iconSize / 2,
      child: IgnorePointer(
        child: Opacity(
          opacity: progress,
          child: Transform.scale(
            scale: 0.65 + progress * 0.35,
            child: Container(
              width: iconSize,
              height: iconSize,
              padding: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: borderColor, width: isSoon ? 1.8 : 1),
              ),
              child: ServiceLogo(
                name: occurrence.subscription.name,
                logoKey: occurrence.subscription.logo,
                category: occurrence.subscription.category,
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
    required this.selectedMonth,
    required this.now,
    required this.showPeriodArcs,
    required this.progress,
    required this.textColor,
    required this.trackColor,
  });

  final int year;
  final List<PaymentOccurrence> occurrences;
  final int selectedMonth;
  final DateTime now;
  final bool showPeriodArcs;
  final double progress;
  final Color textColor;
  final Color trackColor;

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
        ..color = selected
            ? AppColors.coral.withValues(alpha: 0.95)
            : trackColor;
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
            color: selected ? AppColors.coral : textColor,
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
    final periods = _periodOccurrences(occurrences, now);
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
      final occurrence = periods[index];
      final periodRadius = innermostRadius + spacing * index;
      final rect = Rect.fromCircle(center: center, radius: periodRadius);
      final daysUntil = occurrence.date
          .difference(today)
          .inDays
          .clamp(0, daysInYear);
      final sweep = -daysUntil / daysInYear * math.pi * 2;
      final color = occurrence.subscription.category.color;

      canvas.drawArc(
        rect,
        arcStart,
        sweep * progress,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: 0.82 * progress),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CalendarRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.selectedMonth != selectedMonth ||
        oldDelegate.occurrences != occurrences ||
        oldDelegate.now != now ||
        oldDelegate.showPeriodArcs != showPeriodArcs ||
        oldDelegate.textColor != textColor ||
        oldDelegate.trackColor != trackColor;
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../subscriptions/presentation/subscription_ui_extensions.dart';
import '../../application/overview_metrics.dart';

class BerryCalendarRing extends StatefulWidget {
  const BerryCalendarRing({
    required this.year,
    required this.occurrences,
    required this.selectedMonth,
    required this.onMonthSelected,
    super.key,
  });

  final int year;
  final List<PaymentOccurrence> occurrences;
  final int selectedMonth;
  final ValueChanged<int> onMonthSelected;

  @override
  State<BerryCalendarRing> createState() => _BerryCalendarRingState();
}

class _BerryCalendarRingState extends State<BerryCalendarRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

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
  }

  @override
  void didUpdateWidget(covariant BerryCalendarRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.occurrences != widget.occurrences) {
      _animationController
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap(TapUpDetails details, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final delta = details.localPosition - center;
    var angle = math.atan2(delta.dy, delta.dx) + math.pi / 2;
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
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _CalendarRingPainter(
                      year: widget.year,
                      occurrences: widget.occurrences,
                      selectedMonth: widget.selectedMonth,
                      progress: Curves.easeOutCubic.transform(
                        _animationController.value,
                      ),
                      textColor: Theme.of(context).colorScheme.onSurfaceVariant,
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
                        child: ScaleTransition(scale: animation, child: child),
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
                          '${selected.length} ${_paymentWord(selected.length)}',
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
          ),
        );
      },
    );
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
    required this.progress,
    required this.textColor,
    required this.trackColor,
  });

  final int year;
  final List<PaymentOccurrence> occurrences;
  final int selectedMonth;
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
        ..strokeWidth = selected ? 18 : 12
        ..strokeCap = StrokeCap.round
        ..color = selected
            ? AppColors.coral.withValues(alpha: 0.95)
            : trackColor;
      canvas.drawArc(
        ringRect,
        start + index * segment + gap,
        (segment - gap * 2) * progress,
        false,
        paint,
      );

      final labelAngle = start + (index + 0.5) * segment;
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
    final sameDayCount = <int, int>{};
    for (final occurrence in occurrences) {
      final day = occurrence.date.difference(DateTime(year)).inDays;
      if (day < 0 || day >= daysInYear) continue;
      final stackIndex = sameDayCount.update(
        day,
        (value) => value + 1,
        ifAbsent: () => 0,
      );
      final angle = start + (day / daysInYear) * math.pi * 2;
      final pointRadius = radius + 2 + stackIndex * 6;
      final point =
          center +
          Offset(math.cos(angle) * pointRadius, math.sin(angle) * pointRadius);
      final color = occurrence.subscription.category.color;
      canvas.drawCircle(
        point,
        5.2 * progress,
        Paint()..color = color.withValues(alpha: progress),
      );
      canvas.drawCircle(
        point,
        5.2 * progress,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = Colors.white.withValues(alpha: 0.8 * progress),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CalendarRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.selectedMonth != selectedMonth ||
        oldDelegate.occurrences != occurrences ||
        oldDelegate.textColor != textColor ||
        oldDelegate.trackColor != trackColor;
  }
}

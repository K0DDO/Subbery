import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/models/monthly_spend_point.dart';
import '../../../../core/theme/app_accent_theme.dart';

class SpendingBarChart extends StatelessWidget {
  const SpendingBarChart({
    required this.points,
    this.onBarSelected,
    this.height = 190,
    super.key,
  });

  final List<MonthlySpendPoint> points;
  final ValueChanged<MonthlySpendPoint>? onBarSelected;
  final double height;

  static const _months = <String>[
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
  Widget build(BuildContext context) {
    final accent = context.accentTheme;
    final maxAmount = points.fold<int>(
      0,
      (maximum, point) => math.max(
        maximum,
        math.max(point.amountInCents, point.plannedAmountInCents),
      ),
    );
    final maxY = math.max(maxAmount / 100 * 1.22, 100).toDouble();

    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _ChartLegend(label: 'Факт', color: accent.primary, filled: true),
            const SizedBox(width: 18),
            _ChartLegend(label: 'План', color: accent.secondary, filled: false),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: height,
          child: BarChart(
            BarChartData(
              minY: 0,
              maxY: maxY,
              alignment: BarChartAlignment.spaceAround,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY / 3,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.45),
                  strokeWidth: 1,
                  dashArray: <int>[4, 5],
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= points.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _months[points[index].month.month - 1],
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                enabled: true,
                handleBuiltInTouches: true,
                touchCallback: (event, response) {
                  if (onBarSelected == null) return;
                  if (!event.isInterestedForInteractions) return;
                  final spot = response?.spot;
                  if (spot == null) return;
                  if (event is! FlTapUpEvent) return;
                  final index = spot.touchedBarGroupIndex;
                  if (index < 0 || index >= points.length) return;
                  onBarSelected!(points[index]);
                },
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) =>
                      Theme.of(context).colorScheme.inverseSurface,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final label = rodIndex == 0 ? 'Факт' : 'План';
                    return BarTooltipItem(
                      '$label\n${rod.toY.round()} ₽',
                      TextStyle(
                        color: Theme.of(context).colorScheme.onInverseSurface,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    );
                  },
                ),
              ),
              barGroups: <BarChartGroupData>[
                for (var index = 0; index < points.length; index++)
                  BarChartGroupData(
                    x: index,
                    barsSpace: 4,
                    barRods: <BarChartRodData>[
                      BarChartRodData(
                        toY: points[index].amountInCents / 100,
                        width: 10,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(7),
                          bottom: Radius.circular(3),
                        ),
                        gradient: accent.gradient,
                      ),
                      BarChartRodData(
                        toY: points[index].plannedAmountInCents / 100,
                        width: 10,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(7),
                          bottom: Radius.circular(3),
                        ),
                        color: accent.secondary.withValues(alpha: 0.2),
                        borderSide: BorderSide(
                          color: accent.secondary.withValues(alpha: 0.9),
                          width: 1.5,
                        ),
                      ),
                    ],
                    showingTooltipIndicators: const <int>[],
                  ),
              ],
            ),
            duration: const Duration(milliseconds: 750),
            curve: Curves.easeOutCubic,
          ),
        ),
      ],
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({
    required this.label,
    required this.color,
    required this.filled,
  });

  final String label;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: filled ? null : color.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(5),
            border: filled ? null : Border.all(color: color, width: 1.5),
            gradient: filled
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[color, color.withValues(alpha: 0.65)],
                  )
                : null,
          ),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

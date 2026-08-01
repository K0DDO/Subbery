import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/models/monthly_spend_point.dart';
import '../../../../core/theme/app_accent_theme.dart';

class SpendingBarChart extends StatelessWidget {
  const SpendingBarChart({
    required this.points,
    this.onBarSelected,
    super.key,
  });

  final List<MonthlySpendPoint> points;
  final ValueChanged<MonthlySpendPoint>? onBarSelected;

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
      (maximum, point) => math.max(maximum, point.amountInCents),
    );
    final maxY = math.max(maxAmount / 100 * 1.22, 100).toDouble();

    return SizedBox(
      height: 190,
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
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                return BarTooltipItem(
                  '${rod.toY.round()} ₽',
                  TextStyle(
                    color: Theme.of(context).colorScheme.onInverseSurface,
                    fontWeight: FontWeight.w700,
                  ),
                );
              },
            ),
          ),
          barGroups: <BarChartGroupData>[
            for (var index = 0; index < points.length; index++)
              BarChartGroupData(
                x: index,
                barRods: <BarChartRodData>[
                  BarChartRodData(
                    toY: points[index].amountInCents / 100,
                    width: 18,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(9),
                      bottom: Radius.circular(4),
                    ),
                    gradient: accent.gradient,
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: maxY,
                      color: Theme.of(
                        context,
                      ).dividerColor.withValues(alpha: 0.18),
                    ),
                  ),
                ],
              ),
          ],
        ),
        duration: const Duration(milliseconds: 750),
        curve: Curves.easeOutCubic,
      ),
    );
  }
}

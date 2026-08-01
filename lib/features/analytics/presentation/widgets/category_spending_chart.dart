import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../subscriptions/presentation/subscription_ui_extensions.dart';
import '../../application/analytics_metrics.dart';

class CategorySpendingChart extends StatelessWidget {
  const CategorySpendingChart({
    required this.categories,
    this.onCategorySelected,
    super.key,
  });

  final List<CategorySpend> categories;
  final ValueChanged<CategorySpend>? onCategorySelected;

  @override
  Widget build(BuildContext context) {
    final total = categories.fold<int>(
      0,
      (sum, category) => sum + category.amountInCents,
    );

    return Column(
      children: <Widget>[
        SizedBox(
          height: 190,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              PieChart(
                PieChartData(
                  centerSpaceRadius: 58,
                  sectionsSpace: 4,
                  startDegreeOffset: -90,
                  borderData: FlBorderData(show: false),
                  pieTouchData: PieTouchData(
                    enabled: onCategorySelected != null,
                    touchCallback: (event, response) {
                      if (onCategorySelected == null) return;
                      if (event is! FlTapUpEvent) return;
                      final index =
                          response?.touchedSection?.touchedSectionIndex;
                      if (index == null ||
                          index < 0 ||
                          index >= categories.length) {
                        return;
                      }
                      onCategorySelected!(categories[index]);
                    },
                  ),
                  sections: <PieChartSectionData>[
                    for (final category in categories)
                      PieChartSectionData(
                        value: category.amountInCents.toDouble(),
                        color: category.category.color,
                        radius: 30,
                        showTitle: false,
                        badgePositionPercentageOffset: 0.98,
                      ),
                  ],
                ),
                duration: const Duration(milliseconds: 750),
                curve: Curves.easeOutCubic,
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'В месяц',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppFormatters.money(total),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            for (final category in categories)
              _LegendItem(
                category: category,
                onTap: onCategorySelected == null
                    ? null
                    : () => onCategorySelected!(category),
              ),
          ],
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.category, this.onTap});

  final CategorySpend category;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: category.category.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          category.category.label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxs,
          vertical: AppSpacing.xxs,
        ),
        child: row,
      ),
    );
  }
}

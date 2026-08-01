import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_accent_theme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../widgets/morphing_sheet/sheet_page_navigator.dart';
import '../../../shell/presentation/hotbar_morph_sheet.dart';
import '../../domain/entities/subscription.dart';
import '../subscription_ui_extensions.dart';

const int _columns = 2;
const double _tileExtent = 64;
const double _tileSpacing = AppSpacing.xs;

@visibleForTesting
double categoryPickerMaxHeight(double screenHeight) =>
    math.min(460, screenHeight * 0.9);

Future<SubscriptionCategory?> showCategoryPickerSheet({
  required BuildContext context,
  required SubscriptionCategory selected,
}) {
  final screenHeight = MediaQuery.sizeOf(context).height;
  return showHotbarMorphSheet<SubscriptionCategory>(
    context: context,
    maximumHeight: categoryPickerMaxHeight(screenHeight),
    builder: (sheetContext) => MorphingSheetNavigator(
      home: CategoryPickerSheet(
        selected: selected,
        onSelected: (category) => Navigator.of(sheetContext).pop(category),
      ),
    ),
  );
}

class CategoryPickerSheet extends StatelessWidget {
  const CategoryPickerSheet({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final SubscriptionCategory selected;
  final ValueChanged<SubscriptionCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = SubscriptionCategory.values;
    final rows = (categories.length / _columns).ceil();

    return Material(
      type: MaterialType.transparency,
      child: SingleChildScrollView(
        primary: false,
        physics: const NeverScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            48,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Выберите категорию',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const ValueKey<String>('category-picker-close'),
                    tooltip: 'Закрыть',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              SizedBox(
                height: rows * _tileExtent + (rows - 1) * _tileSpacing,
                child: GridView.builder(
                  key: const ValueKey<String>('category-picker-grid'),
                  padding: EdgeInsets.zero,
                  primary: false,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _columns,
                    mainAxisExtent: _tileExtent,
                    crossAxisSpacing: _tileSpacing,
                    mainAxisSpacing: _tileSpacing,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return _CategoryTile(
                      category: category,
                      selected: category == selected,
                      onTap: () => onSelected(category),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final SubscriptionCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subberry = context.subberryTheme;
    final accent = category.color(context);

    return Semantics(
      button: true,
      selected: selected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          color: selected
              ? accent.withValues(alpha: 0.18)
              : subberry.glassTint.withValues(alpha: 0.42),
          border: Border.all(color: selected ? accent : subberry.borderColor),
          boxShadow: selected
              ? <BoxShadow>[
                  BoxShadow(
                    color: category.glow(context).withValues(alpha: 0.28),
                    blurRadius: 14,
                  ),
                ]
              : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            key: ValueKey<String>('category-picker-${category.name}'),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Row(
                children: <Widget>[
                  Text(category.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      category.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: selected
                            ? accent
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                  if (selected)
                    Icon(Icons.check_rounded, size: 18, color: accent),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

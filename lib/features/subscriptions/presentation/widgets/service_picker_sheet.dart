import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_accent_theme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../shell/presentation/hotbar_morph_sheet.dart';
import '../../data/catalog/known_services.dart';
import '../../domain/entities/subscription.dart';
import '../subscription_ui_extensions.dart';
import 'service_logo.dart';

@visibleForTesting
List<KnownService> filterKnownServices({
  required String query,
  SubscriptionCategory? category,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  return KnownServices.all
      .where((service) {
        final matchesQuery =
            normalizedQuery.isEmpty ||
            service.name.toLowerCase().contains(normalizedQuery);
        final matchesCategory =
            category == null || service.category == category;
        return matchesQuery && matchesCategory;
      })
      .toList(growable: false);
}

Future<KnownService?> showServicePickerSheet({
  required BuildContext context,
  required String initialQuery,
  required ValueChanged<String> onQueryChanged,
}) {
  final screenHeight = MediaQuery.sizeOf(context).height;
  return showHotbarMorphSheet<KnownService>(
    context: context,
    maximumHeight: math.min(680, screenHeight * 0.82),
    builder: (sheetContext) => ServicePickerSheet(
      initialQuery: initialQuery,
      onQueryChanged: onQueryChanged,
      onSelected: (service) => Navigator.of(sheetContext).pop(service),
    ),
  );
}

class ServicePickerSheet extends StatefulWidget {
  const ServicePickerSheet({
    required this.initialQuery,
    required this.onQueryChanged,
    required this.onSelected,
    super.key,
  });

  final String initialQuery;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<KnownService> onSelected;

  @override
  State<ServicePickerSheet> createState() => _ServicePickerSheetState();
}

class _ServicePickerSheetState extends State<ServicePickerSheet> {
  late final TextEditingController _searchController;
  SubscriptionCategory? _category;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    widget.onQueryChanged(value);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subberry = context.subberryTheme;
    final services = filterKnownServices(
      query: _searchController.text,
      category: _category,
    );
    final rows = math.max(1, (services.length / 3).ceil());
    final availableHeight = math.min(
      680.0,
      MediaQuery.sizeOf(context).height * 0.82,
    );
    final maxGridHeight = math.min(
      324.0,
      math.max(108.0, availableHeight - 300),
    );
    final gridHeight = math.min(rows * 108.0, maxGridHeight);

    return Material(
      type: MaterialType.transparency,
      child: SingleChildScrollView(
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
                      'Выберите сервис',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const ValueKey<String>('service-picker-close'),
                    tooltip: 'Закрыть',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                key: const ValueKey<String>('service-picker-search'),
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Поиск сервиса',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: subberry.primary,
                  ),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Очистить',
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _CategoryGrid(
                selected: _category,
                onSelected: (category) {
                  setState(() {
                    _category = _category == category ? null : category;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              AnimatedSize(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeInOutCubic,
                alignment: Alignment.topCenter,
                child: SizedBox(
                  key: const ValueKey<String>('service-picker-grid-viewport'),
                  height: gridHeight,
                  child: services.isEmpty
                      ? Center(
                          child: Text(
                            'Сервисы не найдены',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : GridView.builder(
                          key: const ValueKey<String>('service-picker-grid'),
                          padding: EdgeInsets.zero,
                          physics: rows * 108.0 > maxGridHeight
                              ? const BouncingScrollPhysics()
                              : const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisExtent: 108,
                                crossAxisSpacing: AppSpacing.xs,
                                mainAxisSpacing: AppSpacing.xs,
                              ),
                          itemCount: services.length,
                          itemBuilder: (context, index) {
                            final service = services[index];
                            return _ServiceAppCell(
                              service: service,
                              onTap: () => widget.onSelected(service),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.selected, required this.onSelected});

  final SubscriptionCategory? selected;
  final ValueChanged<SubscriptionCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subberry = context.subberryTheme;
    return SizedBox(
      height: 84,
      child: GridView.builder(
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisExtent: 40,
          crossAxisSpacing: AppSpacing.xxs,
          mainAxisSpacing: AppSpacing.xxs,
        ),
        itemCount: SubscriptionCategory.values.length,
        itemBuilder: (context, index) {
          final category = SubscriptionCategory.values[index];
          final isSelected = selected == category;
          return Material(
            color: isSelected
                ? subberry.primary.withValues(alpha: 0.18)
                : subberry.softBackgroundTint.withValues(alpha: 0.34),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: InkWell(
              key: ValueKey<String>('service-category-${category.name}'),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              onTap: () => onSelected(category),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: isSelected ? subberry.primary : subberry.borderColor,
                  ),
                ),
                child: Text(
                  '${category.emoji} ${category.label}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isSelected
                        ? subberry.primary
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ServiceAppCell extends StatelessWidget {
  const _ServiceAppCell({required this.service, required this.onTap});

  final KnownService service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subberry = context.subberryTheme;
    return Semantics(
      button: true,
      label: 'Выбрать ${service.name}',
      child: InkWell(
        key: ValueKey<String>('service-app-${service.logoKey}'),
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxs,
            vertical: AppSpacing.xs,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              ServiceLogo(
                name: service.name,
                logoKey: service.logoKey,
                category: service.category,
                size: 64,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                service.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                  shadows: <Shadow>[
                    Shadow(
                      color: subberry.glowColor.withValues(alpha: 0.14),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

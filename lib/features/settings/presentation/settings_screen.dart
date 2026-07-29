import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/screen_header.dart';
import '../../notifications/application/notification_settings_controller.dart';
import '../../shell/application/tab_reset_provider.dart';
import '../application/app_icon_controller.dart';
import '../application/theme_mode_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _setNotifications(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    final result = await ref
        .read(notificationSettingsProvider.notifier)
        .setEnabled(enabled);
    if (enabled && !result && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Разрешите уведомления в настройках устройства'),
        ),
      );
    }
  }

  Future<void> _setAppIcon(
    BuildContext context,
    WidgetRef ref,
    AppIconChoice choice,
  ) async {
    final result = await ref.read(appIconProvider.notifier).selectIcon(choice);
    if (result == AppIconSelectionResult.failed && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось сменить иконку')),
      );
      return;
    }
    if (result == AppIconSelectionResult.changed && Platform.isAndroid) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      await SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final notificationSettings = ref.watch(notificationSettingsProvider);
    final appIconState = ref.watch(appIconProvider);
    final resetRevision = ref.watch(tabResetRevisionProvider(3));

    return SafeArea(
      bottom: false,
      child: Column(
        children: <Widget>[
          const ScreenHeader(
            title: 'Настройки',
            subtitle: 'Subberry подстраивается под вас',
          ),
          Expanded(
            child: ListView(
              key: ValueKey<String>('settings-$resetRevision'),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                128,
              ),
              children: <Widget>[
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Тема',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _ThemeModePicker(
                        selected: themeMode,
                        onSelected: (mode) {
                          unawaited(
                            ref.read(themeModeProvider.notifier).setMode(mode),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Иконка приложения',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Выберите любой из шести вариантов',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _AppIconPicker(
                        selected: appIconState.selected,
                        isBusy: appIconState.isBusy,
                        onSelected: (choice) {
                          unawaited(_setAppIcon(context, ref, choice));
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                GlassCard(
                  child: Column(
                    children: <Widget>[
                      _SettingsRow(
                        icon: Icons.notifications_active_rounded,
                        title: 'Напоминания',
                        subtitle: 'Предупреждать о списаниях',
                        trailing: Switch.adaptive(
                          value: notificationSettings.enabled,
                          onChanged: notificationSettings.isBusy
                              ? null
                              : (value) {
                                  unawaited(
                                    _setNotifications(context, ref, value),
                                  );
                                },
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 240),
                        child: !notificationSettings.enabled
                            ? const SizedBox.shrink()
                            : Padding(
                                key: const ValueKey<String>('reminder-days'),
                                padding: const EdgeInsets.only(
                                  top: AppSpacing.md,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Divider(
                                      color: Theme.of(context).dividerColor,
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(
                                      'Напомнить заранее',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    SizedBox(
                                      width: double.infinity,
                                      child: SegmentedButton<int>(
                                        segments: const <ButtonSegment<int>>[
                                          ButtonSegment(
                                            value: 1,
                                            label: Text('1 день'),
                                          ),
                                          ButtonSegment(
                                            value: 3,
                                            label: Text('3 дня'),
                                          ),
                                          ButtonSegment(
                                            value: 7,
                                            label: Text('7 дней'),
                                          ),
                                        ],
                                        selected: <int>{
                                          notificationSettings.daysBefore,
                                        },
                                        showSelectedIcon: false,
                                        onSelectionChanged: (selection) {
                                          unawaited(
                                            ref
                                                .read(
                                                  notificationSettingsProvider
                                                      .notifier,
                                                )
                                                .setDaysBefore(selection.first),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const GlassCard(
                  child: _SettingsRow(
                    icon: Icons.favorite_rounded,
                    title: 'Subberry',
                    subtitle: 'Версия 1.2.0',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeModePicker extends StatelessWidget {
  const _ThemeModePicker({required this.selected, required this.onSelected});

  final ThemeMode selected;
  final ValueChanged<ThemeMode> onSelected;

  @override
  Widget build(BuildContext context) {
    const choices = <(ThemeMode, IconData, String)>[
      (ThemeMode.light, Icons.light_mode_rounded, 'Светлая'),
      (ThemeMode.dark, Icons.dark_mode_rounded, 'Тёмная'),
      (ThemeMode.system, Icons.auto_mode_rounded, 'Система'),
    ];
    return Row(
      children: <Widget>[
        for (var index = 0; index < choices.length; index++) ...<Widget>[
          Expanded(
            child: _ThemeModeTile(
              icon: choices[index].$2,
              label: choices[index].$3,
              selected: selected == choices[index].$1,
              onTap: () => onSelected(choices[index].$1),
            ),
          ),
          if (index != choices.length - 1) const SizedBox(width: AppSpacing.xs),
        ],
      ],
    );
  }
}

class _ThemeModeTile extends StatelessWidget {
  const _ThemeModeTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AppColors.coral
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 72,
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.coral.withValues(alpha: 0.13)
                : Theme.of(context).colorScheme.surface.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected
                  ? AppColors.coral
                  : Theme.of(context).dividerColor,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, color: color, size: 22),
              const SizedBox(height: AppSpacing.xxs),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
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

class _AppIconPicker extends StatelessWidget {
  const _AppIconPicker({
    required this.selected,
    required this.isBusy,
    required this.onSelected,
  });

  final AppIconChoice selected;
  final bool isBusy;
  final ValueChanged<AppIconChoice> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Тёмные', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        _AppIconRow(
          choices: AppIconChoice.values
              .where((choice) => choice.name.startsWith('dark'))
              .toList(growable: false),
          selected: selected,
          isBusy: isBusy,
          onSelected: onSelected,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Светлые', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        _AppIconRow(
          choices: AppIconChoice.values
              .where((choice) => choice.name.startsWith('light'))
              .toList(growable: false),
          selected: selected,
          isBusy: isBusy,
          onSelected: onSelected,
        ),
      ],
    );
  }
}

class _AppIconRow extends StatelessWidget {
  const _AppIconRow({
    required this.choices,
    required this.selected,
    required this.isBusy,
    required this.onSelected,
  });

  final List<AppIconChoice> choices;
  final AppIconChoice selected;
  final bool isBusy;
  final ValueChanged<AppIconChoice> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        for (var index = 0; index < choices.length; index++) ...<Widget>[
          Expanded(
            child: _AppIconTile(
              choice: choices[index],
              selected: choices[index] == selected,
              enabled: !isBusy,
              onTap: () => onSelected(choices[index]),
            ),
          ),
          if (index != choices.length - 1) const SizedBox(width: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _AppIconTile extends StatelessWidget {
  const _AppIconTile({
    required this.choice,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final AppIconChoice choice;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shortLabel = switch (choice) {
      AppIconChoice.darkGlass || AppIconChoice.lightGlass => 'Стекло',
      AppIconChoice.darkNeon || AppIconChoice.lightNeon => 'Неон',
      AppIconChoice.darkMinimal || AppIconChoice.lightMinimal => 'Минимал',
    };
    return Semantics(
      selected: selected,
      button: true,
      label: choice.label,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: enabled && !selected ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.coral.withValues(alpha: 0.13)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected
                  ? AppColors.coral
                  : Theme.of(context).dividerColor,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: <Widget>[
              AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Image.asset(choice.assetPath, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  shortLabel,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: selected ? AppColors.coral : null,
                    fontWeight: FontWeight.w700,
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

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

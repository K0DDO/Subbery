import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/screen_header.dart';
import '../../notifications/application/notification_settings_controller.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final notificationSettings = ref.watch(notificationSettingsProvider);

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
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<ThemeMode>(
                          segments: const <ButtonSegment<ThemeMode>>[
                            ButtonSegment(
                              value: ThemeMode.light,
                              icon: Icon(Icons.light_mode_rounded),
                              label: Text('Светлая'),
                            ),
                            ButtonSegment(
                              value: ThemeMode.dark,
                              icon: Icon(Icons.dark_mode_rounded),
                              label: Text('Тёмная'),
                            ),
                            ButtonSegment(
                              value: ThemeMode.system,
                              icon: Icon(Icons.auto_mode_rounded),
                              label: Text('Система'),
                            ),
                          ],
                          selected: <ThemeMode>{themeMode},
                          showSelectedIcon: false,
                          onSelectionChanged: (selection) {
                            unawaited(
                              ref
                                  .read(themeModeProvider.notifier)
                                  .setMode(selection.first),
                            );
                          },
                        ),
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
                    subtitle: 'Версия 1.0.0',
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

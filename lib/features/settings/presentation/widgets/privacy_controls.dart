import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/haptics/haptic_manager.dart';
import '../../../../core/theme/app_accent_theme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../application/privacy_settings_controller.dart';

/// Shared privacy toggles used by Settings and the overview quick sheet.
class PrivacyControls extends ConsumerWidget {
  const PrivacyControls({
    this.includePrivateMode = true,
    this.dense = false,
    super.key,
  });

  final bool includePrivateMode;
  final bool dense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final privacy = ref.watch(privacySettingsProvider);
    final notifier = ref.read(privacySettingsProvider.notifier);
    final gap = dense ? AppSpacing.sm : AppSpacing.md;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (includePrivateMode) ...<Widget>[
          _PrivacySwitchRow(
            icon: Icons.lock_rounded,
            title: 'Приватный режим',
            subtitle: 'Скрывает числа и делает баланс матовым',
            value: privacy.privateMode,
            onChanged: (value) {
              unawaited(HapticManager.instance.toggle());
              unawaited(notifier.setPrivateMode(value));
            },
          ),
          SizedBox(height: gap),
          Divider(color: Theme.of(context).dividerColor),
          SizedBox(height: gap),
        ],
        _PrivacySwitchRow(
          icon: Icons.blur_on_rounded,
          title: 'Прозрачный баланс',
          subtitle: 'Только главная: план и круг платежей',
          value: privacy.effectiveTransparentBalance,
          onChanged: (value) {
            unawaited(HapticManager.instance.toggle());
            unawaited(notifier.setTransparentBalance(value));
          },
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeInOutCubic,
          alignment: Alignment.topCenter,
          child: !privacy.effectiveTransparentBalance
              ? const SizedBox.shrink()
              : Padding(
                  key: const ValueKey<String>('privacy-transparency-slider'),
                  padding: EdgeInsets.only(top: gap),
                  child: _TransparencySlider(
                    value: privacy.transparencyStrength,
                    onChanged: (value) {
                      unawaited(HapticManager.instance.sliderTick());
                      unawaited(notifier.setTransparencyStrength(value));
                    },
                  ),
                ),
        ),
        SizedBox(height: gap),
        _PrivacySwitchRow(
          icon: Icons.visibility_off_rounded,
          title: 'Скрывать числа',
          subtitle: 'Живой спойлер поверх всех сумм',
          value: privacy.effectiveHideNumbers,
          onChanged: (value) {
            unawaited(HapticManager.instance.toggle());
            unawaited(notifier.setHideNumbers(value));
          },
        ),
        SizedBox(height: gap),
        _PrivacySwitchRow(
          icon: Icons.more_horiz_rounded,
          title: 'Показывать копейки',
          subtitle: privacy.showKopecks ? '4 280,50 ₽' : '4 280 ₽',
          value: privacy.showKopecks,
          onChanged: (value) {
            unawaited(HapticManager.instance.toggle());
            unawaited(notifier.setShowKopecks(value));
          },
        ),
      ],
    );
  }
}

class _PrivacySwitchRow extends StatelessWidget {
  const _PrivacySwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.subberryTheme;
    return Row(
      children: <Widget>[
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: palette.primary.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, color: palette.primary, size: 20),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Switch.adaptive(value: value, onChanged: onChanged),
      ],
    );
  }
}

class _TransparencySlider extends StatelessWidget {
  const _TransparencySlider({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.subberryTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Сила прозрачности',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: <Widget>[
            Icon(
              Icons.visibility_off_outlined,
              size: 16,
              color: palette.mutedTextColor,
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: palette.primary,
                  inactiveTrackColor: palette.borderColor,
                  thumbColor: palette.primary,
                  overlayColor: palette.glowColor.withValues(alpha: 0.18),
                ),
                child: Slider(value: value, onChanged: onChanged),
              ),
            ),
            Icon(Icons.visibility_outlined, size: 16, color: palette.primary),
          ],
        ),
        Text(
          value < 0.33
              ? 'Почти скрыто — остаётся контур цифр'
              : value < 0.7
              ? 'Матовое стекло'
              : 'Полностью читаемо',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

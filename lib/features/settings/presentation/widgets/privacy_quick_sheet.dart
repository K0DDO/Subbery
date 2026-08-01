import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_accent_theme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/money_text.dart';
import '../../../../widgets/morphing_sheet/morphing_glass_sheet.dart';
import 'privacy_controls.dart';

Future<void> showPrivacyQuickSheet({
  required BuildContext context,
  required Rect startRect,
  required int plannedCents,
}) {
  final media = MediaQuery.of(context);
  return MorphingGlassSheet.show<void>(
    context: context,
    startRect: startRect,
    endPosition: Offset(AppSpacing.md, media.padding.top + 56),
    maximumHeight: math.min(560, media.size.height * 0.78),
    source: Material(
      type: MaterialType.transparency,
      child: Center(
        child: Icon(
          Icons.account_balance_wallet_rounded,
          color: context.subberryTheme.primary,
        ),
      ),
    ),
    builder: (_) => PrivacyQuickSheet(plannedCents: plannedCents),
  );
}

class PrivacyQuickSheet extends StatelessWidget {
  const PrivacyQuickSheet({required this.plannedCents, super.key});

  final int plannedCents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.subberryTheme;

    return Material(
      type: MaterialType.transparency,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          52,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Приватность',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                color: palette.glassTint.withValues(alpha: 0.55),
                border: Border.all(color: palette.borderColor),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: palette.glowColor.withValues(alpha: 0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Запланировано в этом месяце',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: MoneyText(
                        cents: plannedCents,
                        frost: true,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Превью эффекта на блоке расходов',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const PrivacyControls(includePrivateMode: false, dense: true),
          ],
        ),
      ),
    );
  }
}

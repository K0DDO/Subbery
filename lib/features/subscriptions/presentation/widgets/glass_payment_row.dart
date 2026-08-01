import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/glass_theme.dart';

/// Responsive glass payment row: title + amount on line 1, meta on line 2.
class GlassPaymentRow extends StatelessWidget {
  const GlassPaymentRow({
    required this.leading,
    required this.title,
    required this.trailing,
    this.subtitle,
    this.trailingColor,
    this.accentColor,
    this.onTap,
    super.key,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final String trailing;
  final Color? trailingColor;
  final Color? accentColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<GlassTheme>()!;
    final theme = Theme.of(context);
    final amountStyle = theme.textTheme.titleSmall?.copyWith(
      color: trailingColor,
      fontWeight: FontWeight.w800,
    );
    final titleStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Ink(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: glass.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: accentColor?.withValues(alpha: 0.28) ?? glass.border,
              ),
              boxShadow: accentColor == null
                  ? null
                  : <BoxShadow>[
                      BoxShadow(
                        color: accentColor!.withValues(alpha: 0.12),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                leading,
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: titleStyle,
                            ),
                          ),
                          if (trailing.isNotEmpty) ...<Widget>[
                            const SizedBox(width: AppSpacing.sm),
                            Flexible(
                              child: Text(
                                trailing,
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.fade,
                                textAlign: TextAlign.right,
                                style: amountStyle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (subtitle != null) ...<Widget>[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

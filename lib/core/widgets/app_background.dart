import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColors = isDark
        ? const <Color>[AppColors.darkBackground, AppColors.darkBackgroundWarm]
        : const <Color>[
            AppColors.lightBackground,
            AppColors.lightBackgroundWarm,
            AppColors.lightBackgroundPeach,
          ];

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: backgroundColors,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const Positioned(
            top: -150,
            right: -120,
            child: _GlowOrb(size: 360, color: AppColors.coral, opacity: 0.23),
          ),
          const Positioned(
            bottom: -170,
            left: -150,
            child: _GlowOrb(size: 420, color: AppColors.peach, opacity: 0.2),
          ),
          if (isDark)
            const Positioned(
              top: 280,
              left: -100,
              child: _GlowOrb(size: 280, color: AppColors.pink, opacity: 0.12),
            ),
          child,
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.size,
    required this.color,
    required this.opacity,
  });

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: <Color>[
                color.withValues(alpha: opacity),
                color.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

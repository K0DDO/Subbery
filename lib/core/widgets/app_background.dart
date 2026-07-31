import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/application/background_pattern_controller.dart';
import '../theme/app_colors.dart';

class AppBackground extends ConsumerWidget {
  const AppBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pattern = ref.watch(backgroundPatternProvider);
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
          if (pattern.assetPath case final assetPath?)
            _EmojiPattern(assetPath: assetPath, opacity: isDark ? 0.13 : 0.09),
          child,
        ],
      ),
    );
  }
}

class _EmojiPattern extends StatefulWidget {
  const _EmojiPattern({required this.assetPath, required this.opacity});

  final String assetPath;
  final double opacity;

  @override
  State<_EmojiPattern> createState() => _EmojiPatternState();
}

class _EmojiPatternState extends State<_EmojiPattern>
    with SingleTickerProviderStateMixin {
  late final AnimationController _movementController;
  bool? _animationsDisabled;

  @override
  void initState() {
    super.initState();
    _movementController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animationsDisabled = MediaQuery.disableAnimationsOf(context);
    if (_animationsDisabled == animationsDisabled) return;
    _animationsDisabled = animationsDisabled;
    if (animationsDisabled) {
      _movementController
        ..stop()
        ..value = 0.25;
    } else {
      _movementController.repeat();
    }
  }

  @override
  void dispose() {
    _movementController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final viewport = MediaQuery.sizeOf(context);
            final width = constraints.hasBoundedWidth
                ? constraints.maxWidth
                : viewport.width;
            final height = constraints.hasBoundedHeight
                ? constraints.maxHeight
                : viewport.height;
            const spacing = 74.0;
            final columns = (width / spacing).ceil() + 1;
            final rows = (height / spacing).ceil() + 1;
            final sprites = <_PatternSprite>[
              for (var row = 0; row < rows; row++)
                for (var column = 0; column < columns; column++)
                  _buildSprite(row, column, spacing),
            ];

            return AnimatedBuilder(
              animation: _movementController,
              builder: (context, child) {
                final progress = _movementController.value * math.pi * 2;
                return Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    for (final sprite in sprites)
                      Positioned(
                        left: sprite.left,
                        top: sprite.top,
                        child: Transform.translate(
                          offset: Offset(
                            math.sin(progress + sprite.phase) * sprite.driftX,
                            math.cos(progress + sprite.phase) * sprite.driftY,
                          ),
                          child: Transform.rotate(
                            angle:
                                sprite.angle +
                                math.sin(progress + sprite.phase) * 0.045,
                            child: Image.asset(
                              widget.assetPath,
                              width: sprite.size,
                              height: sprite.size,
                              color: AppColors.coral.withValues(
                                alpha: widget.opacity,
                              ),
                              colorBlendMode: BlendMode.srcIn,
                              filterQuality: FilterQuality.medium,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  _PatternSprite _buildSprite(int row, int column, double spacing) {
    final seed =
        widget.assetPath.hashCode ^ (row * 73856093) ^ (column * 19349663);
    final random = math.Random(seed);
    return _PatternSprite(
      left:
          column * spacing +
          (row.isOdd ? spacing * 0.32 : 0) -
          20 +
          random.nextDouble() * 30,
      top: row * spacing - 18 + random.nextDouble() * 30,
      size: 21 + random.nextDouble() * 11,
      angle: (random.nextDouble() - 0.5) * 0.42,
      phase: random.nextDouble() * math.pi * 2,
      driftX: 3 + random.nextDouble() * 5,
      driftY: 2 + random.nextDouble() * 4,
    );
  }
}

class _PatternSprite {
  const _PatternSprite({
    required this.left,
    required this.top,
    required this.size,
    required this.angle,
    required this.phase,
    required this.driftX,
    required this.driftY,
  });

  final double left;
  final double top;
  final double size;
  final double angle;
  final double phase;
  final double driftX;
  final double driftY;
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

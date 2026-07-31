import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_accent_theme.dart';

class SubberryLogo extends StatelessWidget {
  const SubberryLogo({this.size = 76, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.29;
    final accent = context.accentTheme;

    return Semantics(
      image: true,
      label: 'Логотип Subberry',
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                gradient: accent.gradient,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.62),
                  width: 1.2,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: accent.tertiary.withValues(alpha: 0.32),
                    blurRadius: size * 0.42,
                    spreadRadius: size * 0.02,
                    offset: Offset(0, size * 0.12),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.5),
                    blurRadius: 1,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Colors.white.withValues(alpha: 0.38),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    'S',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size * 0.51,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -size * 0.04,
                      shadows: <Shadow>[
                        Shadow(
                          color: accent.tertiary.withValues(alpha: 0.22),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: -size * 0.09,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _Leaf(size: size * 0.27, angle: -math.pi / 5),
                  Transform.translate(
                    offset: Offset(0, -size * 0.06),
                    child: _Leaf(size: size * 0.29),
                  ),
                  _Leaf(size: size * 0.27, angle: math.pi / 5),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Leaf extends StatelessWidget {
  const _Leaf({required this.size, this.angle = 0});

  final double size;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: size * 0.48,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFF77B879),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(size),
            topRight: Radius.circular(size),
            bottomLeft: Radius.circular(size * 0.25),
            bottomRight: Radius.circular(size * 0.25),
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.45),
            width: 0.8,
          ),
        ),
      ),
    );
  }
}

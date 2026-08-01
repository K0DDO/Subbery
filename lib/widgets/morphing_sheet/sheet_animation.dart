import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

@immutable
class MorphingSheetAnimationSettings {
  const MorphingSheetAnimationSettings({
    this.animationSpeed = 1.35,
    this.minimumDuration = const Duration(milliseconds: 350),
    this.maximumDuration = const Duration(milliseconds: 900),
    this.openingCurve = Curves.easeOutCubic,
    this.returnCurve = Curves.easeOutBack,
    this.startRadius = 40,
    this.endRadius = 24,
    this.startBlur = 18,
    this.endBlur = 28,
    this.overlayOpacity = 0.45,
    this.backgroundBlur = 10,
    this.dismissThreshold = 0.30,
    this.dismissVelocity = 900,
  });

  /// Logical pixels travelled per millisecond.
  final double animationSpeed;
  final Duration minimumDuration;
  final Duration maximumDuration;
  final Curve openingCurve;
  final Curve returnCurve;
  final double startRadius;
  final double endRadius;
  final double startBlur;
  final double endBlur;
  final double overlayOpacity;
  final double backgroundBlur;
  final double dismissThreshold;
  final double dismissVelocity;

  Duration durationFor(Rect start, Rect end) {
    final distance = MorphingSheetGeometry.distance(start, end);
    final milliseconds = (distance / animationSpeed).round().clamp(
      minimumDuration.inMilliseconds,
      maximumDuration.inMilliseconds,
    );
    return Duration(milliseconds: milliseconds);
  }
}

abstract final class MorphingSheetGeometry {
  static Rect interpolate(Rect start, Rect end, double progress) {
    return Rect.lerp(start, end, progress.clamp(0.0, 1.0))!;
  }

  static double distance(Rect start, Rect end) {
    final centerDistance = (end.center - start.center).distance;
    final widthDistance = (end.width - start.width).abs();
    final heightDistance = (end.height - start.height).abs();
    return math.max(centerDistance, math.max(widthDistance, heightDistance));
  }

  static double value(double start, double end, double progress) {
    return lerpDouble(start, end, progress.clamp(0.0, 1.0))!;
  }
}

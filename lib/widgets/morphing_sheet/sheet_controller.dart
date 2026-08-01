import 'package:flutter/material.dart';

import 'sheet_animation.dart';

class MorphingSheetController extends ChangeNotifier {
  MorphingSheetController({required this.settings});

  final MorphingSheetAnimationSettings settings;
  final ScrollController scrollController = ScrollController();

  AnimationController? _animationController;
  VoidCallback? _dismiss;
  double _dragTravel = 1;
  bool _hasInteracted = false;

  bool get hasInteracted => _hasInteracted;
  double get progress => _animationController?.value ?? 0;

  void attach({
    required AnimationController animationController,
    required VoidCallback dismiss,
  }) {
    _animationController = animationController;
    _dismiss = dismiss;
  }

  void configure({required Rect startRect, required Rect endRect}) {
    _dragTravel = (endRect.top - startRect.top).abs().clamp(
      1.0,
      double.infinity,
    );
    final duration = settings.durationFor(startRect, endRect);
    _animationController
      ?..duration = duration
      ..reverseDuration = duration;
  }

  void updateDrag(double primaryDelta) {
    final animation = _animationController;
    if (animation == null) return;
    _beginInteraction();
    animation.stop();
    animation.value = (animation.value - primaryDelta / _dragTravel).clamp(
      0.0,
      1.0,
    );
  }

  void endDrag(double primaryVelocity) {
    final animation = _animationController;
    if (animation == null) return;
    final dismissedFraction = 1 - animation.value;
    if (primaryVelocity > settings.dismissVelocity ||
        dismissedFraction >= settings.dismissThreshold) {
      dismiss();
      return;
    }
    final remaining = (1 - animation.value).clamp(0.0, 1.0);
    final milliseconds = (settings.minimumDuration.inMilliseconds * remaining)
        .round()
        .clamp(120, settings.minimumDuration.inMilliseconds);
    animation.animateTo(
      1,
      duration: Duration(milliseconds: milliseconds),
      curve: settings.returnCurve,
    );
  }

  void dismiss() {
    _beginInteraction();
    _dismiss?.call();
  }

  void _beginInteraction() {
    if (_hasInteracted) return;
    _hasInteracted = true;
    notifyListeners();
  }

  @override
  void dispose() {
    scrollController.dispose();
    _animationController = null;
    _dismiss = null;
    super.dispose();
  }
}

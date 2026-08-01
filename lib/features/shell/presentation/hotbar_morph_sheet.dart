import 'package:flutter/material.dart';

import '../../../widgets/morphing_sheet/morphing_glass_sheet.dart';
import '../../../widgets/morphing_sheet/sheet_animation.dart';
import 'app_shell.dart';

Future<T?> showHotbarMorphSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Size? endSize,
  Offset? endPosition,
  double? maximumHeight,
  MorphingSheetAnimationSettings animationSettings =
      const MorphingSheetAnimationSettings(),
}) async {
  final origin =
      AppShellHotbar.currentRect() ?? AppShellHotbar.fallbackRect(context);
  AppShellHotbar.hide();
  try {
    return await MorphingGlassSheet.show<T>(
      context: context,
      startRect: origin,
      endSize: endSize,
      endPosition: endPosition,
      maximumHeight: maximumHeight,
      animationSettings: animationSettings,
      source: AppHotbarContents(
        currentIndex: AppShellHotbar.currentIndex,
        onSelected: (_) {},
      ),
      builder: builder,
    );
  } finally {
    AppShellHotbar.show();
  }
}

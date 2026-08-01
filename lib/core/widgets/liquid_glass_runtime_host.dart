import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/application/glass_effect_controller.dart';
import '../../features/settings/application/haptic_settings_controller.dart';
import '../haptics/haptic_manager.dart';
import 'liquid_glass_material.dart';
import 'liquid_glass_sheen.dart';

/// Syncs glass sheen + haptic settings into process-wide singletons.
class LiquidGlassRuntimeHost extends ConsumerStatefulWidget {
  const LiquidGlassRuntimeHost({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<LiquidGlassRuntimeHost> createState() =>
      _LiquidGlassRuntimeHostState();
}

class _LiquidGlassRuntimeHostState extends ConsumerState<LiquidGlassRuntimeHost>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    LiquidGlassSheen.instance.attach(this);
  }

  @override
  void dispose() {
    LiquidGlassSheen.instance.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strength = ref.watch(glassEffectProvider);
    final haptics = ref.watch(hapticSettingsProvider);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    LiquidGlassSheen.instance.setEnabled(
      strength >= 0.35 && !disableAnimations,
    );
    HapticManager.instance.configure(
      enabled: haptics.enabled,
      intensity: haptics.intensity,
    );

    return LiquidGlassConfig(strength: strength, child: widget.child);
  }
}

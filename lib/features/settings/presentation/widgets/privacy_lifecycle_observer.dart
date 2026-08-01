import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shell/application/tab_reset_provider.dart';
import '../../application/privacy_settings_controller.dart';

/// Clears revealed spoilers when the app backgrounds or the user switches tabs.
class PrivacyLifecycleObserver extends ConsumerStatefulWidget {
  const PrivacyLifecycleObserver({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<PrivacyLifecycleObserver> createState() =>
      _PrivacyLifecycleObserverState();
}

class _PrivacyLifecycleObserverState
    extends ConsumerState<PrivacyLifecycleObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      ref.read(moneyRevealEpochProvider.notifier).hideAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(tabResetRevisionProvider(0), (_, _) {
      ref.read(moneyRevealEpochProvider.notifier).hideAll();
    });
    ref.listen<int>(tabResetRevisionProvider(1), (_, _) {
      ref.read(moneyRevealEpochProvider.notifier).hideAll();
    });
    ref.listen<int>(tabResetRevisionProvider(2), (_, _) {
      ref.read(moneyRevealEpochProvider.notifier).hideAll();
    });
    ref.listen<int>(tabResetRevisionProvider(3), (_, _) {
      ref.read(moneyRevealEpochProvider.notifier).hideAll();
    });
    return widget.child;
  }
}

import 'dart:async';
import 'dart:io';

import 'package:dynamic_app_icon_flutter_plus/dynamic_app_icon_flutter_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppIconChoice {
  darkGlass(
    label: 'Тёмное стекло',
    assetPath: 'assets/icons/subberry_dark_glass.png',
  ),
  darkNeon(
    label: 'Тёмный неон',
    assetPath: 'assets/icons/subberry_dark_neon.png',
    alternateName: 'dark_neon',
  ),
  darkMinimal(
    label: 'Тёмный минимал',
    assetPath: 'assets/icons/subberry_dark_minimal.png',
    alternateName: 'dark_minimal',
  ),
  lightGlass(
    label: 'Светлое стекло',
    assetPath: 'assets/icons/subberry_light_glass.png',
    alternateName: 'light_glass',
  ),
  lightNeon(
    label: 'Светлый неон',
    assetPath: 'assets/icons/subberry_light_neon.png',
    alternateName: 'light_neon',
  ),
  lightMinimal(
    label: 'Светлый минимал',
    assetPath: 'assets/icons/subberry_light_minimal.png',
    alternateName: 'light_minimal',
  );

  const AppIconChoice({
    required this.label,
    required this.assetPath,
    this.alternateName,
  });

  final String label;
  final String assetPath;
  final String? alternateName;
}

enum AppIconSelectionResult { changed, unchanged, failed }

abstract interface class AppIconGateway {
  Future<void> setIcon(String? alternateName);
}

class PlatformAppIconGateway implements AppIconGateway {
  const PlatformAppIconGateway();

  @override
  Future<void> setIcon(String? alternateName) {
    return DynamicAppIconFlutterPlus.setAlternateIconName(
      alternateName,
      showAlert: Platform.isIOS,
      deferUntilBackground: Platform.isAndroid,
    );
  }
}

class AppIconLifecycleObserver extends StatefulWidget {
  const AppIconLifecycleObserver({required this.child, super.key});

  final Widget child;

  @override
  State<AppIconLifecycleObserver> createState() =>
      _AppIconLifecycleObserverState();
}

class _AppIconLifecycleObserverState extends State<AppIconLifecycleObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (Platform.isAndroid &&
        (state == AppLifecycleState.hidden ||
            state == AppLifecycleState.paused)) {
      unawaited(DynamicAppIconFlutterPlus.applyPendingIcon());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

final appIconGatewayProvider = Provider<AppIconGateway>((ref) {
  return const PlatformAppIconGateway();
});

final appIconProvider = StateNotifierProvider<AppIconController, AppIconState>((
  ref,
) {
  return AppIconController(ref.watch(appIconGatewayProvider));
});

class AppIconState extends Equatable {
  const AppIconState({
    this.selected = AppIconChoice.darkGlass,
    this.isBusy = false,
    this.errorMessage,
  });

  final AppIconChoice selected;
  final bool isBusy;
  final String? errorMessage;

  AppIconState copyWith({
    AppIconChoice? selected,
    bool? isBusy,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AppIconState(
      selected: selected ?? this.selected,
      isBusy: isBusy ?? this.isBusy,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[selected, isBusy, errorMessage];
}

class AppIconController extends StateNotifier<AppIconState> {
  AppIconController(this._gateway) : super(const AppIconState()) {
    unawaited(_restore());
  }

  final AppIconGateway _gateway;
  static const _storageKey = 'selected_app_icon';

  Future<void> _restore() async {
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getString(_storageKey);
    final selected = AppIconChoice.values.firstWhere(
      (icon) => icon.name == stored,
      orElse: () => AppIconChoice.darkGlass,
    );
    state = state.copyWith(selected: selected);
  }

  Future<AppIconSelectionResult> selectIcon(AppIconChoice choice) async {
    if (state.selected == choice) return AppIconSelectionResult.unchanged;
    if (state.isBusy) return AppIconSelectionResult.failed;
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      await _gateway.setIcon(choice.alternateName);
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_storageKey, choice.name);
      state = state.copyWith(selected: choice, isBusy: false);
      return AppIconSelectionResult.changed;
    } on Object {
      state = state.copyWith(
        isBusy: false,
        errorMessage: 'Не удалось сменить иконку',
      );
      return AppIconSelectionResult.failed;
    }
  }
}

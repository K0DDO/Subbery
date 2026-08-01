import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../settings/application/accent_color_controller.dart';
import '../../subscriptions/application/subscription_providers.dart';
import '../data/local_notification_service.dart';

final notificationGatewayProvider = Provider<NotificationGateway>((ref) {
  return LocalNotificationService();
});

final notificationSettingsProvider =
    StateNotifierProvider<
      NotificationSettingsController,
      NotificationSettingsState
    >((ref) {
      return NotificationSettingsController(
        ref.watch(notificationGatewayProvider),
      );
    });

final notificationCoordinatorProvider = Provider<void>((ref) {
  Future<void> reschedule() async {
    final settings = ref.read(notificationSettingsProvider);
    final subscriptions = ref.read(subscriptionsProvider).asData?.value;
    if (!settings.isInitialized || subscriptions == null) return;
    await ref
        .read(notificationGatewayProvider)
        .schedulePaymentReminders(
          subscriptions: subscriptions,
          daysBefore: settings.daysBefore,
          enabled: settings.enabled,
          accentColor: ref.read(accentColorProvider).seed,
        );
  }

  ref
    ..listen(subscriptionsProvider, (_, _) => unawaited(reschedule()))
    ..listen(notificationSettingsProvider, (_, _) => unawaited(reschedule()))
    ..listen(accentColorProvider, (_, _) => unawaited(reschedule()));
});

class NotificationSettingsState extends Equatable {
  const NotificationSettingsState({
    this.enabled = false,
    this.daysBefore = 3,
    this.isInitialized = false,
    this.isBusy = false,
  });

  final bool enabled;
  final int daysBefore;
  final bool isInitialized;
  final bool isBusy;

  NotificationSettingsState copyWith({
    bool? enabled,
    int? daysBefore,
    bool? isInitialized,
    bool? isBusy,
  }) {
    return NotificationSettingsState(
      enabled: enabled ?? this.enabled,
      daysBefore: daysBefore ?? this.daysBefore,
      isInitialized: isInitialized ?? this.isInitialized,
      isBusy: isBusy ?? this.isBusy,
    );
  }

  @override
  List<Object> get props => <Object>[
    enabled,
    daysBefore,
    isInitialized,
    isBusy,
  ];
}

class NotificationSettingsController
    extends StateNotifier<NotificationSettingsState> {
  NotificationSettingsController(this._gateway)
    : super(const NotificationSettingsState());

  final NotificationGateway _gateway;

  static const _enabledKey = 'notifications_enabled';
  static const _daysBeforeKey = 'notification_days_before';
  static const _allowedDays = <int>{1, 3, 7};

  Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    final days = preferences.getInt(_daysBeforeKey) ?? 3;
    state = state.copyWith(
      enabled: preferences.getBool(_enabledKey) ?? false,
      daysBefore: _allowedDays.contains(days) ? days : 3,
      isInitialized: true,
    );
  }

  Future<bool> setEnabled(bool enabled) async {
    if (state.isBusy || state.enabled == enabled) return state.enabled;
    state = state.copyWith(isBusy: true);

    final permissionGranted = !enabled || await _gateway.requestPermission();
    final newValue = enabled && permissionGranted;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_enabledKey, newValue);
    state = state.copyWith(enabled: newValue, isBusy: false);
    return newValue;
  }

  Future<void> setDaysBefore(int days) async {
    if (!_allowedDays.contains(days) || state.daysBefore == days) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_daysBeforeKey, days);
    state = state.copyWith(daysBefore: days);
  }
}

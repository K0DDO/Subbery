import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:subberry/features/notifications/application/notification_settings_controller.dart';
import 'package:subberry/features/notifications/data/local_notification_service.dart';
import 'package:subberry/features/subscriptions/domain/entities/subscription.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('uses safe reminder defaults', () async {
    final controller = NotificationSettingsController(
      _FakeNotificationGateway(),
    );

    await controller.initialize();

    expect(controller.state.enabled, isFalse);
    expect(controller.state.daysBefore, 3);
    expect(controller.state.isInitialized, isTrue);
  });

  test('does not enable reminders when permission is denied', () async {
    final gateway = _FakeNotificationGateway(permissionGranted: false);
    final controller = NotificationSettingsController(gateway);
    await controller.initialize();

    expect(await controller.setEnabled(true), isFalse);
    expect(controller.state.enabled, isFalse);
  });

  test('persists permission and reminder lead time', () async {
    final gateway = _FakeNotificationGateway();
    final controller = NotificationSettingsController(gateway);
    await controller.initialize();

    expect(await controller.setEnabled(true), isTrue);
    await controller.setDaysBefore(7);

    final restored = NotificationSettingsController(gateway);
    await restored.initialize();
    expect(restored.state.enabled, isTrue);
    expect(restored.state.daysBefore, 7);
  });
}

class _FakeNotificationGateway implements NotificationGateway {
  _FakeNotificationGateway({this.permissionGranted = true});

  final bool permissionGranted;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => permissionGranted;

  @override
  Future<void> schedulePaymentReminders({
    required List<Subscription> subscriptions,
    required int daysBefore,
    required bool enabled,
  }) async {}
}

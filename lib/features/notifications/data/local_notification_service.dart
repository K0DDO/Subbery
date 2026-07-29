import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/utils/app_formatters.dart';
import '../../subscriptions/domain/entities/subscription.dart';

abstract interface class NotificationGateway {
  Future<void> initialize();

  Future<bool> requestPermission();

  Future<void> schedulePaymentReminders({
    required List<Subscription> subscriptions,
    required int daysBefore,
    required bool enabled,
  });
}

class LocalNotificationService implements NotificationGateway {
  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static const _channelId = 'payment_reminders';
  static const _channelName = 'Напоминания о платежах';

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
    } on Object {
      // timezone.local remains UTC only when the platform cannot report a zone.
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: IOSInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  @override
  Future<bool> requestPermission() async {
    await initialize();
    if (Platform.isAndroid) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          false;
    }
    if (Platform.isIOS) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    }
    return false;
  }

  @override
  Future<void> schedulePaymentReminders({
    required List<Subscription> subscriptions,
    required int daysBefore,
    required bool enabled,
  }) async {
    await initialize();
    await _plugin.cancelAll();
    if (!enabled) return;

    final now = tz.TZDateTime.now(tz.local);
    for (final subscription in subscriptions) {
      if (subscription.status != SubscriptionStatus.active ||
          !subscription.reminderEnabled) {
        continue;
      }

      final paymentDate = _nextPaymentDate(subscription, now);
      final reminderDate = tz.TZDateTime(
        tz.local,
        paymentDate.year,
        paymentDate.month,
        paymentDate.day,
        10,
      ).subtract(Duration(days: daysBefore));
      if (!reminderDate.isAfter(now)) continue;

      await _plugin.zonedSchedule(
        id: _stableNotificationId(subscription.id),
        title: '🍓 Subberry',
        body:
            '${subscription.name} скоро закончится\n'
            'Через $daysBefore ${_dayWord(daysBefore)} будет списание '
            '${AppFormatters.money(subscription.priceInCents)}',
        scheduledDate: reminderDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: 'Предупреждения о предстоящих списаниях',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: subscription.id,
      );
    }
  }

  static DateTime _nextPaymentDate(Subscription subscription, DateTime now) {
    var candidate = subscription.nextPaymentDate;
    final today = DateTime(now.year, now.month, now.day);
    while (candidate.isBefore(today)) {
      candidate = switch (subscription.billingCycle) {
        BillingCycle.monthly => _addMonth(candidate),
        BillingCycle.yearly => _safeDate(
          candidate.year + 1,
          candidate.month,
          candidate.day,
        ),
      };
    }
    return candidate;
  }

  static DateTime _addMonth(DateTime date) {
    final nextMonth = date.month == 12 ? 1 : date.month + 1;
    final nextYear = date.month == 12 ? date.year + 1 : date.year;
    return _safeDate(nextYear, nextMonth, date.day);
  }

  static DateTime _safeDate(int year, int month, int day) {
    return DateTime(
      year,
      month,
      day.clamp(1, DateTime(year, month + 1, 0).day),
    );
  }

  static int _stableNotificationId(String value) {
    var hash = 0x811C9DC5;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7FFFFFFF;
    }
    return hash;
  }

  static String _dayWord(int count) {
    final last = count % 10;
    final lastTwo = count % 100;
    if (last == 1 && lastTwo != 11) return 'день';
    if (last >= 2 && last <= 4 && (lastTwo < 12 || lastTwo > 14)) {
      return 'дня';
    }
    return 'дней';
  }
}

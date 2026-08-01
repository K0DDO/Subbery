import 'package:flutter/material.dart';

import '../../../core/theme/app_accent_theme.dart';
import '../domain/entities/subscription.dart';

extension SubscriptionCategoryUi on SubscriptionCategory {
  String get label => switch (this) {
    SubscriptionCategory.entertainment => 'Развлечения',
    SubscriptionCategory.music => 'Музыка',
    SubscriptionCategory.work => 'Работа',
    SubscriptionCategory.cloud => 'Облако',
    SubscriptionCategory.gaming => 'Игры',
    SubscriptionCategory.education => 'Образование',
    SubscriptionCategory.health => 'Здоровье',
    SubscriptionCategory.other => 'Другое',
  };

  String get emoji => switch (this) {
    SubscriptionCategory.entertainment => '🍿',
    SubscriptionCategory.music => '🎧',
    SubscriptionCategory.work => '💻',
    SubscriptionCategory.cloud => '☁️',
    SubscriptionCategory.gaming => '🎮',
    SubscriptionCategory.education => '🧠',
    SubscriptionCategory.health => '🏥',
    SubscriptionCategory.other => '📦',
  };

  Color color(BuildContext context) =>
      context.subberryTheme.categoryColor(index);
}

extension BillingCycleUi on BillingCycle {
  String get label => switch (this) {
    BillingCycle.monthly => 'Месяц',
    BillingCycle.quarterly => '3 месяца',
    BillingCycle.semiannual => 'Полгода',
    BillingCycle.yearly => 'Год',
    BillingCycle.biennial => '2 года',
    BillingCycle.custom => 'Свой период',
  };

  String get shortLabel => switch (this) {
    BillingCycle.monthly => 'месяц',
    BillingCycle.quarterly => '3 мес.',
    BillingCycle.semiannual => 'полгода',
    BillingCycle.yearly => 'год',
    BillingCycle.biennial => '2 года',
    BillingCycle.custom => 'период',
  };

  String periodLabel({int? customIntervalDays}) {
    if (this == BillingCycle.custom) {
      final days = customIntervalDays ?? 0;
      return 'каждые $days дн.';
    }
    return shortLabel;
  }
}

extension RenewalModeUi on RenewalMode {
  String get label => switch (this) {
    RenewalMode.automatic => 'Автоматическая',
    RenewalMode.manual => 'Единичная',
  };
}

extension SubscriptionStatusUi on SubscriptionStatus {
  String get label => switch (this) {
    SubscriptionStatus.active => 'Активна',
    SubscriptionStatus.paused => 'Приостановлена',
    SubscriptionStatus.cancelled => 'Отменена',
    SubscriptionStatus.expired => 'Истекла',
  };
}

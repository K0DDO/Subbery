import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
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

  Color get color => switch (this) {
    SubscriptionCategory.entertainment => AppColors.entertainment,
    SubscriptionCategory.music => AppColors.music,
    SubscriptionCategory.work => AppColors.work,
    SubscriptionCategory.cloud => AppColors.cloud,
    SubscriptionCategory.gaming => AppColors.gaming,
    SubscriptionCategory.education => AppColors.education,
    SubscriptionCategory.health => AppColors.health,
    SubscriptionCategory.other => AppColors.other,
  };
}

extension BillingCycleUi on BillingCycle {
  String get label => switch (this) {
    BillingCycle.monthly => 'Раз в месяц',
    BillingCycle.quarterly => 'Раз в 3 месяца',
    BillingCycle.semiannual => 'Раз в полгода',
    BillingCycle.yearly => 'Раз в год',
    BillingCycle.biennial => 'Раз в 2 года',
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

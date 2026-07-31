import 'package:equatable/equatable.dart';

enum SubscriptionCategory {
  entertainment,
  music,
  work,
  cloud,
  gaming,
  education,
  health,
  other,
}

enum BillingCycle {
  monthly,
  quarterly,
  semiannual,
  yearly,
  biennial,
  custom,
}

enum RenewalMode { automatic, manual }

enum SubscriptionStatus { active, paused, cancelled, expired }

class Subscription extends Equatable {
  const Subscription({
    required this.id,
    required this.name,
    required this.category,
    required this.priceInCents,
    required this.billingCycle,
    required this.startDate,
    required this.nextPaymentDate,
    required this.status,
    required this.totalSpentInCents,
    required this.reminderEnabled,
    this.renewalMode = RenewalMode.automatic,
    this.billingAnchorDay,
    this.customIntervalDays,
    this.logo,
    this.notes,
  });

  final String id;
  final String name;
  final String? logo;
  final SubscriptionCategory category;
  final int priceInCents;
  final BillingCycle billingCycle;
  final DateTime startDate;
  final DateTime nextPaymentDate;
  final SubscriptionStatus status;
  final int totalSpentInCents;
  final bool reminderEnabled;
  final RenewalMode renewalMode;
  final int? billingAnchorDay;
  final int? customIntervalDays;
  final String? notes;

  double get price => priceInCents / 100;
  double get totalSpent => totalSpentInCents / 100;

  /// Approximate annual cost for active recurring subscriptions.
  int get annualPlanInCents {
    if (renewalMode == RenewalMode.manual) return 0;
    return switch (billingCycle) {
      BillingCycle.monthly => priceInCents * 12,
      BillingCycle.quarterly => priceInCents * 4,
      BillingCycle.semiannual => priceInCents * 2,
      BillingCycle.yearly => priceInCents,
      BillingCycle.biennial => (priceInCents / 2).round(),
      BillingCycle.custom => () {
        final days = customIntervalDays ?? 30;
        if (days <= 0) return 0;
        return ((priceInCents * 365) / days).round();
      }(),
    };
  }

  Subscription copyWith({
    String? id,
    String? name,
    String? logo,
    bool clearLogo = false,
    SubscriptionCategory? category,
    int? priceInCents,
    BillingCycle? billingCycle,
    DateTime? startDate,
    DateTime? nextPaymentDate,
    SubscriptionStatus? status,
    int? totalSpentInCents,
    bool? reminderEnabled,
    RenewalMode? renewalMode,
    int? billingAnchorDay,
    int? customIntervalDays,
    bool clearCustomIntervalDays = false,
    String? notes,
    bool clearNotes = false,
  }) {
    return Subscription(
      id: id ?? this.id,
      name: name ?? this.name,
      logo: clearLogo ? null : logo ?? this.logo,
      category: category ?? this.category,
      priceInCents: priceInCents ?? this.priceInCents,
      billingCycle: billingCycle ?? this.billingCycle,
      startDate: startDate ?? this.startDate,
      nextPaymentDate: nextPaymentDate ?? this.nextPaymentDate,
      status: status ?? this.status,
      totalSpentInCents: totalSpentInCents ?? this.totalSpentInCents,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      renewalMode: renewalMode ?? this.renewalMode,
      billingAnchorDay: billingAnchorDay ?? this.billingAnchorDay,
      customIntervalDays: clearCustomIntervalDays
          ? null
          : customIntervalDays ?? this.customIntervalDays,
      notes: clearNotes ? null : notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    name,
    logo,
    category,
    priceInCents,
    billingCycle,
    startDate,
    nextPaymentDate,
    status,
    totalSpentInCents,
    reminderEnabled,
    renewalMode,
    billingAnchorDay,
    customIntervalDays,
    notes,
  ];
}

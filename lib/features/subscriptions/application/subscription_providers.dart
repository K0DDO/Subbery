import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/app_database.dart';
import '../data/repositories/drift_subscription_repository.dart';
import '../domain/entities/payment.dart';
import '../domain/entities/subscription.dart';
import '../domain/repositories/subscription_repository.dart';
import '../domain/subscription_schedule.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(() => unawaited(database.close()));
  return database;
});

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return DriftSubscriptionRepository(ref.watch(databaseProvider));
});

final subscriptionsProvider = StreamProvider<List<Subscription>>((ref) {
  return ref.watch(subscriptionRepositoryProvider).watchSubscriptions().map((
    subscriptions,
  ) {
    final now = DateTime.now();
    final normalized = subscriptions
        .map((subscription) => _normalizeSchedule(subscription, now))
        .toList(growable: false);
    normalized.sort(
      (left, right) => left.nextPaymentDate.compareTo(right.nextPaymentDate),
    );
    return normalized;
  });
});

final subscriptionProvider = StreamProvider.family<Subscription?, String>((
  ref,
  id,
) {
  return ref
      .watch(subscriptionRepositoryProvider)
      .watchSubscription(id)
      .map(
        (subscription) => subscription == null
            ? null
            : _normalizeSchedule(subscription, DateTime.now()),
      );
});

final paymentsProvider = StreamProvider.family<List<Payment>, String>((
  ref,
  subscriptionId,
) {
  return ref
      .watch(subscriptionRepositoryProvider)
      .watchPayments(subscriptionId);
});

final allPaymentsProvider = StreamProvider<List<Payment>>((ref) {
  return ref.watch(subscriptionRepositoryProvider).watchAllPayments();
});

Subscription _normalizeSchedule(Subscription subscription, DateTime now) {
  if (subscription.status != SubscriptionStatus.active) return subscription;
  final nextPayment = SubscriptionSchedule.normalizedNextPayment(
    subscription,
    now,
  );
  if (nextPayment == subscription.nextPaymentDate) return subscription;
  return subscription.copyWith(nextPaymentDate: nextPayment);
}

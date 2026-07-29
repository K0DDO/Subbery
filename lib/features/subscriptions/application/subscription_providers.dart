import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/app_database.dart';
import '../data/repositories/drift_subscription_repository.dart';
import '../domain/entities/payment.dart';
import '../domain/entities/subscription.dart';
import '../domain/repositories/subscription_repository.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(() => unawaited(database.close()));
  return database;
});

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return DriftSubscriptionRepository(ref.watch(databaseProvider));
});

final subscriptionsProvider = StreamProvider<List<Subscription>>((ref) {
  return ref.watch(subscriptionRepositoryProvider).watchSubscriptions();
});

final subscriptionProvider = FutureProvider.family<Subscription?, String>((
  ref,
  id,
) {
  return ref.watch(subscriptionRepositoryProvider).getSubscription(id);
});

final paymentsProvider = StreamProvider.family<List<Payment>, String>((
  ref,
  subscriptionId,
) {
  return ref
      .watch(subscriptionRepositoryProvider)
      .watchPayments(subscriptionId);
});

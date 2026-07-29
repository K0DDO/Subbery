import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../domain/entities/payment.dart';
import '../domain/entities/subscription.dart';
import '../domain/repositories/subscription_repository.dart';
import 'subscription_providers.dart';

final subscriptionDetailsControllerProvider = StateNotifierProvider.autoDispose
    .family<SubscriptionDetailsController, AsyncValue<void>, String>((
      ref,
      subscriptionId,
    ) {
      return SubscriptionDetailsController(
        ref.watch(subscriptionRepositoryProvider),
        subscriptionId,
      );
    });

class SubscriptionDetailsController extends StateNotifier<AsyncValue<void>> {
  SubscriptionDetailsController(
    this._repository,
    this._subscriptionId, {
    this._uuid = const Uuid(),
  }) : super(const AsyncData<void>(null));

  final SubscriptionRepository _repository;
  final String _subscriptionId;
  final Uuid _uuid;

  Future<bool> recordPayment({
    required int amountInCents,
    required DateTime date,
  }) {
    if (amountInCents <= 0) {
      state = AsyncError<void>(
        ArgumentError.value(amountInCents, 'amountInCents'),
        StackTrace.current,
      );
      return Future<bool>.value(false);
    }

    return _run(() {
      return _repository.addPayment(
        Payment(
          id: _uuid.v4(),
          subscriptionId: _subscriptionId,
          amountInCents: amountInCents,
          date: DateTime(date.year, date.month, date.day),
        ),
      );
    });
  }

  Future<bool> changeStatus(
    Subscription subscription,
    SubscriptionStatus status,
  ) {
    return _run(
      () =>
          _repository.updateSubscription(subscription.copyWith(status: status)),
    );
  }

  Future<bool> deleteSubscription() {
    return _run(() => _repository.deleteSubscription(_subscriptionId));
  }

  Future<bool> _run(Future<void> Function() operation) async {
    state = const AsyncLoading<void>();
    state = await AsyncValue.guard(operation);
    return !state.hasError;
  }
}

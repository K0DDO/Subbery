import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../domain/entities/payment.dart';
import '../domain/entities/subscription.dart';
import '../domain/repositories/subscription_repository.dart';
import '../domain/subscription_schedule.dart';
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
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       super(const AsyncData<void>(null));

  final SubscriptionRepository _repository;
  final String _subscriptionId;
  final Uuid _uuid;
  final DateTime Function() _clock;

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

    return _run(() async {
      final subscription = await _repository.getSubscription(_subscriptionId);
      if (subscription == null) {
        throw StateError('Subscription $_subscriptionId does not exist.');
      }
      if (subscription.renewalMode == RenewalMode.manual &&
          subscription.status != SubscriptionStatus.active) {
        throw StateError('Manual subscription has no active planned payment.');
      }
      final paymentDate = SubscriptionSchedule.dateOnly(date);
      final currentDueDate = SubscriptionSchedule.normalizedNextPayment(
        subscription,
        _clock(),
      );
      if (paymentDate.isAfter(currentDueDate)) {
        throw ArgumentError.value(
          date,
          'date',
          'Payment date cannot be after the next payment date.',
        );
      }

      final updatedSubscription = switch (subscription.renewalMode) {
        RenewalMode.manual => subscription.copyWith(
          priceInCents: amountInCents,
          status: SubscriptionStatus.expired,
        ),
        RenewalMode.automatic => () {
          final anchorDay =
              subscription.billingAnchorDay ?? subscription.nextPaymentDate.day;
          final updatedNextPayment = paymentDate == currentDueDate
              ? SubscriptionSchedule.nextAfter(
                  currentDueDate,
                  subscription.billingCycle,
                  anchorDay: anchorDay,
                )
              : currentDueDate;
          return subscription.copyWith(
            nextPaymentDate: updatedNextPayment,
            billingAnchorDay: anchorDay,
          );
        }(),
      };

      await _repository.addPayment(
        Payment(
          id: _uuid.v4(),
          subscriptionId: _subscriptionId,
          amountInCents: amountInCents,
          date: paymentDate,
        ),
        updatedSubscription: updatedSubscription,
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

  Future<bool> planManualPayment({
    required Subscription subscription,
    required int amountInCents,
    required DateTime date,
  }) {
    if (subscription.renewalMode != RenewalMode.manual || amountInCents <= 0) {
      return Future<bool>.value(false);
    }
    final plannedDate = SubscriptionSchedule.dateOnly(date);
    return _run(
      () => _repository.updateSubscription(
        subscription.copyWith(
          priceInCents: amountInCents,
          nextPaymentDate: plannedDate,
          billingAnchorDay: plannedDate.day,
          status: SubscriptionStatus.active,
        ),
      ),
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

import 'package:drift/drift.dart';

import '../../domain/entities/payment.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../local/app_database.dart';

class DriftSubscriptionRepository implements SubscriptionRepository {
  const DriftSubscriptionRepository(this._database);

  final AppDatabase _database;

  @override
  Stream<List<Subscription>> watchSubscriptions() {
    return _database.watchAllSubscriptions().map(
      (records) => records.map(_mapSubscription).toList(growable: false),
    );
  }

  @override
  Stream<Subscription?> watchSubscription(String id) {
    return _database
        .watchSubscriptionById(id)
        .map((record) => record == null ? null : _mapSubscription(record));
  }

  @override
  Future<List<Subscription>> getSubscriptions() async {
    final records = await _database.getAllSubscriptions();
    return records.map(_mapSubscription).toList(growable: false);
  }

  @override
  Future<Subscription?> getSubscription(String id) async {
    final record = await _database.getSubscriptionById(id);
    return record == null ? null : _mapSubscription(record);
  }

  @override
  Future<void> createSubscription(Subscription subscription) {
    _validateSubscription(subscription);
    return _database.insertSubscription(_subscriptionCompanion(subscription));
  }

  @override
  Future<void> updateSubscription(Subscription subscription) async {
    _validateSubscription(subscription);
    final didUpdate = await _database.replaceSubscription(
      _subscriptionCompanion(subscription),
    );
    if (!didUpdate) {
      throw StateError('Subscription ${subscription.id} does not exist.');
    }
  }

  @override
  Future<void> deleteSubscription(String id) {
    return _database.removeSubscription(id);
  }

  @override
  Stream<List<Payment>> watchPayments(String subscriptionId) {
    return _database
        .watchPaymentsFor(subscriptionId)
        .map((records) => records.map(_mapPayment).toList(growable: false));
  }

  @override
  Stream<List<Payment>> watchAllPayments() {
    return _database.watchAllPayments().map(
      (records) => records.map(_mapPayment).toList(growable: false),
    );
  }

  @override
  Future<List<Payment>> getPayments(String subscriptionId) async {
    final records = await _database.getPaymentsFor(subscriptionId);
    return records.map(_mapPayment).toList(growable: false);
  }

  @override
  Future<void> addPayment(
    Payment payment, {
    Subscription? updatedSubscription,
  }) {
    if (payment.amountInCents <= 0) {
      throw ArgumentError.value(
        payment.amountInCents,
        'payment.amountInCents',
        'Payment amount must be positive.',
      );
    }
    return _database.recordPayment(
      PaymentsCompanion.insert(
        id: payment.id,
        subscriptionId: payment.subscriptionId,
        amountInCents: payment.amountInCents,
        date: payment.date,
      ),
      updatedSubscription: updatedSubscription == null
          ? null
          : _subscriptionCompanion(updatedSubscription),
    );
  }

  @override
  Future<void> deletePayment(String paymentId) {
    return _database.removePayment(paymentId);
  }

  static void _validateSubscription(Subscription subscription) {
    if (subscription.name.trim().isEmpty) {
      throw ArgumentError.value(
        subscription.name,
        'subscription.name',
        'Subscription name cannot be empty.',
      );
    }
    if (subscription.priceInCents < 0) {
      throw ArgumentError.value(
        subscription.priceInCents,
        'subscription.priceInCents',
        'Subscription price cannot be negative.',
      );
    }
  }

  static SubscriptionsCompanion _subscriptionCompanion(
    Subscription subscription,
  ) {
    return SubscriptionsCompanion.insert(
      id: subscription.id,
      name: subscription.name.trim(),
      logo: Value(subscription.logo),
      category: subscription.category.name,
      priceInCents: subscription.priceInCents,
      billingCycle: subscription.billingCycle.name,
      renewalMode: Value(subscription.renewalMode.name),
      startDate: subscription.startDate,
      nextPaymentDate: subscription.nextPaymentDate,
      billingAnchorDay: Value(
        subscription.billingAnchorDay ?? subscription.nextPaymentDate.day,
      ),
      status: subscription.status.name,
      totalSpentInCents: Value(subscription.totalSpentInCents),
      reminderEnabled: Value(subscription.reminderEnabled),
      notes: Value(subscription.notes),
    );
  }

  static Subscription _mapSubscription(SubscriptionRecord record) {
    return Subscription(
      id: record.id,
      name: record.name,
      logo: record.logo,
      category: _enumByName(
        SubscriptionCategory.values,
        record.category,
        SubscriptionCategory.other,
      ),
      priceInCents: record.priceInCents,
      billingCycle: _enumByName(
        BillingCycle.values,
        record.billingCycle,
        BillingCycle.monthly,
      ),
      renewalMode: _enumByName(
        RenewalMode.values,
        record.renewalMode,
        RenewalMode.automatic,
      ),
      startDate: record.startDate,
      nextPaymentDate: record.nextPaymentDate,
      billingAnchorDay: record.billingAnchorDay,
      status: _enumByName(
        SubscriptionStatus.values,
        record.status,
        SubscriptionStatus.active,
      ),
      totalSpentInCents: record.totalSpentInCents,
      reminderEnabled: record.reminderEnabled,
      notes: record.notes,
    );
  }

  static Payment _mapPayment(PaymentRecord record) {
    return Payment(
      id: record.id,
      subscriptionId: record.subscriptionId,
      amountInCents: record.amountInCents,
      date: record.date,
    );
  }

  static T _enumByName<T extends Enum>(
    List<T> values,
    String name,
    T fallback,
  ) {
    return values.firstWhere(
      (value) => value.name == name,
      orElse: () => fallback,
    );
  }
}

import '../entities/payment.dart';
import '../entities/subscription.dart';

abstract interface class SubscriptionRepository {
  Stream<List<Subscription>> watchSubscriptions();

  Stream<Subscription?> watchSubscription(String id);

  Future<List<Subscription>> getSubscriptions();

  Future<Subscription?> getSubscription(String id);

  Future<void> createSubscription(Subscription subscription);

  Future<void> updateSubscription(Subscription subscription);

  Future<void> deleteSubscription(String id);

  Stream<List<Payment>> watchPayments(String subscriptionId);

  Future<List<Payment>> getPayments(String subscriptionId);

  Future<void> addPayment(Payment payment);

  Future<void> deletePayment(String paymentId);
}

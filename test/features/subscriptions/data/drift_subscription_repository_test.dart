import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subberry/features/subscriptions/data/local/app_database.dart';
import 'package:subberry/features/subscriptions/data/repositories/drift_subscription_repository.dart';
import 'package:subberry/features/subscriptions/domain/entities/payment.dart';
import 'package:subberry/features/subscriptions/domain/entities/subscription.dart';

void main() {
  late AppDatabase database;
  late DriftSubscriptionRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftSubscriptionRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('creates, reads, updates, and deletes subscriptions', () async {
    final netflix = _subscription(
      id: 'netflix',
      name: 'Netflix',
      nextPaymentDate: DateTime(2026, 8, 3),
    );
    final spotify = _subscription(
      id: 'spotify',
      name: 'Spotify',
      nextPaymentDate: DateTime(2026, 8, 10),
    );

    await repository.createSubscription(spotify);
    await repository.createSubscription(netflix);

    final subscriptions = await repository.getSubscriptions();
    expect(subscriptions, <Subscription>[netflix, spotify]);

    final pausedNetflix = netflix.copyWith(
      priceInCents: 89900,
      status: SubscriptionStatus.paused,
    );
    await repository.updateSubscription(pausedNetflix);

    expect(await repository.getSubscription('netflix'), pausedNetflix);

    await repository.deleteSubscription('netflix');
    expect(await repository.getSubscription('netflix'), isNull);
  });

  test('records payments and keeps total spent consistent', () async {
    final netflix = _subscription(
      id: 'netflix',
      name: 'Netflix',
      nextPaymentDate: DateTime(2026, 8, 3),
    );
    await repository.createSubscription(netflix);

    await repository.addPayment(
      Payment(
        id: 'payment-1',
        subscriptionId: netflix.id,
        amountInCents: 79900,
        date: DateTime(2026, 7, 3),
      ),
    );
    await repository.addPayment(
      Payment(
        id: 'payment-2',
        subscriptionId: netflix.id,
        amountInCents: 16900,
        date: DateTime(2026, 6, 3),
      ),
    );

    expect(
      (await repository.getSubscription(netflix.id))?.totalSpentInCents,
      96800,
    );
    expect(await repository.getPayments(netflix.id), hasLength(2));

    await repository.deletePayment('payment-1');
    expect(
      (await repository.getSubscription(netflix.id))?.totalSpentInCents,
      16900,
    );

    await repository.deleteSubscription(netflix.id);
    expect(await repository.getPayments(netflix.id), isEmpty);
  });
}

Subscription _subscription({
  required String id,
  required String name,
  required DateTime nextPaymentDate,
}) {
  return Subscription(
    id: id,
    name: name,
    logo: name.toLowerCase(),
    category: SubscriptionCategory.entertainment,
    priceInCents: 79900,
    billingCycle: BillingCycle.monthly,
    startDate: DateTime(2026),
    nextPaymentDate: nextPaymentDate,
    status: SubscriptionStatus.active,
    totalSpentInCents: 0,
    reminderEnabled: true,
  );
}

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subberry/features/subscriptions/application/subscription_details_controller.dart';
import 'package:subberry/features/subscriptions/data/local/app_database.dart';
import 'package:subberry/features/subscriptions/data/repositories/drift_subscription_repository.dart';
import 'package:subberry/features/subscriptions/domain/entities/subscription.dart';

void main() {
  late AppDatabase database;
  late DriftSubscriptionRepository repository;
  late SubscriptionDetailsController controller;
  late Subscription subscription;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftSubscriptionRepository(database);
    subscription = Subscription(
      id: 'netflix',
      name: 'Netflix',
      logo: 'netflix',
      category: SubscriptionCategory.entertainment,
      priceInCents: 79900,
      billingCycle: BillingCycle.monthly,
      startDate: DateTime(2026),
      nextPaymentDate: DateTime(2026, 8, 3),
      status: SubscriptionStatus.active,
      totalSpentInCents: 0,
      reminderEnabled: true,
    );
    await repository.createSubscription(subscription);
    controller = SubscriptionDetailsController(repository, subscription.id);
  });

  tearDown(() async {
    controller.dispose();
    await database.close();
  });

  test('records payment and updates total spent', () async {
    final saved = await controller.recordPayment(
      amountInCents: 79900,
      date: DateTime(2026, 7, 3),
    );

    expect(saved, isTrue);
    expect(
      (await repository.getSubscription(subscription.id))?.totalSpentInCents,
      79900,
    );
    expect(await repository.getPayments(subscription.id), hasLength(1));
  });

  test('changes status and deletes subscription', () async {
    expect(
      await controller.changeStatus(subscription, SubscriptionStatus.paused),
      isTrue,
    );
    expect(
      (await repository.getSubscription(subscription.id))?.status,
      SubscriptionStatus.paused,
    );

    expect(await controller.deleteSubscription(), isTrue);
    expect(await repository.getSubscription(subscription.id), isNull);
  });
}

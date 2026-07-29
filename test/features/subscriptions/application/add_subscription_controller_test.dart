import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subberry/features/subscriptions/application/add_subscription_controller.dart';
import 'package:subberry/features/subscriptions/data/catalog/known_services.dart';
import 'package:subberry/features/subscriptions/data/local/app_database.dart';
import 'package:subberry/features/subscriptions/data/repositories/drift_subscription_repository.dart';
import 'package:subberry/features/subscriptions/domain/entities/subscription.dart';

void main() {
  late AppDatabase database;
  late DriftSubscriptionRepository repository;
  late AddSubscriptionController controller;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftSubscriptionRepository(database);
    controller = AddSubscriptionController(
      repository,
      clock: () => DateTime(2026, 7, 29),
    );
  });

  tearDown(() async {
    controller.dispose();
    await database.close();
  });

  test('suggests known service metadata', () {
    controller.setServiceName('Netflix');

    expect(controller.state.selectedService?.logoKey, 'netflix');
    expect(controller.state.category, SubscriptionCategory.entertainment);
    expect(
      KnownServices.suggestionsFor('tele').single.name,
      'Telegram Premium',
    );
  });

  test('creates a subscription from valid localized input', () async {
    controller
      ..setServiceName('Spotify')
      ..setPrice('169,50 ₽')
      ..setBillingCycle(BillingCycle.monthly)
      ..setNextPaymentDate(DateTime(2026, 8, 10));

    expect(await controller.submit(), isTrue);

    final saved = (await repository.getSubscriptions()).single;
    expect(saved.name, 'Spotify');
    expect(saved.logo, 'spotify');
    expect(saved.category, SubscriptionCategory.music);
    expect(saved.priceInCents, 16950);
    expect(saved.startDate, DateTime(2026, 7, 29));
    expect(saved.nextPaymentDate, DateTime(2026, 8, 10));
  });

  test('rejects incomplete input without writing to storage', () async {
    controller
      ..setServiceName('Custom service')
      ..setPrice('not a price');

    expect(await controller.submit(), isFalse);
    expect(controller.state.errorMessage, 'Укажите корректную стоимость');
    expect(await repository.getSubscriptions(), isEmpty);
  });

  test('updates every editable subscription field', () async {
    controller
      ..setServiceName('Netflix')
      ..setPrice('799')
      ..setNextPaymentDate(DateTime(2026, 8, 29));
    expect(await controller.submit(), isTrue);
    final original = (await repository.getSubscriptions()).single;

    final editor = AddSubscriptionController(
      repository,
      initialSubscription: original,
    );
    editor
      ..setServiceName('Spotify')
      ..setPrice('199,50')
      ..setCategory(SubscriptionCategory.music)
      ..setBillingCycle(BillingCycle.yearly)
      ..setNextPaymentDate(DateTime(2027, 8, 29))
      ..setReminderEnabled(false)
      ..setNotes('Семейный план');

    expect(await editor.submit(), isTrue);
    final updated = (await repository.getSubscriptions()).single;
    expect(updated.id, original.id);
    expect(updated.name, 'Spotify');
    expect(updated.logo, 'spotify');
    expect(updated.priceInCents, 19950);
    expect(updated.billingCycle, BillingCycle.yearly);
    expect(updated.nextPaymentDate, DateTime(2027, 8, 29));
    expect(updated.reminderEnabled, isFalse);
    expect(updated.notes, 'Семейный план');
    editor.dispose();
  });
}

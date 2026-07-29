import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

@DataClassName('SubscriptionRecord')
class Subscriptions extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get logo => text().nullable()();
  TextColumn get category => text()();
  IntColumn get priceInCents => integer()();
  TextColumn get billingCycle => text()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get nextPaymentDate => dateTime()();
  TextColumn get status => text()();
  IntColumn get totalSpentInCents => integer().withDefault(const Constant(0))();
  BoolColumn get reminderEnabled =>
      boolean().withDefault(const Constant(true))();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('PaymentRecord')
class Payments extends Table {
  TextColumn get id => text()();
  TextColumn get subscriptionId =>
      text().references(Subscriptions, #id, onDelete: KeyAction.cascade)();
  IntColumn get amountInCents => integer()();
  DateTimeColumn get date => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DriftDatabase(tables: <Type>[Subscriptions, Payments])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Stream<List<SubscriptionRecord>> watchAllSubscriptions() {
    return (select(subscriptions)
          ..orderBy(<OrderingTerm Function(Subscriptions)>[
            (table) => OrderingTerm.asc(table.nextPaymentDate),
          ]))
        .watch();
  }

  Future<List<SubscriptionRecord>> getAllSubscriptions() {
    return (select(subscriptions)
          ..orderBy(<OrderingTerm Function(Subscriptions)>[
            (table) => OrderingTerm.asc(table.nextPaymentDate),
          ]))
        .get();
  }

  Future<SubscriptionRecord?> getSubscriptionById(String id) {
    return (select(
      subscriptions,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
  }

  Future<void> insertSubscription(SubscriptionsCompanion entry) async {
    await into(subscriptions).insert(entry);
  }

  Future<bool> replaceSubscription(SubscriptionsCompanion entry) async {
    final changedRows = await (update(
      subscriptions,
    )..where((table) => table.id.equals(entry.id.value))).write(entry);
    return changedRows > 0;
  }

  Future<void> removeSubscription(String id) async {
    await (delete(subscriptions)..where((table) => table.id.equals(id))).go();
  }

  Stream<List<PaymentRecord>> watchPaymentsFor(String subscriptionId) {
    return (select(payments)
          ..where((table) => table.subscriptionId.equals(subscriptionId))
          ..orderBy(<OrderingTerm Function(Payments)>[
            (table) => OrderingTerm.desc(table.date),
          ]))
        .watch();
  }

  Future<List<PaymentRecord>> getPaymentsFor(String subscriptionId) {
    return (select(payments)
          ..where((table) => table.subscriptionId.equals(subscriptionId))
          ..orderBy(<OrderingTerm Function(Payments)>[
            (table) => OrderingTerm.desc(table.date),
          ]))
        .get();
  }

  Future<void> recordPayment(PaymentsCompanion entry) {
    return transaction(() async {
      await into(payments).insert(entry);
      await _refreshTotalSpent(entry.subscriptionId.value);
    });
  }

  Future<void> removePayment(String paymentId) {
    return transaction(() async {
      final payment = await (select(
        payments,
      )..where((table) => table.id.equals(paymentId))).getSingleOrNull();
      if (payment == null) return;

      await (delete(
        payments,
      )..where((table) => table.id.equals(paymentId))).go();
      await _refreshTotalSpent(payment.subscriptionId);
    });
  }

  Future<void> _refreshTotalSpent(String subscriptionId) async {
    final totalExpression = payments.amountInCents.sum();
    final totalQuery = selectOnly(payments)
      ..addColumns(<Expression<Object>>[totalExpression])
      ..where(payments.subscriptionId.equals(subscriptionId));
    final total = (await totalQuery.getSingle()).read(totalExpression) ?? 0;

    await (update(subscriptions)
          ..where((table) => table.id.equals(subscriptionId)))
        .write(SubscriptionsCompanion(totalSpentInCents: Value(total)));
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final databaseFile = File(
      p.join(documentsDirectory.path, 'subberry.sqlite'),
    );
    return NativeDatabase.createInBackground(databaseFile);
  });
}

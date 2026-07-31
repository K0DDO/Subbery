import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:subberry/features/subscriptions/data/local/app_database.dart';

void main() {
  test('migrates version 2 subscriptions to automatic renewal', () async {
    final directory = await Directory.systemTemp.createTemp('subberry-v2-');
    final file = File('${directory.path}/subberry.sqlite');
    final sqlite = sqlite3.open(file.path);
    sqlite
      ..execute('''
        CREATE TABLE subscriptions (
          id TEXT NOT NULL PRIMARY KEY,
          name TEXT NOT NULL,
          logo TEXT,
          category TEXT NOT NULL,
          price_in_cents INTEGER NOT NULL,
          billing_cycle TEXT NOT NULL,
          start_date INTEGER NOT NULL,
          next_payment_date INTEGER NOT NULL,
          billing_anchor_day INTEGER,
          status TEXT NOT NULL,
          total_spent_in_cents INTEGER NOT NULL DEFAULT 0,
          reminder_enabled INTEGER NOT NULL DEFAULT 1 CHECK (reminder_enabled IN (0, 1)),
          notes TEXT
        )
      ''')
      ..execute('''
        CREATE TABLE payments (
          id TEXT NOT NULL PRIMARY KEY,
          subscription_id TEXT NOT NULL REFERENCES subscriptions(id) ON DELETE CASCADE,
          amount_in_cents INTEGER NOT NULL,
          date INTEGER NOT NULL
        )
      ''')
      ..execute(
        '''
        INSERT INTO subscriptions (
          id, name, category, price_in_cents, billing_cycle,
          start_date, next_payment_date, billing_anchor_day, status
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        <Object?>[
          'legacy',
          'Legacy',
          'other',
          10000,
          'monthly',
          DateTime(2026).millisecondsSinceEpoch ~/ 1000,
          DateTime(2026, 8, 1).millisecondsSinceEpoch ~/ 1000,
          1,
          'active',
        ],
      )
      ..userVersion = 2
      ..close();

    final database = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(() async {
      await database.close();
      await directory.delete(recursive: true);
    });

    final migrated = (await database.getAllSubscriptions()).single;

    expect(migrated.id, 'legacy');
    expect(migrated.renewalMode, 'automatic');
    expect(migrated.customIntervalDays, isNull);
    expect(database.schemaVersion, 4);
  });
}

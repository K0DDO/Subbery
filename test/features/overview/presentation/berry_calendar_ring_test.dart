import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subberry/features/overview/application/overview_metrics.dart';
import 'package:subberry/features/overview/presentation/widgets/berry_calendar_ring.dart';
import 'package:subberry/features/subscriptions/domain/entities/subscription.dart';
import 'package:subberry/features/subscriptions/presentation/widgets/service_logo.dart';

void main() {
  testWidgets('selects months counter-clockwise from January', (tester) async {
    var selectedMonth = 1;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 340,
              child: BerryCalendarRing(
                year: 2026,
                now: DateTime(2026, 7, 29),
                occurrences: const [],
                selectedMonth: selectedMonth,
                onMonthSelected: (month) => selectedMonth = month,
              ),
            ),
          ),
        ),
      ),
    );

    final ring = find.byType(BerryCalendarRing);
    await tester.tapAt(tester.getCenter(ring) + const Offset(140, 0));

    expect(selectedMonth, 10);
  });

  test('groups equal dates and keeps farthest arcs outside', () {
    final groups = buildPeriodArcGroups(<PaymentOccurrence>[
      PaymentOccurrence(
        subscription: _subscription('a'),
        date: DateTime(2026, 8, 1),
      ),
      PaymentOccurrence(
        subscription: _subscription('b'),
        date: DateTime(2026, 8, 1),
      ),
      PaymentOccurrence(
        subscription: _subscription('c'),
        date: DateTime(2026, 8, 10),
      ),
      PaymentOccurrence(
        subscription: _subscription('d'),
        date: DateTime(2026, 8, 20),
      ),
      PaymentOccurrence(
        subscription: _subscription('e'),
        date: DateTime(2026, 9, 1),
      ),
      PaymentOccurrence(
        subscription: _subscription('f'),
        date: DateTime(2026, 9, 15),
      ),
      PaymentOccurrence(
        subscription: _subscription('g'),
        date: DateTime(2026, 10, 1),
      ),
    ], DateTime(2026, 7, 29));

    expect(groups, hasLength(4));
    expect(groups.map((group) => group.date).toList(), <DateTime>[
      DateTime(2026, 8, 1),
      DateTime(2026, 8, 10),
      DateTime(2026, 8, 20),
      DateTime(2026, 9, 1),
    ]);
    expect(groups.first.count, 2);
    expect(groups.first.date.isBefore(groups.last.date), isTrue);
  });

  testWidgets('limits payment arcs and shows service logos', (tester) async {
    final occurrences = <PaymentOccurrence>[
      for (var index = 0; index < 6; index++)
        PaymentOccurrence(
          subscription: _subscription('$index'),
          date: DateTime(2026, 8, 1 + index),
        ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 340,
              child: BerryCalendarRing(
                year: 2026,
                now: DateTime(2026, 7, 29),
                occurrences: occurrences,
                selectedMonth: 8,
                showPeriodArcs: true,
                showCalendarLogos: false,
                onMonthSelected: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(ServiceLogo), findsNWidgets(4));
  });

  testWidgets('shows count badge for same-day payments', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 340,
              child: BerryCalendarRing(
                year: 2026,
                now: DateTime(2026, 7, 29),
                occurrences: <PaymentOccurrence>[
                  PaymentOccurrence(
                    subscription: _subscription('a'),
                    date: DateTime(2026, 8, 3),
                  ),
                  PaymentOccurrence(
                    subscription: _subscription('b'),
                    date: DateTime(2026, 8, 3),
                  ),
                  PaymentOccurrence(
                    subscription: _subscription('c'),
                    date: DateTime(2026, 8, 10),
                  ),
                ],
                selectedMonth: 8,
                showPeriodArcs: true,
                showCalendarLogos: false,
                onMonthSelected: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('2'), findsOneWidget);
    expect(find.byType(ServiceLogo), findsOneWidget);
  });

  testWidgets('uses separate sources for calendar logos and period arcs', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 340,
              child: BerryCalendarRing(
                year: 2026,
                now: DateTime(2026, 7, 29),
                occurrences: <PaymentOccurrence>[
                  PaymentOccurrence(
                    subscription: _subscription('a'),
                    date: DateTime(2026, 8, 3),
                  ),
                  PaymentOccurrence(
                    subscription: _subscription('b'),
                    date: DateTime(2026, 9, 10),
                  ),
                ],
                periodArcOccurrences: <PaymentOccurrence>[
                  PaymentOccurrence(
                    subscription: _subscription('arc'),
                    date: DateTime(2026, 10, 4),
                  ),
                ],
                selectedMonth: 8,
                showPeriodArcs: true,
                showCalendarLogos: true,
                onMonthSelected: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    // Two yearly calendar logos + one upcoming-payment endpoint logo.
    expect(find.byType(ServiceLogo), findsNWidgets(3));
  });
}

Subscription _subscription(String id) {
  return Subscription(
    id: id,
    name: 'Service $id',
    category: SubscriptionCategory.entertainment,
    priceInCents: 10000,
    billingCycle: BillingCycle.monthly,
    startDate: DateTime(2026),
    nextPaymentDate: DateTime(2026, 8, 1),
    status: SubscriptionStatus.active,
    totalSpentInCents: 0,
    reminderEnabled: true,
  );
}

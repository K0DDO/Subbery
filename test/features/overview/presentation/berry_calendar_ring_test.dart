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
                onMonthSelected: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(ServiceLogo), findsNWidgets(4));
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

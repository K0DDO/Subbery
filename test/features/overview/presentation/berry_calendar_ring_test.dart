import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subberry/features/overview/presentation/widgets/berry_calendar_ring.dart';

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
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:subberry/features/subscriptions/domain/entities/subscription.dart';
import 'package:subberry/features/subscriptions/presentation/widgets/service_logo.dart';

void main() {
  testWidgets('shows known service brand icon', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ServiceLogo(
            name: 'Netflix',
            logoKey: 'netflix',
            category: SubscriptionCategory.entertainment,
          ),
        ),
      ),
    );

    expect(find.byIcon(SimpleIcons.netflix), findsOneWidget);
    expect(find.text('N'), findsNothing);
  });

  testWidgets('keeps monogram for custom services', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ServiceLogo(
            name: 'Custom',
            category: SubscriptionCategory.other,
          ),
        ),
      ),
    );

    expect(find.text('C'), findsOneWidget);
  });
}

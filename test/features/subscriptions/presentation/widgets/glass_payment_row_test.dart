import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subberry/core/theme/app_theme.dart';
import 'package:subberry/features/subscriptions/presentation/widgets/glass_payment_row.dart';

void main() {
  testWidgets('keeps title and amount on one line on narrow widths', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: SizedBox(
            width: 280,
            child: GlassPaymentRow(
              leading: Icon(Icons.subscriptions_rounded),
              title: 'Очень длинное название подписки для проверки',
              subtitle: '1 авг · следующее списание',
              trailing: '1 999 ₽',
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('название подписки'), findsOneWidget);
    expect(find.text('1 999 ₽'), findsOneWidget);
    expect(find.text('1 авг · следующее списание'), findsOneWidget);

    final amount = tester.getRect(find.text('1 999 ₽'));
    final title = tester.getRect(
      find.text('Очень длинное название подписки для проверки'),
    );
    expect((amount.center.dy - title.center.dy).abs(), lessThan(2));
  });
}

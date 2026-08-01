import 'package:flutter_test/flutter_test.dart';
import 'package:subberry/features/analytics/application/analytics_breakdown.dart';
import 'package:subberry/features/analytics/application/openrouter_insights_service.dart';
import 'package:subberry/features/subscriptions/domain/entities/payment.dart';
import 'package:subberry/features/subscriptions/domain/entities/subscription.dart';

void main() {
  test('builds payment rows for month and year periods', () {
    final netflix = _subscription('netflix', SubscriptionCategory.entertainment);
    final spotify = _subscription('spotify', SubscriptionCategory.music);
    final payments = <Payment>[
      Payment(
        id: 'a',
        subscriptionId: netflix.id,
        amountInCents: 79900,
        date: DateTime(2026, 7, 3),
      ),
      Payment(
        id: 'b',
        subscriptionId: spotify.id,
        amountInCents: 16900,
        date: DateTime(2026, 1, 10),
      ),
    ];

    final monthRows = AnalyticsBreakdown.paymentRows(
      payments: payments,
      subscriptions: <Subscription>[netflix, spotify],
      period: AnalyticsPeriod.month,
      now: DateTime(2026, 7, 29),
    );
    final yearRows = AnalyticsBreakdown.paymentRows(
      payments: payments,
      subscriptions: <Subscription>[netflix, spotify],
      period: AnalyticsPeriod.year,
      now: DateTime(2026, 7, 29),
    );

    expect(monthRows, hasLength(1));
    expect(monthRows.single.name, 'Netflix');
    expect(AnalyticsBreakdown.sumRows(yearRows), 96800);
  });

  test('parses OpenRouter insights JSON even with markdown fence', () {
    const raw = '''
```json
[
  {"title":"Срежьте дубли","detail":"Две стриминговые подписки дают пересечение по контенту"},
  {"title":"Рост к июню","detail":"Июль дороже июня на 12% из-за облака"},
  {"title":"Кандидат на паузу","detail":"Adobe почти не используется последние месяцы"}
]
```
''';
    final insights = OpenRouterInsightsService.parseInsights(raw);
    expect(insights, hasLength(3));
    expect(insights.first.title, 'Срежьте дубли');
    expect(insights.every((item) => item.type.name == 'ai'), isTrue);
  });
}

Subscription _subscription(String id, SubscriptionCategory category) {
  return Subscription(
    id: id,
    name: id == 'netflix' ? 'Netflix' : 'Spotify',
    category: category,
    priceInCents: id == 'netflix' ? 79900 : 16900,
    billingCycle: BillingCycle.monthly,
    startDate: DateTime(2025, 1, 1),
    nextPaymentDate: DateTime(2026, 8, 3),
    status: SubscriptionStatus.active,
    totalSpentInCents: 0,
    reminderEnabled: true,
  );
}

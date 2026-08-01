import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../subscriptions/domain/entities/payment.dart';
import '../../subscriptions/domain/entities/subscription.dart';
import 'analytics_breakdown.dart';
import 'analytics_metrics.dart';
import 'openrouter_insights_service.dart';

/// Prefer `--dart-define=OPENROUTER_API_KEY=...` for release builds.
const _defaultOpenRouterApiKey = String.fromEnvironment('OPENROUTER_API_KEY');

final openRouterInsightsServiceProvider = Provider<OpenRouterInsightsService>((
  ref,
) {
  return OpenRouterInsightsService(defaultApiKey: _defaultOpenRouterApiKey);
});

class AiInsightsRequest {
  const AiInsightsRequest({
    required this.fingerprint,
    required this.summary,
    required this.fallback,
  });

  final String fingerprint;
  final Map<String, Object?> summary;
  final List<AnalyticsInsight> fallback;

  @override
  bool operator ==(Object other) {
    return other is AiInsightsRequest && other.fingerprint == fingerprint;
  }

  @override
  int get hashCode => fingerprint.hashCode;
}

final aiInsightsProvider =
    FutureProvider.family<List<AnalyticsInsight>, AiInsightsRequest>((
      ref,
      request,
    ) async {
      final service = ref.watch(openRouterInsightsServiceProvider);
      try {
        final insights = await service.generateInsights(request.summary);
        if (insights.isEmpty) return request.fallback;
        return insights;
      } catch (_) {
        return request.fallback;
      }
    });

AiInsightsRequest buildAiInsightsRequest({
  required List<Subscription> subscriptions,
  required List<Payment> payments,
  required AnalyticsMetrics metrics,
  required DateTime now,
}) {
  final summary = AnalyticsBreakdown.compactSummary(
    subscriptions: subscriptions,
    payments: payments,
    monthlySpending: metrics.monthlySpending,
    thisMonthInCents: metrics.thisMonthInCents,
    thisYearInCents: metrics.thisYearInCents,
    totalSpentInCents: metrics.totalSpentInCents,
    now: now,
  );
  final fingerprint = [
    now.year,
    now.month,
    now.day,
    metrics.thisMonthInCents,
    metrics.thisYearInCents,
    metrics.totalSpentInCents,
    metrics.monthlySpending
        .map((p) => '${p.amountInCents}/${p.plannedAmountInCents}')
        .join(','),
    metrics.categorySpending
        .map((c) => '${c.category.name}:${c.amountInCents}')
        .join(','),
    subscriptions.length,
    payments.length,
  ].join('|');

  return AiInsightsRequest(
    fingerprint: fingerprint,
    summary: summary,
    fallback: metrics.insights,
  );
}

final openRouterKeyConfiguredProvider = FutureProvider<bool>((ref) async {
  final key = await ref.watch(openRouterInsightsServiceProvider).readApiKey();
  return key != null && key.isNotEmpty;
});

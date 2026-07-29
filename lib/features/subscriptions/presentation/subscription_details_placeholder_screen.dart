import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/empty_state.dart';
import '../application/subscription_providers.dart';

class SubscriptionDetailsPlaceholderScreen extends ConsumerWidget {
  const SubscriptionDetailsPlaceholderScreen({
    required this.subscriptionId,
    super.key,
  });

  final String subscriptionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(subscriptionProvider(subscriptionId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Подписка'),
        backgroundColor: Colors.transparent,
      ),
      body: AppBackground(
        child: subscription.when(
          data: (item) => EmptyState(
            title: item?.name ?? 'Подписка не найдена',
            description: 'История платежей появится на следующем этапе',
            icon: Icons.receipt_long_rounded,
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => const EmptyState(
            title: 'Не удалось открыть подписку',
            description: 'Попробуйте ещё раз',
            icon: Icons.error_outline_rounded,
          ),
        ),
      ),
    );
  }
}

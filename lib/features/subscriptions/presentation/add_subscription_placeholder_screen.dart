import 'package:flutter/material.dart';

import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/empty_state.dart';

class AddSubscriptionPlaceholderScreen extends StatelessWidget {
  const AddSubscriptionPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Новая подписка'),
        backgroundColor: Colors.transparent,
      ),
      body: const AppBackground(
        child: EmptyState(
          title: 'Добавление подписки',
          description: 'Форма появится на следующем этапе',
          icon: Icons.add_card_rounded,
        ),
      ),
    );
  }
}

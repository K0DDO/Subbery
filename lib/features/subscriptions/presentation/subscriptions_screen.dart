import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/screen_header.dart';

class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: <Widget>[
          ScreenHeader(
            title: 'Подписки',
            subtitle: 'Все сервисы в одном месте',
            trailing: IconButton.filled(
              tooltip: 'Добавить подписку',
              onPressed: () => context.push('/subscriptions/add'),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.coral,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.add_rounded),
            ),
          ),
          Expanded(
            child: EmptyState(
              title: 'Пока нет подписок 🍓',
              description:
                  'Добавьте первый сервис,\n'
                  'чтобы начать контролировать расходы',
              actionLabel: 'Добавить подписку',
              onAction: () => context.push('/subscriptions/add'),
            ),
          ),
        ],
      ),
    );
  }
}

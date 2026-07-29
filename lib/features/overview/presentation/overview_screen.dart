import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/screen_header.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: <Widget>[
          const ScreenHeader(
            title: 'Привет, Дима 👋',
            subtitle: 'Контролируйте расходы без лишнего шума',
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

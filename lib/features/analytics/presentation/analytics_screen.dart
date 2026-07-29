import 'package:flutter/material.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/screen_header.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      bottom: false,
      child: Column(
        children: <Widget>[
          ScreenHeader(
            title: 'Аналитика',
            subtitle: 'Понятная картина ваших расходов',
          ),
          Expanded(
            child: EmptyState(
              title: 'Здесь появится аналитика',
              description:
                  'Добавьте подписки, и Subberry покажет\n'
                  'динамику и структуру расходов',
              icon: Icons.auto_graph_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

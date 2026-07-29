import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subberry/app/app.dart';

void main() {
  testWidgets('renders overview empty state', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SubberryApp()));

    expect(find.text('Привет, Дима 👋'), findsOneWidget);
    expect(find.text('Пока нет подписок 🍓'), findsOneWidget);
    expect(find.text('Добавить подписку'), findsOneWidget);
  });

  testWidgets('switches between navigation tabs', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SubberryApp()));

    await tester.tap(find.text('Аналитика'));
    await tester.pumpAndSettle();

    expect(find.text('Здесь появится аналитика'), findsOneWidget);

    await tester.tap(find.text('Настройки'));
    await tester.pumpAndSettle();

    expect(find.text('Версия 1.0.0'), findsOneWidget);
  });
}

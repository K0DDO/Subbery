import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subberry/app/app.dart';

void main() {
  testWidgets('renders the application foundation', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SubberryApp()));

    expect(find.text('Subberry 🍓'), findsOneWidget);
  });
}

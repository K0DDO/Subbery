import 'package:flutter_test/flutter_test.dart';
import 'package:subberry/features/overview/presentation/overview_screen.dart';

void main() {
  test('detects dima4ka admin name case-insensitively', () {
    expect(isAdminDateSimulator('dima4ka'), isTrue);
    expect(isAdminDateSimulator(' DIMA4KA '), isTrue);
    expect(isAdminDateSimulator('Дима'), isFalse);
    expect(isAdminDateSimulator('Анна'), isFalse);
    expect(isAdminDateSimulator(null), isFalse);
    expect(isAdminDateSimulator(''), isFalse);
  });
}

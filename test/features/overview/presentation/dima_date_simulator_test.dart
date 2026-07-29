import 'package:flutter_test/flutter_test.dart';
import 'package:subberry/features/overview/presentation/overview_screen.dart';

void main() {
  test('detects dima name case-insensitively', () {
    expect(isDimaDateSimulator('Дима'), isTrue);
    expect(isDimaDateSimulator(' дима '), isTrue);
    expect(isDimaDateSimulator('ДИМА'), isTrue);
    expect(isDimaDateSimulator('Анна'), isFalse);
    expect(isDimaDateSimulator(null), isFalse);
    expect(isDimaDateSimulator(''), isFalse);
  });
}

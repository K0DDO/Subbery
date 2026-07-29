import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:subberry/core/utils/app_formatters.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ru');
  });

  test('keeps short dates within the current year', () {
    expect(
      AppFormatters.shortDate(
        DateTime(2026, 8, 3),
        now: DateTime(2026, 7, 30),
      ),
      '3 августа',
    );
  });

  test('includes the year for dates outside the current year', () {
    expect(
      AppFormatters.shortDate(
        DateTime(2027, 7, 29),
        now: DateTime(2026, 7, 30),
      ),
      '29 июля 2027',
    );
  });
}

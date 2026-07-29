import 'package:intl/intl.dart';

abstract final class AppFormatters {
  static final _wholeMoney = NumberFormat.currency(
    locale: 'ru_RU',
    symbol: '₽',
    decimalDigits: 0,
  );
  static final _fractionalMoney = NumberFormat.currency(
    locale: 'ru_RU',
    symbol: '₽',
    decimalDigits: 2,
  );
  static final _shortDate = DateFormat('d MMMM', 'ru');
  static final _shortDateWithYear = DateFormat('d MMMM yyyy', 'ru');
  static final _fullDate = DateFormat('dd.MM.yyyy', 'ru');

  static String money(int cents) {
    final formatter = cents % 100 == 0 ? _wholeMoney : _fractionalMoney;
    return formatter.format(cents / 100);
  }

  static String shortDate(DateTime date, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    if (date.year == reference.year) {
      return _shortDate.format(date);
    }
    return _shortDateWithYear.format(date);
  }

  static String fullDate(DateTime date) => _fullDate.format(date);
}

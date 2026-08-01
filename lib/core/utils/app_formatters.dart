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

  /// Formats cents as rubles.
  ///
  /// When [showKopecks] is true, always shows two decimals.
  /// When false, always shows whole rubles (rounded).
  static String money(int cents, {bool showKopecks = false}) {
    if (showKopecks) {
      return _fractionalMoney.format(cents / 100);
    }
    final roundedRubles = (cents / 100).round();
    return _wholeMoney.format(roundedRubles);
  }

  /// Compact ring label used by the overview calendar.
  static String compactMoney(int cents, {bool showKopecks = false}) {
    final rubles = showKopecks ? cents / 100 : (cents / 100).roundToDouble();
    if (rubles.abs() >= 1000) {
      final thousands = rubles / 1000;
      final digits = showKopecks
          ? 1
          : (thousands == thousands.roundToDouble() ? 0 : 1);
      return '${thousands.toStringAsFixed(digits)} тыс. ₽';
    }
    if (showKopecks) {
      return _fractionalMoney.format(rubles);
    }
    return _wholeMoney.format(rubles);
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

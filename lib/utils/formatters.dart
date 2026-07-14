import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final NumberFormat _vnd = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  static String vnd(num value) {
    return _vnd.format(value).trim();
  }

  static String vndCompact(num value) {
    final n = value / 1000;
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(1)}tr ₫';
    }
    if (n >= 1) {
      return '${n.toStringAsFixed(0)}k ₫';
    }
    return '${value.toStringAsFixed(0)} ₫';
  }
}
import 'package:intl/intl.dart';

class Formatters {
  static final _currencyFormat = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
  );

  static final _dateFormat = DateFormat('dd MMM', 'es');

  static String formatPrice(double? price) {
    if (price == null) return '';
    return _currencyFormat.format(price);
  }

  static String formatDiscount(int percent) {
    return '-$percent%';
  }

  static String formatDate(DateTime? date) {
    if (date == null) return '';
    return _dateFormat.format(date);
  }

  static String formatValidUntil(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = date.difference(now).inDays;
    
    if (diff < 0) return 'Expirado';
    if (diff == 0) return 'Último día';
    if (diff == 1) return 'Mañana';
    if (diff <= 7) return 'Quedan $diff días';
    
    return 'Hasta ${formatDate(date)}';
  }
}

import 'package:intl/intl.dart';

extension CurrencyFormatter on num {
  /// Converts a number into a formatted USD currency string (e.g., $12,450.75)
  String toCurrency({String currencyCode = 'USD'}) {
    switch (currencyCode) {
      case 'KHR':
        return NumberFormat.currency(
          locale: 'en_US',
          symbol: '៛',
          decimalDigits: 0,
        ).format(this);
      case 'USD':
      default:
        return NumberFormat.currency(
          locale: 'en_US',
          symbol: '\$',
          decimalDigits: 2,
        ).format(this);
    }
  }
}

import 'package:intl/intl.dart';

final NumberFormat _indianCurrency = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 2,
);

String formatCurrency(double amount) {
  return _indianCurrency.format(amount);
}

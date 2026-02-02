import 'package:intl/intl.dart';

enum Currency { brl, usd, btc, heaven }

class CurrencyFormat {
  static String brl(double amount) {
    return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(amount);
  }

  static String usd(double amount) {
    return NumberFormat.currency(locale: 'en_US', symbol: '\$').format(amount);
  }

  static String btc(double amount) {
    return '${amount.toStringAsFixed(8)} BTC';
  }

  static String format(double amount, Currency type) {
    switch (type) {
      case Currency.heaven:
      case Currency.brl:
        return CurrencyFormat.brl(amount);
      case Currency.usd:
        return CurrencyFormat.usd(amount);
      case Currency.btc:
        return CurrencyFormat.btc(amount);
    }
  }
}

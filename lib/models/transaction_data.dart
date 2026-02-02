import 'currency.dart';

enum TransactionType { buy, sell }

class TransactionData {
  final TransactionType type;
  final Currency from;
  final Currency to;
  final double amount;
  final double price;
  final DateTime timestamp;

  TransactionData({
    required this.type,
    required this.from,
    required this.to,
    required this.amount,
    required this.price,
    required this.timestamp,
  });

  String get name => from == Currency.heaven
      ? 'Ganhou'
      : type == TransactionType.buy
      ? 'Comprou'
      : 'Vendeu';

  Map<String, dynamic> toMap() {
    return {
      'type': type.toString().split('.').last,
      'from': from.toString().split('.').last,
      'to': to.toString().split('.').last,
      'amount': amount,
      'price': price,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory TransactionData.fromMap(Map<String, dynamic> map) {
    return TransactionData(
      type: TransactionType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
      ),
      from: Currency.values.firstWhere(
        (e) => e.toString().split('.').last == map['from'],
      ),
      to: Currency.values.firstWhere(
        (e) => e.toString().split('.').last == map['to'],
      ),
      amount: map['amount'],
      price: map['price'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}

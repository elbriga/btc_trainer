enum TransactionType { buyBtc, sellBtc, buyUsd, sellUsd }

class TransactionData {
  final TransactionType type;
  final double amount;
  final double pricePerUnit;
  final DateTime timestamp;

  TransactionData({
    required this.type,
    required this.amount,
    required this.pricePerUnit,
    required this.timestamp,
  });

  double get total => amount * pricePerUnit;

  Map<String, dynamic> toMap() {
    return {
      'type': type.toString().split('.').last,
      'amount': amount,
      'pricePerUnit': pricePerUnit,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory TransactionData.fromMap(Map<String, dynamic> map) {
    return TransactionData(
      type: TransactionType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
      ),
      amount: map['amount'],
      pricePerUnit: map['pricePerUnit'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}

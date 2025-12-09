enum TransactionType { buy, sell }

class TransactionData {
  final TransactionType type;
  final double btcAmount;
  final double pricePerBtc;
  final DateTime timestamp;

  TransactionData({
    required this.type,
    required this.btcAmount,
    required this.pricePerBtc,
    required this.timestamp,
  });

  double get totalUsd => btcAmount * pricePerBtc;

  Map<String, dynamic> toMap() {
    return {
      'type': type.toString().split('.').last,
      'btcAmount': btcAmount,
      'pricePerBtc': pricePerBtc,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory TransactionData.fromMap(Map<String, dynamic> map) {
    return TransactionData(
      type: TransactionType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
      ),
      btcAmount: map['btcAmount'],
      pricePerBtc: map['pricePerBtc'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}

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
}

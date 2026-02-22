class PriceData {
  final double price;
  final double dollarPrice;
  final DateTime timestamp;

  PriceData({
    required this.price,
    required this.dollarPrice,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'price': price,
      'dollarPrice': dollarPrice,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory PriceData.fromMap(Map<String, dynamic> map) {
    return PriceData(
      price: (map['price'] as num).toDouble(),
      dollarPrice: (map['dollarPrice'] ?? 0 as num).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (map['timestamp'] as num).toInt(),
      ),
    );
  }
}

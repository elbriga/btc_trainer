class PriceData {
  final double price;
  final double dollarPrice; // Add dollarPrice field
  final DateTime timestamp;
  final int consolidate;

  PriceData({
    required this.price,
    required this.dollarPrice,
    required this.timestamp,
    this.consolidate = 0,
  }); // Update constructor

  Map<String, dynamic> toMap() {
    return {
      'price': price,
      'dollarPrice': dollarPrice,
      'timestamp': timestamp.toIso8601String(),
      'consolidate': consolidate,
    };
  }

  factory PriceData.fromMap(Map<String, dynamic> map) {
    return PriceData(
      price: (map['price'] as num).toDouble(),
      dollarPrice: (map['dollarPrice'] as num).toDouble(),
      timestamp: DateTime.parse(map['timestamp']),
      consolidate: ((map['consolidate'] ?? 0) as num).toInt(),
    );
  }
}

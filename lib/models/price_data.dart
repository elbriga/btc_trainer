class PriceData {
  final double price;
  final double dollarPrice; // Add dollarPrice field
  final DateTime timestamp;

  PriceData({required this.price, required this.dollarPrice, required this.timestamp}); // Update constructor

  Map<String, dynamic> toMap() {
    return {
      'price': price,
      'dollarPrice': dollarPrice, // Add dollarPrice to toMap()
      'timestamp': timestamp.toIso8601String()
    };
  }

  factory PriceData.fromMap(Map<String, dynamic> map) {
    return PriceData(
      price: map['price'],
      dollarPrice: map['dollarPrice'], // Add dollarPrice to fromMap()
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}

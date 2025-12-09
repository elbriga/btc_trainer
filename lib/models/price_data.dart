class PriceData {
  final double price;
  final DateTime timestamp;

  PriceData({required this.price, required this.timestamp});

  Map<String, dynamic> toMap() {
    return {'price': price, 'timestamp': timestamp.toIso8601String()};
  }

  factory PriceData.fromMap(Map<String, dynamic> map) {
    return PriceData(
      price: map['price'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}

class PriceData {
  final double btcPrice;
  final double usdPrice;
  final DateTime timestamp;

  PriceData({
    required this.btcPrice,
    required this.usdPrice,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'btcPrice': btcPrice,
      'usdPrice': usdPrice,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory PriceData.fromMap(Map<String, dynamic> map) {
    return PriceData(
      btcPrice: map['btcPrice'],
      usdPrice: map['usdPrice'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}

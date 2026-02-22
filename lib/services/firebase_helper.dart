import 'package:btc_trainer/models/price_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseHelper {
  static final FirebaseHelper instance = FirebaseHelper._init();
  FirebaseHelper._init();

  CollectionReference<Map<String, dynamic>> _getFBCollection({
    String collectionName = 'prices',
  }) {
    return FirebaseFirestore.instance.collection(collectionName);
  }

  Future<List<PriceData>> getPrices() async {
    final snapshot = await _getFBCollection().get();

    final List<PriceData> prices = [];
    for (var doc in snapshot.docs) {
      final data = doc.data();

      prices.add(
        PriceData(
          price: (data['btc_usd'] as num).toDouble(),
          dollarPrice: (data['usd_brl'] as num).toDouble(),
          timestamp: DateTime.parse(doc.id),
        ),
      );
    }

    return prices;
  }
}

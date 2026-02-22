import 'package:btc_trainer/models/price_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseHelper {
  static final FirebaseHelper instance = FirebaseHelper._init();
  FirebaseHelper._init();

  Function? onNewPrice;

  Future<List<PriceData>> getLastPrices() async {
    var prices = await getPrices(last: 30);

    if (onNewPrice != null) onNewPrice!(prices);

    return prices;
  }

  Future<List<PriceData>> getPrices({int last = 0}) async {
    final snapshot = (last == 0)
        ? await _getFBCollection().get()
        : await _getFBCollection()
              .orderBy(FieldPath.documentId, descending: true)
              .limit(last)
              .get();

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

  CollectionReference<Map<String, dynamic>> _getFBCollection({
    String collectionName = 'prices',
  }) {
    return FirebaseFirestore.instance.collection(collectionName);
  }
}

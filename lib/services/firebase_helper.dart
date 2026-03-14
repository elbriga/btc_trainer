import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '/models/currency.dart';
import '/models/price_data.dart';
import '/models/transaction_data.dart';

class FirebaseHelper {
  static final FirebaseHelper instance = FirebaseHelper._init();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseHelper._init();

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> registerWithEmail(
    String email,
    String password,
  ) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<List<PriceData>> getLastPrices({int last = 30}) async {
    return await getPrices(last: last);
  }

  Future<List<PriceData>> getPrices({int last = 0}) async {
    final snapshot = (last == 0)
        ? await _getFBCollection('prices').get()
        : await _getFBCollection(
            'prices',
          ).orderBy(FieldPath.documentId, descending: true).limit(last).get();

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

  Future<void> saveTransaction(TransactionData transaction) async {
    final user = currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .add(transaction.toMap());
  }

  Future<List<TransactionData>> getTransactions() async {
    final user = currentUser;
    if (user == null) return [];

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => TransactionData.fromMap(doc.data()))
        .toList();
  }

  /*
  Future<void> migrateTransactions(List<TransactionData> localTransactions) async {
    final user = currentUser;
    if (user == null) return;

    final collection = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('transactions');

    // Check if we already have transactions to avoid duplicates
    final existing = await collection.limit(1).get();
    if (existing.docs.isNotEmpty) return;

    // Firestore batch limit is 500
    for (var i = 0; i < localTransactions.length; i += 500) {
      final batch = _firestore.batch();
      final end = (i + 500 < localTransactions.length)
          ? i + 500
          : localTransactions.length;
      
      final chunk = localTransactions.sublist(i, end);
      for (var tx in chunk) {
        final docRef = collection.doc();
        batch.set(docRef, tx.toMap());
      }
      await batch.commit();
    }
  }
*/
  Future<TransactionData> insertHeavenTransaction(DateTime? dt) async {
    final brlAmount = 50000.00;
    final transaction = TransactionData(
      type: TransactionType.buy,
      from: Currency.heaven,
      to: Currency.brl,
      amount: brlAmount,
      price: 1.0,
      timestamp: dt ?? DateTime.now(),
    );

    await insertTransaction(transaction);

    return transaction;
  }

  Future insertTransaction(TransactionData transaction) async {
    // final db = await instance.database;
    // await db.insert('transactions', transaction.toMap());
  }

  Future insertTestData() async {
    //await db.rawQuery('DELETE FROM transactions');

    final brlAmount = 50000.00;
    final dollarPrice = 5.20;
    await insertTransaction(
      TransactionData(
        type: TransactionType.buy,
        from: Currency.brl,
        to: Currency.usd,
        amount: brlAmount / dollarPrice,
        price: dollarPrice,
        timestamp: DateTime.now().subtract(Duration(days: 45, minutes: 30)),
      ),
    );

    final usdAmount = brlAmount / dollarPrice;
    final btcPrice = 68217.00;
    await insertTransaction(
      TransactionData(
        type: TransactionType.buy,
        from: Currency.usd,
        to: Currency.btc,
        amount: usdAmount / btcPrice,
        price: btcPrice,
        timestamp: DateTime.now().subtract(Duration(days: 45, minutes: 2)),
      ),
    );
  }

  CollectionReference<Map<String, dynamic>> _getFBCollection(
    String collectionName,
  ) {
    return _firestore.collection(collectionName);
  }
}

import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:btc_trainer/services/firebase_helper.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;

import '/models/price_data.dart';
import '/models/transaction_data.dart';
import '/models/currency.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    _database ??= await _initDB('btc_trainer.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<List<PriceData>> getPrices(DateTime firstTX) async {
    final List<PriceData> prices = [];

    final results = await Future.wait([
      (() async {
        return await FirebaseHelper.instance.getPrices();
      })(),
      (() async {
        return await _fetchHistoryPrices(firstTX);
      })(),
    ]);

    final today = results[0];
    final history = results[1];

    final ontem = DateTime.now().subtract(const Duration(hours: 24));
    for (var h in history) {
      final pd = PriceData.fromMap(h);
      if (pd.timestamp.isBefore(ontem) && pd.timestamp.isAfter(firstTX)) {
        prices.add(pd);
      }
    }
    for (PriceData pd in today) {
      prices.add(pd);
    }

    return prices;
  }

  Future<http.Response> _fetchHttp(String url, {int timeout = 6}) async {
    // print('-------=========.>>>>> $url');
    final response = await http
        .get(Uri.parse(url))
        .timeout(
          Duration(seconds: timeout),
          onTimeout: () {
            throw TimeoutException('The connection has timed out');
          },
        );
    // print('-------=== $url = ${response.statusCode}');

    if (response.statusCode == 200) {
      return response;
    } else {
      throw Exception('Failed to load data: ${response.statusCode}');
    }
  }

  Future<List> _fetchHistoryPrices(DateTime firstTX) async {
    final changeAPIDate = DateTime.now().subtract(Duration(days: 50));
    var url = firstTX.isBefore(changeAPIDate)
        ? 'rainbow?interval=daily'
        : 'pi-cycle-top?interval=hourly&limit=365';

    final response = await _fetchHttp(
      'https://charts.bitcoin.com/api/v1/charts/$url',
    );
    final data = json.decode(response.body);

    List prices = data['data']?['price'] ?? [];
    return prices;
  }

  // Called on app start
  Future checkUpdateDB() async {
    await _dropPricesTable();
    // await insertTestData();
    await _check1stFromHeaven();
  }

  Future _dropPricesTable() async {
    final db = await instance.database;
    db.rawQuery('DROP TABLE IF EXISTS prices');
  }

  Future _check1stFromHeaven() async {
    final db = await instance.database;

    // Check for the 1st Transaction, should be from heaven!
    final mapFirstTx = await db.query(
      'transactions',
      orderBy: 'timestamp ASC',
      limit: 1,
    );
    var tx = mapFirstTx.isEmpty
        ? null
        : TransactionData.fromMap(mapFirstTx.first);
    if (tx == null || tx.from != Currency.heaven) {
      var new1stDate = (tx == null)
          ? DateTime.now()
          : DateTime(
              tx.timestamp.year,
              tx.timestamp.month,
              tx.timestamp.day - 1, // Yesterday
            );

      await insertHeavenTransaction(new1stDate);
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        `from` TEXT NOT NULL,
        `to` TEXT NOT NULL,
        amount REAL NOT NULL,
        price REAL NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');
  }

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
    final db = await instance.database;
    await db.insert('transactions', transaction.toMap());
  }

  Future<List<TransactionData>> getTransactions() async {
    final db = await instance.database;
    final maps = await db.query('transactions', orderBy: 'timestamp DESC');

    if (maps.isNotEmpty) {
      return maps.map((map) => TransactionData.fromMap(map)).toList();
    } else {
      return [];
    }
  }

  Future close() async {
    final db = await instance.database;
    db.close();
    _database = null;
  }

  Future restore(
    String newDbPath, {
    Future<void> Function()? onRestored,
  }) async {
    if (!await File(newDbPath).exists()) {
      throw ('Erro com a nova base!');
    }

    await instance.close();

    try {
      final dbPath = await getDatabasesPath();
      final dbFile = File(join(dbPath, 'btc_trainer.db'));
      final backupFile = File(join(dbPath, 'btc_trainer.db.bak'));

      if (await dbFile.exists()) {
        await dbFile.rename(backupFile.path);
      }

      await File(newDbPath).copy(dbFile.path);

      await instance.database;

      if (onRestored != null) {
        await onRestored();
      }

      if (await backupFile.exists()) {
        await backupFile.delete();
      }

      // Wait a bit for the user to see the animation!
      await Future.delayed(const Duration(milliseconds: 1500));
    } catch (e) {
      final dbPath = await getDatabasesPath();
      final dbFile = File(join(dbPath, 'btc_trainer.db'));
      final backupFile = File(join(dbPath, 'btc_trainer.db.bak'));

      if (await backupFile.exists()) {
        if (await dbFile.exists()) {
          await dbFile.delete();
        }
        await backupFile.rename(dbFile.path);
      }
      await instance.database;

      throw ('Erro ao restaurar a base!');
    }
  }

  Future insertTestData() async {
    final db = await instance.database;
    await db.rawQuery('DELETE FROM transactions');

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
}

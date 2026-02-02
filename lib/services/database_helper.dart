import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

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

  void checkUpdateDB() async {
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
      //print('===>>> Add 1st BRL R\$ 50k!');

      var new1stDate = tx == null
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
      CREATE TABLE prices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        price REAL NOT NULL,
        dollarPrice REAL NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');

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

  Future<void> insertPrice(PriceData price) async {
    final db = await instance.database;
    await db.insert('prices', price.toMap());
  }

  Future<List<PriceData>> getPrices() async {
    final db = await instance.database;
    final maps = await db.query('prices', orderBy: 'timestamp ASC');

    if (maps.isNotEmpty) {
      return maps.map((map) => PriceData.fromMap(map)).toList();
    } else {
      return [];
    }
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

  Future<void> insertTransaction(TransactionData transaction) async {
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

  Future restore(String newDbPath) async {
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
}

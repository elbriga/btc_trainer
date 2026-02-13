import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:synchronized/synchronized.dart';

import '/models/price_data.dart';
import '/models/transaction_data.dart';
import '/models/currency.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  final _lock = Lock();

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    await _lock.synchronized(() async {
      _database ??= await _initDB('btc_trainer.db');
    });
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  // Called on app start
  Future checkUpdateDB() async {
    _checkConsolidateColumn();
    _check1stFromHeaven();
    _fixZeroes();
    _consolidate();
  }

  Future _fixZeroes() async {
    final db = await instance.database;
    db.rawQuery('DELETE FROM prices WHERE price = 0 OR dollarPrice = 0');
  }

  Future<bool> _columnExists(
    Database db,
    String tableName,
    String columnName,
  ) async {
    final List<Map<String, dynamic>> tableInfo = await db.rawQuery(
      'PRAGMA table_info($tableName)',
    );

    for (var column in tableInfo) {
      if (column['name'] == columnName) {
        return true;
      }
    }
    return false;
  }

  Future _checkConsolidateColumn() async {
    final db = await instance.database;
    if (!await _columnExists(db, 'prices', 'consolidate')) {
      await db.execute(
        'ALTER TABLE prices ADD COLUMN consolidate INTEGER DEFAULT 0',
      );
    }
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
        timestamp TEXT NOT NULL,
        consolidate INTEGER DEFAULT 0
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

  // Called by BackGroundService
  Future<void> insertPrice(PriceData price) async {
    var db = await instance.database;
    try {
      await db.insert('prices', price.toMap());
    } on DatabaseException catch (_) {
      // happens when restore db
      await instance.close();
      db = await instance.database;
      await db.insert('prices', price.toMap());
    }
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

  // Group the minutes of the same hour => / 60
  Future _consolidate() async {
    final db = await instance.database;

    // We'll consolidate entries older than today to avoid
    // consolidating data that is still being collected.
    final keep = Duration(hours: 24);
    final now = DateTime.now();
    final sk = now.subtract(keep);
    final consolidationCutOff = DateTime(sk.year, sk.month, sk.day, sk.hour);
    final consolidationCutOffString = consolidationCutOff.toIso8601String();

    String whereClause =
        '(consolidate IS NULL OR consolidate < 60) AND timestamp < ?';
    List<String> whereArgs = [consolidationCutOffString];

    final consolidatedPrices = await db.rawQuery('''
      SELECT
        AVG(price) as price,
        AVG(dollarPrice) as dollarPrice,
        strftime('%Y-%m-%d %H:00:00.000', timestamp) as timestamp,
        60 as consolidate
      FROM prices
      WHERE $whereClause
      GROUP BY strftime('%Y-%m-%d %H', timestamp)
    ''', whereArgs);

    if (consolidatedPrices.isEmpty) {
      print('------------===========>> RETURN');
      return;
    }

    var prices = await getPrices();
    print('------------===========>> Prices before: ${prices.length}');

    await db.transaction((txn) async {
      // Delete the old, minutely entries
      await txn.delete('prices', where: whereClause, whereArgs: whereArgs);

      // Insert the new, hourly-averaged entries
      final batch = txn.batch();
      for (var price in consolidatedPrices) {
        batch.insert('prices', price);
      }
      await batch.commit(noResult: true);
    });

    prices = await getPrices();
    print('------------===========>> Prices after: ${prices.length}');
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
}

import 'dart:async';

import 'package:btc_trainer/main.dart' as app_main;
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../models/currency.dart';
import '../models/price_data.dart';
import '../models/transaction_data.dart';
import '../services/database_helper.dart';

class WalletViewModel extends ChangeNotifier {
  final dbHelper = DatabaseHelper.instance;

  double _brlBalance = 50000.00;
  double _usdBalance = 0.0;
  double _btcBalance = 0.0;

  List<PriceData> _priceHistory = [];
  List<TransactionData> _transactions = [];
  bool _isLoading = true;
  String? _errorMessage;

  double get brlBalance => _brlBalance;
  double get usdBalance => _usdBalance;
  double get btcBalance => _btcBalance;

  List<PriceData> get priceHistory => _priceHistory;
  List<TransactionData> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double get currentBtcPrice =>
      _priceHistory.isEmpty ? 0 : _priceHistory.last.price;
  double get currentUsdBrlPrice =>
      _priceHistory.isEmpty ? 0 : _priceHistory.last.dollarPrice;

  WalletViewModel() {
    _initialize();
  }

  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _priceHistory = await dbHelper.getPrices();
      _transactions = await dbHelper.getTransactions();
      _recalculateBalances();

      FlutterBackgroundService().on('update').listen((event) {
        if (event == null) return;
        final newPrice = PriceData(
          price: (event['btcPrice'] as num).toDouble(),
          dollarPrice: (event['usdPrice'] as num).toDouble(),
          timestamp: DateTime.parse(event['timestamp']),
        );
        addNewPrice(newPrice);
      });
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _recalculateBalances() {
    double brl = 50000.00;
    double usd = 0.0;
    double btc = 0.0;

    for (final transaction in _transactions.reversed) {
      if (transaction.type == TransactionType.buy) {
        if (transaction.from == Currency.brl &&
            transaction.to == Currency.usd) {
          brl -= transaction.amount * transaction.price;
          usd += transaction.amount;
        } else if (transaction.from == Currency.usd &&
            transaction.to == Currency.btc) {
          usd -= transaction.amount * transaction.price;
          btc += transaction.amount;
        }
      } else if (transaction.type == TransactionType.sell) {
        if (transaction.from == Currency.usd &&
            transaction.to == Currency.brl) {
          usd -= transaction.amount;
          brl += transaction.amount * transaction.price;
        } else if (transaction.from == Currency.btc &&
            transaction.to == Currency.usd) {
          btc -= transaction.amount;
          usd += transaction.amount * transaction.price;
        }
      }
    }
    _brlBalance = brl;
    _usdBalance = usd;
    _btcBalance = btc;
  }

  void addNewPrice(PriceData newPrice) {
    _priceHistory.add(newPrice);
    if (_priceHistory.length > 100) {
      _priceHistory.removeAt(0);
    }
    notifyListeners();
  }

  Future<void> buyUsd(double brlAmount) async {
    if (brlAmount > 0 && brlAmount <= _brlBalance) {
      final price = currentUsdBrlPrice;
      if (price == 0) return;

      final usdAmount = brlAmount / price;
      final transaction = TransactionData(
        type: TransactionType.buy,
        from: Currency.brl,
        to: Currency.usd,
        amount: usdAmount,
        price: price,
        timestamp: DateTime.now(),
      );

      await dbHelper.insertTransaction(transaction);
      _transactions.insert(0, transaction);
      _recalculateBalances();
      notifyListeners();
    }
  }

  Future<void> sellUsd(double usdAmount) async {
    if (usdAmount > 0 && usdAmount <= _usdBalance) {
      final price = currentUsdBrlPrice;
      if (price == 0) return;

      final transaction = TransactionData(
        type: TransactionType.sell,
        from: Currency.usd,
        to: Currency.brl,
        amount: usdAmount,
        price: price,
        timestamp: DateTime.now(),
      );

      await dbHelper.insertTransaction(transaction);
      _transactions.insert(0, transaction);
      _recalculateBalances();
      notifyListeners();
    }
  }

  Future<void> buyBtc(double usdAmount) async {
    if (usdAmount > 0 && usdAmount <= _usdBalance) {
      final price = currentBtcPrice;
      if (price == 0) return;

      final btcAmount = usdAmount / price;
      final transaction = TransactionData(
        type: TransactionType.buy,
        from: Currency.usd,
        to: Currency.btc,
        amount: btcAmount,
        price: price,
        timestamp: DateTime.now(),
      );

      await dbHelper.insertTransaction(transaction);
      _transactions.insert(0, transaction);
      _recalculateBalances();
      notifyListeners();
    }
  }

  Future<void> sellBtc(double btcAmount) async {
    if (btcAmount > 0 && btcAmount <= _btcBalance) {
      final price = currentBtcPrice;
      if (price == 0) return;

      final transaction = TransactionData(
        type: TransactionType.sell,
        from: Currency.btc,
        to: Currency.usd,
        amount: btcAmount,
        price: price,
        timestamp: DateTime.now(),
      );

      await dbHelper.insertTransaction(transaction);
      _transactions.insert(0, transaction);
      _recalculateBalances();
      notifyListeners();
    }
  }
}

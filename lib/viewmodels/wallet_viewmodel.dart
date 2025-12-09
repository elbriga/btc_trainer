import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../models/price_data.dart';
import '../models/transaction_data.dart';
import '../services/database_helper.dart';

class WalletViewModel extends ChangeNotifier {
  final dbHelper = DatabaseHelper.instance;

  double _usdBalance = 10000.00;
  double _btcBalance = 0.0;
  List<PriceData> _priceHistory = [];
  List<TransactionData> _transactions = [];
  bool _isLoading = true;
  String? _errorMessage;

  double get usdBalance => _usdBalance;
  double get btcBalance => _btcBalance;
  List<PriceData> get priceHistory => _priceHistory;
  List<TransactionData> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double get currentBtcPrice =>
      _priceHistory.isEmpty ? 0 : _priceHistory.last.price;

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
          price: (event['current_price'] as num).toDouble(),
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
    double usd = 10000.00;
    double btc = 0.0;

    for (final transaction in _transactions.reversed) {
      if (transaction.type == TransactionType.buy) {
        final usdAmount = transaction.totalUsd;
        if (usd >= usdAmount) {
          usd -= usdAmount;
          btc += transaction.btcAmount;
        }
      } else if (transaction.type == TransactionType.sell) {
        if (btc >= transaction.btcAmount) {
          btc -= transaction.btcAmount;
          usd += transaction.totalUsd;
        }
      }
    }
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

  Future<void> buyBtc(double usdAmount) async {
    if (usdAmount > 0 && usdAmount <= _usdBalance) {
      final price = currentBtcPrice;
      if (price == 0) return;

      final btcAmount = usdAmount / price;
      final transaction = TransactionData(
        type: TransactionType.buy,
        btcAmount: btcAmount,
        pricePerBtc: price,
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
        btcAmount: btcAmount,
        pricePerBtc: price,
        timestamp: DateTime.now(),
      );

      await dbHelper.insertTransaction(transaction);
      _transactions.insert(0, transaction);
      _recalculateBalances();
      notifyListeners();
    }
  }
}

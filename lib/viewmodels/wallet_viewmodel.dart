import 'dart:async';
import 'package:flutter/material.dart';

import '/models/currency.dart';
import '/models/price_data.dart';
import '/models/transaction_data.dart';
import '/services/database_helper.dart';
import '/services/firebase_helper.dart';

class WalletViewModel extends ChangeNotifier with WidgetsBindingObserver {
  final dbHelper = DatabaseHelper.instance;
  Timer? _timer;
  DateTime? _lastPricesFetch;

  double _brlBalance = 0.0;
  double _usdBalance = 0.0;
  double _btcBalance = 0.0;

  List<PriceData> _priceHistory = [];
  List<TransactionData> _transactions = [];
  bool _isLoading = true;

  double get brlBalance => _brlBalance;
  double get usdBalance => _usdBalance;
  double get btcBalance => _btcBalance;

  bool isPriceUpdated() {
    return _priceHistory.isEmpty
        ? false
        : _priceHistory.last.timestamp.isAfter(
            DateTime.now().subtract(const Duration(minutes: 3)),
          );
  }

  List<PriceData> get priceHistory => _priceHistory;
  List<TransactionData> get transactions => _transactions;
  bool get isLoading => _isLoading;

  double get currentBtcPrice =>
      _priceHistory.isEmpty ? 0 : _priceHistory.last.price;
  double get currentUsdBrlPrice =>
      _priceHistory.isEmpty ? 0 : _priceHistory.last.dollarPrice;

  double get quantoVeioDoCeu => _transactions.fold(
    0.0,
    (soma, t) => soma + (t.from == Currency.heaven ? t.amount : 0.0),
  );

  WalletViewModel() {
    WidgetsBinding.instance.addObserver(this);
    initialize();
  }

  void _timerFunction(Timer? timer) {
    if (_priceHistory.isEmpty) {
      // safety check if we are initialized
      return;
    }

    // This function will call the callback _onNewPriceFromBGService
    FirebaseHelper.instance.getLastPrices();

    _lastPricesFetch = DateTime.now();
  }

  void startTimer() {
    _timer ??= Timer.periodic(Duration(minutes: 1), _timerFunction);
  }

  void stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    stopTimer();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      final tooooLong = DateTime.now().subtract(const Duration(minutes: 30));
      final tooLong = DateTime.now().subtract(const Duration(minutes: 1));

      if (_lastPricesFetch == null || _lastPricesFetch!.isBefore(tooooLong)) {
        // fetch all price data again
        initialize();
      } else if (_lastPricesFetch!.isBefore(tooLong)) {
        _timerFunction(null);
      }
      startTimer();
    } else if (state == AppLifecycleState.paused) {
      stopTimer();
    }
  }

  Future<void> initialize() async {
    // avoid a new price while initing
    FirebaseHelper.instance.onNewPrice = null;

    _priceHistory = [];
    _transactions = [];

    _isLoading = true;
    notifyListeners();

    await _loadTransactionsData();

    _isLoading = false;
    notifyListeners();

    await _loadPricesData();

    FirebaseHelper.instance.onNewPrice = _onNewPriceFromBGService;
    notifyListeners();
  }

  Future _loadTransactionsData() async {
    _transactions = await dbHelper.getTransactions();
    _recalculateBalances();
  }

  Future _loadPricesData() async {
    DateTime firstTX = getFirstBtcTransaction();
    _priceHistory = await dbHelper.getPrices(firstTX);
  }

  DateTime getFirstBtcTransaction() {
    DateTime? first;
    DateTime ontem = DateTime.now().subtract(const Duration(hours: 24));

    for (var t in _transactions.reversed) {
      if (t.to == Currency.btc) {
        first = t.timestamp;
        if (first.isAfter(ontem)) {
          first = ontem;
        }
        break;
      }
    }

    return first ?? ontem;
  }

  // called by BalanceDisplay Widget
  double getAverageBtcPrice() {
    final buys = _transactions.where(
      (t) => t.type == TransactionType.buy && t.to == Currency.btc,
    );

    if (buys.isEmpty) return 0.0;

    final totalInvested = buys.fold<double>(
      0.0,
      (sum, t) => sum + (t.price * t.amount),
    );

    final totalBtc = buys.fold<double>(0.0, (sum, t) => sum + t.amount);

    if (totalBtc == 0) return 0.0;

    return totalInvested / totalBtc;
  }

  double getTrend(Duration duration) {
    if (_priceHistory.isEmpty) return 0.0;

    final now = DateTime.now();
    final relevantPrices = _priceHistory.where((priceData) {
      return now.difference(priceData.timestamp) <= duration;
    }).toList();

    if (relevantPrices.isEmpty) return 0.0;

    double initPrice = relevantPrices.first.price;
    double lastPrice = relevantPrices.last.price;

    if (initPrice == 0) return 0.0;

    return ((lastPrice - initPrice) / initPrice) * 100;
  }

  Future _onNewPriceFromBGService(List<PriceData> lastPrices) async {
    for (var pd in lastPrices.reversed) {
      if (!_priceHistory.any((element) => element.timestamp == pd.timestamp)) {
        _priceHistory.add(pd);
      }
    }

    notifyListeners();
  }

  Future<double> getHeavenIntervention() async {
    var transaction = await dbHelper.insertHeavenTransaction(null);
    _transactions.insert(0, transaction);
    _recalculateBalances();
    notifyListeners();

    return transaction.amount;
  }

  void _recalculateBalances() {
    _brlBalance = 0.0;
    _usdBalance = 0.0;
    _btcBalance = 0.0;

    for (final transaction in _transactions.reversed) {
      if (transaction.type == TransactionType.buy) {
        if (transaction.from == Currency.heaven &&
            transaction.to == Currency.brl) {
          _brlBalance += transaction.amount;
        } else if (transaction.from == Currency.brl &&
            transaction.to == Currency.usd) {
          _brlBalance -= transaction.amount * transaction.price;
          if (_brlBalance < 0.1) _brlBalance = 0; // rounding issues
          _usdBalance += transaction.amount;
        } else if (transaction.from == Currency.usd &&
            transaction.to == Currency.btc) {
          _usdBalance -= transaction.amount * transaction.price;
          if (_usdBalance < 0.1) _usdBalance = 0; // rounding issues
          _btcBalance += transaction.amount;
        }
      } else if (transaction.type == TransactionType.sell) {
        if (transaction.from == Currency.usd &&
            transaction.to == Currency.brl) {
          _usdBalance -= transaction.amount;
          if (_usdBalance < 0.1) _usdBalance = 0; // rounding issues
          _brlBalance += transaction.amount * transaction.price;
        } else if (transaction.from == Currency.btc &&
            transaction.to == Currency.usd) {
          _btcBalance -= transaction.amount;
          if (_btcBalance < 0.1) _btcBalance = 0; // rounding issues
          _usdBalance += transaction.amount * transaction.price;
        }
      }
    }
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

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/price_data.dart';
import '../services/api_service.dart';

class WalletViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  double _usdBalance = 10000.00; // Starting with $10,000 fake money
  double _btcBalance = 0.0;
  List<PriceData> _priceHistory = [];
  Timer? _timer;
  bool _isLoading = true;
  String? _errorMessage;

  double get usdBalance => _usdBalance;
  double get btcBalance => _btcBalance;
  List<PriceData> get priceHistory => _priceHistory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double get currentBtcPrice => _priceHistory.isEmpty ? 0 : _priceHistory.last.price;

  WalletViewModel() {
    _initialize();
  }

  void _initialize() {
    _fetchPrice();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _fetchPrice();
    });
  }

  Future<void> _fetchPrice() async {
    _isLoading = _priceHistory.isEmpty;
    _errorMessage = null;
    notifyListeners();

    try {
      final price = await _apiService.fetchBtcPrice();
      _priceHistory.add(PriceData(price: price, timestamp: DateTime.now()));
      // Keep the history to a reasonable size, e.g., last 100 data points
      if (_priceHistory.length > 100) {
        _priceHistory.removeAt(0);
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void buyBtc(double usdAmount) {
    if (usdAmount > 0 && usdAmount <= _usdBalance) {
      final btcAmount = usdAmount / currentBtcPrice;
      _usdBalance -= usdAmount;
      _btcBalance += btcAmount;
      notifyListeners();
    }
  }

  void sellBtc(double btcAmount) {
    if (btcAmount > 0 && btcAmount <= _btcBalance) {
      final usdAmount = btcAmount * currentBtcPrice;
      _btcBalance -= btcAmount;
      _usdBalance += usdAmount;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

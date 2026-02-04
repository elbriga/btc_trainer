import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_background_service/flutter_background_service.dart';

import '/services/database_helper.dart';
import '/models/price_data.dart';

class PricesBackgroundService {
  ServiceInstance service;

  Timer? _timer;
  final _dbHelper = DatabaseHelper.instance;

  double _currBtcPrice = 0.0;
  double _currUsdPrice = 0.0;

  PricesBackgroundService(this.service);

  Future init() async {
    await _fetchPrices(null);
    _timer = Timer.periodic(const Duration(minutes: 1), _fetchPrices);
  }

  void shutdown() {
    // Where to shut down this timer?
    _timer?.cancel();
  }

  Future _fetchPrices(Timer? timer) async {
    final results = await Future.wait([
      (() async {
        try {
          return await _fetchBtcPrice();
        } catch (e) {
          print('=================>>>>>>>>> Erro BTC: $e');
          return _currBtcPrice;
        }
      })(),
      (() async {
        try {
          return await _fetchUsdBrlPrice();
        } catch (e) {
          print('=============>>>>>>>>>>> Erro USD: $e');
          return _currUsdPrice;
        }
      })(),
    ]);

    _currBtcPrice = results[0];
    _currUsdPrice = results[1];

    // print('=================>>>>>>>>> CURR BTC $_currBtcPrice');
    // print('=================>>>>>>>>> CURR USD $_currUsdPrice');

    final priceData = PriceData(
      price: _currBtcPrice,
      dollarPrice: _currUsdPrice,
      timestamp: DateTime.now(),
    );

    _dbHelper.insertPrice(priceData);

    service.invoke('update', {
      "price": _currBtcPrice,
      "dollarPrice": _currUsdPrice,
      "timestamp": priceData.timestamp.toIso8601String(),
    });
  }

  Future<http.Response> _fetchHttp(String url) async {
    int retries = 3;
    while (retries > 0) {
      try {
        return await http.get(Uri.parse(url));
      } catch (_) {}
      retries--;
      await Future.delayed(Duration(seconds: 2));
    }
    throw Exception('Falha _fetchHttp($url)');
  }

  Future<double> _fetchUsdBrlPrice() async {
    // print('==============>>>>>>>>>>>>>>>> fetchUsdPrice()');
    // print('==============>>>>>>>>>>>>>>>  fetchUsdPrice()');
    // print('==============>>>>>>>>>>>>>>>> fetchUsdPrice()');
    http.Response response = await _fetchHttp(
      'https://economia.awesomeapi.com.br/json/last/USD-BRL',
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return double.tryParse(data['USDBRL']['high']) ?? 0.00;
    } else {
      throw Exception('Falha ao carregar o preço do USD-BRL');
    }
  }

  Future<double> _fetchBtcPrice() async {
    // print('==============>>>>>>>>>>>>>>>> fetchBtcPrice()');
    // print('==============>>>>>>>>>>>>>>>  fetchBtcPrice()');
    // print('==============>>>>>>>>>>>>>>>> fetchBtcPrice()');
    http.Response response = await _fetchHttp(
      'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd',
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['bitcoin']['usd'].toDouble();
    } else {
      throw Exception('Falha ao carregar o preço do BTC');
    }
  }
}

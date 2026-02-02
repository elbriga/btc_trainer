import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_background_service/flutter_background_service.dart';

import '/models/price_data.dart';

class PricesBackgroundService {
  ServiceInstance service;

  double _currBtcPrice = 0.0;
  double _currUsdPrice = 0.0;

  PricesBackgroundService(this.service);

  void init() {
    timerFunc(null);
    Timer.periodic(const Duration(minutes: 1), timerFunc);
    // TODO :: where to shut down this timer?
  }

  void timerFunc(Timer? timer) async {
    double btc;
    try {
      btc = await fetchBtcPrice();
    } catch (e) {
      // print('Erro BTC: $e');
      if (_currBtcPrice == 0.0) return; // Dont save if dont have value yet
      btc = _currBtcPrice; // Use old value
    }
    _currBtcPrice = btc;

    double usd;
    try {
      usd = await fetchUsdBrlPrice();
    } catch (e) {
      // print('Erro USD: $e');
      if (_currUsdPrice == 0.0) return; // Dont save if dont have value yet
      usd = _currUsdPrice; // Use old value
    }
    _currUsdPrice = usd;

    final priceData = PriceData(
      price: _currBtcPrice,
      dollarPrice: _currUsdPrice,
      timestamp: DateTime.now(),
    );

    service.invoke('update', {
      "btcPrice": _currBtcPrice,
      "usdPrice": _currUsdPrice,
      "timestamp": priceData.timestamp.toIso8601String(),
    });
  }

  Future<double> fetchUsdBrlPrice() async {
    http.Response response;
    try {
      response = await http.get(
        Uri.parse('https://economia.awesomeapi.com.br/json/last/USD-BRL'),
      );
    } catch (e) {
      throw Exception('Falha ao conectar ao servidor :: $e');
    }

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return double.tryParse(data['USDBRL']['high']) ?? 0.00;
    } else {
      throw Exception('Falha ao carregar o preço do USD-BRL');
    }
  }

  Future<double> fetchBtcPrice() async {
    http.Response response;
    try {
      response = await http.get(
        Uri.parse(
          'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd',
        ),
      );
    } catch (e) {
      throw Exception('Falha ao conectar ao servidor :: $e');
    }

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['bitcoin']['usd'].toDouble();
    } else {
      throw Exception('Falha ao carregar o preço do BTC');
    }
  }
}

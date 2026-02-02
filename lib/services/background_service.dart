import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_background_service/flutter_background_service.dart';

import '/models/price_data.dart';

class PricesBackgroundService {
  ServiceInstance service;
  Timer? _timer;

  double _currBtcPrice = 0.0;
  double _currUsdPrice = 0.0;

  PricesBackgroundService(this.service);

  Future init() async {
    await _fetchPrices(null);
    _timer = Timer.periodic(const Duration(minutes: 1), _fetchPrices);
  }

  void shutdown() {
    // TODO :: where to shut down this timer?
    _timer?.cancel();
  }

  Future _fetchPrices(Timer? timer) async {
    final results = await Future.wait([
      (() async {
        try {
          return await fetchBtcPrice();
        } catch (e) {
          print('=================>>>>>>>>> Erro BTC: $e');
          return _currBtcPrice == 0.0 ? null : _currBtcPrice;
        }
      })(),
      (() async {
        try {
          return await fetchUsdBrlPrice();
        } catch (e) {
          print('=============>>>>>>>>>>> Erro USD: $e');
          return _currUsdPrice == 0.0 ? null : _currUsdPrice;
        }
      })(),
    ]);

    final btc = results[0];
    final usd = results[1];

    if (btc != null) {
      _currBtcPrice = btc;
    }
    if (usd != null) {
      _currUsdPrice = usd;
    }

    print('=================>>>>>>>>> CURR BTC $_currBtcPrice');
    print('=================>>>>>>>>> CURR USD $_currUsdPrice');

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
    print('==============>>>>>>>>>>>>>>>> fetchUsdPrice()');
    print('==============>>>>>>>>>>>>>>>  fetchUsdPrice()');
    print('==============>>>>>>>>>>>>>>>> fetchUsdPrice()');
    http.Response response;
    try {
      response = await http.get(
        Uri.parse('https://economia.awesomeapi.com.br/json/last/USD-BRL'),
      );
    } catch (e) {
      throw Exception('Falha ao conectar ao servidor USD :: $e');
    }

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return double.tryParse(data['USDBRL']['high']) ?? 0.00;
    } else {
      throw Exception('Falha ao carregar o preço do USD-BRL');
    }
  }

  Future<double> fetchBtcPrice() async {
    print('==============>>>>>>>>>>>>>>>> fetchBtcPrice()');
    print('==============>>>>>>>>>>>>>>>  fetchBtcPrice()');
    print('==============>>>>>>>>>>>>>>>> fetchBtcPrice()');
    http.Response response;
    try {
      response = await http.get(
        Uri.parse(
          'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd',
        ),
      );
    } catch (e) {
      throw Exception('Falha ao conectar ao servidor BTC :: $e');
    }

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['bitcoin']['usd'].toDouble();
    } else {
      throw Exception('Falha ao carregar o preço do BTC');
    }
  }
}

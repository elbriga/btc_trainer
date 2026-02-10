import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_background_service/flutter_background_service.dart';

import '/services/database_helper.dart';
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
          // 1st API
          return await _fetchUsdBrlPrice2();
        } catch (e) {
          print('=============>>>>>>>>>>> Erro USD2: $e');

          try {
            // 2nd API backup
            return await _fetchUsdBrlPrice();
          } catch (e) {
            print('=============>>>>>>>>>>> Erro USD1: $e');
          }

          return _currUsdPrice;
        }
      })(),
    ]);

    _currBtcPrice = results[0];
    _currUsdPrice = results[1];

    print('=================>>>>>>>>> CURR BTC $_currBtcPrice');
    print('=================>>>>>>>>> CURR USD $_currUsdPrice');

    final priceData = PriceData(
      price: _currBtcPrice,
      dollarPrice: _currUsdPrice,
      timestamp: DateTime.now(),
    );

    final dbHelper = DatabaseHelper.instance;
    dbHelper.insertPrice(priceData);

    service.invoke('update', {
      "price": _currBtcPrice,
      "dollarPrice": _currUsdPrice,
      "timestamp": priceData.timestamp.toIso8601String(),
    });
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

  Future<double> _fetchBtcPrice() async {
    var url =
        'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd';
    // print('==============>>>>>>>>>>>>>>>> fetchBtcPrice()');
    // print('=== $url');
    // print('==============>>>>>>>>>>>>>>>> fetchBtcPrice()');

    final response = await _fetchHttp(url);
    final data = json.decode(response.body);
    return data['bitcoin']['usd'].toDouble();
  }

  Future<double> _fetchUsdBrlPrice() async {
    var url = 'https://economia.awesomeapi.com.br/json/last/USD-BRL';
    // print('==============>>>>>>>>>>>>>>>> fetchUsdPrice()');
    // print('=== $url');
    // print('==============>>>>>>>>>>>>>>>> fetchUsdPrice()');

    final response = await _fetchHttp(url);
    final data = json.decode(response.body);
    return double.tryParse(data['USDBRL']['high']) ?? 0.00;
  }

  Future<double> _fetchUsdBrlPrice2() async {
    var url = 'https://api.frankfurter.dev/v1/latest?base=USD&symbols=BRL';
    // print('==============>>>>>>>>>>>>>>>> fetchUsdPrice()');
    // print('=== $url');
    // print('==============>>>>>>>>>>>>>>>> fetchUsdPrice()');

    final response = await _fetchHttp(url);
    final data = json.decode(response.body);
    return (data['rates']['BRL'] as num).toDouble();
  }
}

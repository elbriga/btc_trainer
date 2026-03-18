import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;

import '/viewmodels/wallet_viewmodel.dart';
import '/services/firebase_helper.dart';
import '/models/price_data.dart';
import '/models/transaction_data.dart';
import '/models/currency.dart';

class HttpHelper {
  static final HttpHelper instance = HttpHelper._init();

  HttpHelper._init();

  int _getPricesExecID = 0; // Avoid concurrency problems
  Future<List<PriceData>> getPrices(DateTime firstTX) async {
    final List<PriceData> prices = [];

    int myExecID = ++_getPricesExecID;

    final results = await Future.wait([
      (() async {
        return await FirebaseHelper.instance.getPrices();
      })(),
      (() async {
        return await _fetchHistoryPrices(firstTX);
      })(),
    ]);

    if (myExecID != _getPricesExecID) {
      throw HistoryFetchException('OBSOLET $myExecID');
    }

    final today = results[0];
    final history = results[1];

    final ontem = DateTime.now().subtract(const Duration(hours: 24));
    for (var h in history) {
      final pd = PriceData.fromMap(h);
      if (pd.timestamp.isBefore(ontem) && pd.timestamp.isAfter(firstTX)) {
        prices.add(pd);
      }
    }
    for (PriceData pd in today) {
      prices.add(pd);
    }

    return prices;
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

  Future<List> _fetchHistoryPrices(DateTime firstTX) async {
    final changeAPIDate = DateTime.now().subtract(Duration(days: 50));
    var url = firstTX.isBefore(changeAPIDate)
        ? 'rainbow?interval=daily'
        : 'pi-cycle-top?interval=hourly&limit=365';

    final response = await _fetchHttp(
      'https://charts.bitcoin.com/api/v1/charts/$url',
    );
    final data = json.decode(response.body);

    List prices = data['data']?['price'] ?? [];
    return prices;
  }
}

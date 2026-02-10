import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '/viewmodels/wallet_viewmodel.dart';
import '/models/currency.dart';
import '/models/transaction_data.dart';
import '/models/price_data.dart';

class Grafico extends StatefulWidget {
  final WalletViewModel viewModel;
  final Function()? onTap;

  const Grafico(this.viewModel, {this.onTap, super.key});

  @override
  GraficoState createState() => GraficoState();
}

class GraficoState extends State<Grafico> {
  late double _minPrice, _maxPrice, _minUsdPrice, _maxUsdPrice;

  List<ScatterSpot> _generateTransactionSpots(WalletViewModel viewModel) {
    final List<ScatterSpot> spots = [];

    for (final transaction in viewModel.transactions) {
      if (transaction.from == Currency.btc || transaction.to == Currency.btc) {
        int closestIndex = -1;
        Duration minDuration = const Duration(days: 999);

        for (int i = 0; i < viewModel.priceHistory.length; i++) {
          final duration = viewModel.priceHistory[i].timestamp
              .difference(transaction.timestamp)
              .abs();
          if (duration < minDuration) {
            minDuration = duration;
            closestIndex = i;
          }
        }

        if (closestIndex != -1) {
          spots.add(
            ScatterSpot(
              closestIndex.toDouble(),
              transaction.price,
              dotPainter: FlDotCirclePainter(
                radius: 6,
                color: transaction.type == TransactionType.buy
                    ? Colors.green
                    : Colors.red,
                strokeColor: Colors.white,
                strokeWidth: 2,
              ),
            ),
          );
        }
      }
    }
    return spots;
  }

  List<FlSpot> _getResultChartSpots(WalletViewModel viewModel) {
    print('+++++++++++++++++++++++++++++=====================');
    double brl = viewModel.transactions[0].amount;
    double usd = 0.0;
    double btc = 0.0;

    double quantoVeioDoCeu = brl;

    int t = 1;
    double minResult = double.maxFinite;
    double maxResult = -double.maxFinite;
    TransactionData transaction = viewModel.transactions[1];
    List<double> results = [];
    for (int i = 0; i < viewModel.priceHistory.length; i++) {
      var pd = viewModel.priceHistory[i];
      while (pd.timestamp.isAfter(transaction.timestamp)) {
        if (transaction.type == TransactionType.buy) {
          if (transaction.from == Currency.heaven &&
              transaction.to == Currency.brl) {
            brl += transaction.amount;
            quantoVeioDoCeu += transaction.amount;
          } else if (transaction.from == Currency.brl &&
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

        if (t >= viewModel.transactions.length - 1) break;
        transaction = viewModel.transactions[++t];
      }

      double result =
          ((brl + (usd * pd.dollarPrice) + (btc * pd.price * pd.dollarPrice)) -
          quantoVeioDoCeu);
      results.add(result);

      if (result > maxResult) maxResult = result;
      if (result < minResult) minResult = result;
    }

    double rangeResult = maxResult - minResult;
    double rangeBtc = _maxPrice - _minPrice;
    double resultBtcRatio = (_minPrice + (rangeBtc / 2)) / rangeResult;

    print('----------=======>>>> RES: ${results.length}');

    final List<FlSpot> spots = [];
    for (int i = 0; i < results.length; i++) {
      double res = results[i] * resultBtcRatio;
      spots.add(FlSpot(i.toDouble(), res));
      print('>>>>> $i > $res');
    }
    return spots;
  }

  List<FlSpot> _getChartSpots(List<PriceData> priceHistory) {
    double i = 0;
    return priceHistory.map((pd) => FlSpot(i++, pd.price)).toList();
  }

  List<FlSpot> _getUsdChartSpots(WalletViewModel viewModel) {
    double range = _maxPrice - _minPrice;
    double usdBtcRatio =
        (_minPrice + (range / 2)) / viewModel.currentUsdBrlPrice;

    final List<FlSpot> spots = [];
    for (int i = 0; i < viewModel.priceHistory.length; i++) {
      double usdOfs = viewModel.priceHistory[i].dollarPrice * usdBtcRatio;
      spots.add(FlSpot(i.toDouble(), usdOfs));
    }

    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final WalletViewModel viewModel = widget.viewModel;
    //final TextTheme textTheme = Theme.of(context).textTheme;

    if (viewModel.priceHistory.isEmpty) {
      return const SizedBox(
        height: 150,
        child: Center(child: Text("Ainda não há dados de preço.")),
      );
    }

    _minPrice = double.maxFinite;
    _maxPrice = -double.maxFinite;
    _minUsdPrice = double.maxFinite;
    _maxUsdPrice = -double.maxFinite;
    for (var p = 0; p < widget.viewModel.priceHistory.length; p++) {
      var price = widget.viewModel.priceHistory[p].price;
      if (price < _minPrice) _minPrice = price;
      if (price > _maxPrice) _maxPrice = price;

      var usdPrice = widget.viewModel.priceHistory[p].dollarPrice;
      if (usdPrice < _minUsdPrice) _minUsdPrice = usdPrice;
      if (usdPrice > _maxUsdPrice) _maxUsdPrice = usdPrice;
    }
    if (_minPrice == _maxPrice) {
      _minPrice = _minPrice - 5;
      _maxPrice = _maxPrice + 5;
    }
    if (_minUsdPrice == _maxUsdPrice) {
      _minUsdPrice = _minUsdPrice - 0.1;
      _maxUsdPrice = _maxUsdPrice + 0.1;
    }

    const styleLegenda = TextStyle(
      color: Colors.black,
      fontSize: 10,
      fontWeight: FontWeight.bold,
    );

    // TODO :: Gráfico do Resultado!
    return AspectRatio(
      aspectRatio: 1.7,
      child: Stack(
        children: [
          LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: const Color(0xff37434d), width: 1),
              ),
              minX: 0,
              maxX: (viewModel.priceHistory.length - 1).toDouble(),
              minY: _minPrice,
              maxY: _maxPrice,
              lineBarsData: [
                LineChartBarData(
                  spots: _getChartSpots(viewModel.priceHistory),
                  isCurved: true,
                  color: Colors.orange,
                  barWidth: 5,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                LineChartBarData(
                  spots: _getUsdChartSpots(viewModel),
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 5,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                ),
                // LineChartBarData(
                //   spots: _getResultChartSpots(viewModel),
                //   isCurved: true,
                //   color: Colors.red,
                //   barWidth: 5,
                //   isStrokeCapRound: true,
                //   dotData: const FlDotData(show: false),
                // ),
              ],
            ),
          ),
          ScatterChart(
            ScatterChartData(
              scatterSpots: _generateTransactionSpots(viewModel),
              minX: 0,
              maxX: (viewModel.priceHistory.length - 1).toDouble(),
              minY: _minPrice,
              maxY: _maxPrice,
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
            ),
          ),
          Positioned(
            left: 8,
            bottom: 8,
            child: Text(CurrencyFormat.usd(_minPrice), style: styleLegenda),
          ),
          Positioned(
            left: 8,
            top: 8,
            child: Text(CurrencyFormat.usd(_maxPrice), style: styleLegenda),
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: Text(CurrencyFormat.brl(_minUsdPrice), style: styleLegenda),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: Text(CurrencyFormat.brl(_maxUsdPrice), style: styleLegenda),
          ),
          if (widget.onTap != null)
            Positioned.fill(
              child: GestureDetector(
                onTap: widget.onTap,
                behavior: HitTestBehavior.translucent,
                child: Container(),
              ),
            ),
        ],
      ),
    );
  }
}

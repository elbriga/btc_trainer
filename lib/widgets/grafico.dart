import 'package:btc_trainer/theme/colors.dart';
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
  late double _minPrice, _maxPrice;
  late double _minUsdPrice, _maxUsdPrice;

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
                    ? AppColors.buy
                    : AppColors.sell,
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

  List<FlSpot> _getChartSpots(List<PriceData> priceHistory) {
    double i = 0;
    return priceHistory.map((pd) => FlSpot(i++, pd.price)).toList();
  }

  List<FlSpot> _getUsdChartSpots(List<PriceData> priceHistory) {
    double i = 0;
    return priceHistory.map((pd) => FlSpot(i++, pd.dollarPrice)).toList();
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
    for (var p = 0; p < viewModel.priceHistory.length; p++) {
      var price = viewModel.priceHistory[p].price;
      if (price < _minPrice) _minPrice = price;
      if (price > _maxPrice) _maxPrice = price;

      var usdPrice = viewModel.priceHistory[p].dollarPrice;
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
                  color: AppColors.primary,
                  barWidth: 5,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
          LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              minX: 0,
              maxX: (viewModel.priceHistory.length - 1).toDouble(),
              minY: _minUsdPrice - 0.25,
              maxY: _maxUsdPrice + 0.25,
              lineBarsData: [
                LineChartBarData(
                  spots: _getUsdChartSpots(viewModel.priceHistory),
                  isCurved: true,
                  color: AppColors.secondary,
                  barWidth: 5,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                ),
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
            child: Text(
              'Min: ${CurrencyFormat.usd(_minPrice)}',
              style: styleLegenda,
            ),
          ),
          Positioned(
            left: 8,
            top: 8,
            child: Text(
              'Máx: ${CurrencyFormat.usd(_maxPrice)}',
              style: styleLegenda,
            ),
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

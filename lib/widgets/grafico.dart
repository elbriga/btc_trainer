import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '/viewmodels/wallet_viewmodel.dart';
import '/models/currency.dart';
import '/models/transaction_data.dart';
import '/models/price_data.dart';
import '/theme/colors.dart';

class Grafico extends StatelessWidget {
  final WalletViewModel viewModel;
  final Function()? onTap;
  late final double _minTS, _maxTS;
  late final double _minPrice, _maxPrice;
  late final double _minUsdPrice, _maxUsdPrice;

  Grafico(this.viewModel, {this.onTap, super.key}) {
    double minPrice, maxPrice, minUsdPrice, maxUsdPrice;
    int minTS, maxTS;

    if (viewModel.priceHistory.isEmpty) {
      minTS = 0;
      maxTS = 0;
      minPrice = 0;
      maxPrice = 0;
      minUsdPrice = 0;
      maxUsdPrice = 0;
    } else {
      minTS = -1 >>> 1; // int max
      maxTS = 0;
      minPrice = double.maxFinite;
      maxPrice = -double.maxFinite;
      minUsdPrice = double.maxFinite;
      maxUsdPrice = -double.maxFinite;
      for (var p = 0; p < viewModel.priceHistory.length; p++) {
        var ts = viewModel.priceHistory[p].timestamp.millisecondsSinceEpoch;
        if (ts < minTS) minTS = ts;
        if (ts > maxTS) maxTS = ts;

        var price = viewModel.priceHistory[p].price;
        if (price < minPrice) minPrice = price;
        if (price > maxPrice) maxPrice = price;

        var usdPrice = viewModel.priceHistory[p].dollarPrice;
        if (usdPrice < minUsdPrice) minUsdPrice = usdPrice;
        if (usdPrice > maxUsdPrice) maxUsdPrice = usdPrice;
      }
      if (minPrice == maxPrice) {
        minPrice = minPrice - 5;
        maxPrice = maxPrice + 5;
      }
      if (minUsdPrice == maxUsdPrice) {
        minUsdPrice = minUsdPrice - 0.1;
        maxUsdPrice = maxUsdPrice + 0.1;
      }
    }

    _minTS = minTS.toDouble();
    _maxTS = maxTS.toDouble();
    _minPrice = minPrice;
    _maxPrice = maxPrice;
    _minUsdPrice = minUsdPrice;
    _maxUsdPrice = maxUsdPrice;
  }

  List<ScatterSpot> _generateTransactionSpots(WalletViewModel viewModel) {
    final List<ScatterSpot> spots = [];

    for (final transaction in viewModel.transactions) {
      if (transaction.from != Currency.btc && transaction.to != Currency.btc) {
        continue;
      }

      int closestIndex = -1;
      Duration minDuration = const Duration(days: 99999);
      for (int i = 0; i < viewModel.priceHistory.length; i++) {
        final duration = viewModel.priceHistory[i].timestamp
            .difference(transaction.timestamp)
            .abs();
        if (duration < minDuration) {
          minDuration = duration;
          closestIndex =
              viewModel.priceHistory[i].timestamp.millisecondsSinceEpoch;
        }
      }
      if (closestIndex == -1) {
        continue;
      }

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
    return spots;
  }

  List<FlSpot> _getChartSpots(List<PriceData> priceHistory) {
    return priceHistory
        .map(
          (pd) =>
              FlSpot(pd.timestamp.millisecondsSinceEpoch.toDouble(), pd.price),
        )
        .toList();
  }

  List<FlSpot> _getUsdChartSpots(List<PriceData> priceHistory) {
    return priceHistory
        .map(
          (pd) => FlSpot(
            pd.timestamp.millisecondsSinceEpoch.toDouble(),
            pd.dollarPrice,
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    //final TextTheme textTheme = Theme.of(context).textTheme;

    if (viewModel.priceHistory.isEmpty) {
      return const SizedBox(
        height: 150,
        child: Center(child: Text("Ainda não há dados de preço.")),
      );
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
              minX: _minTS,
              maxX: _maxTS,
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
              minX: _minTS,
              maxX: _maxTS,
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
              minX: _minTS,
              maxX: _maxTS,
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
          if (onTap != null)
            Positioned.fill(
              child: GestureDetector(
                onTap: onTap,
                behavior: HitTestBehavior.translucent,
                child: Container(),
              ),
            ),
        ],
      ),
    );
  }
}

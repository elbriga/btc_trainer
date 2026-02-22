import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

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

  Grafico(this.viewModel, {this.onTap, super.key}) {
    double minPrice, maxPrice;
    int minTS, maxTS;

    if (viewModel.priceHistory.isEmpty) {
      minTS = 0;
      maxTS = 0;
      minPrice = 0;
      maxPrice = 0;
    } else {
      minTS = -1 >>> 1; // int max
      maxTS = 0;
      minPrice = double.maxFinite;
      maxPrice = -double.maxFinite;
      for (var p = 0; p < viewModel.priceHistory.length; p++) {
        var ts = viewModel.priceHistory[p].timestamp.millisecondsSinceEpoch;
        if (ts < minTS) minTS = ts;
        if (ts > maxTS) maxTS = ts;

        var price = viewModel.priceHistory[p].price;
        if (price < minPrice) minPrice = price;
        if (price > maxPrice) maxPrice = price;
      }
      if (minPrice == maxPrice) {
        minPrice = minPrice - 5;
        maxPrice = maxPrice + 5;
      }
    }

    _minTS = minTS.toDouble();
    _maxTS = DateTime.now().millisecondsSinceEpoch
        .toDouble(); // maxTS.toDouble();
    _minPrice = minPrice;
    _maxPrice = maxPrice;
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
            radius: 3,
            color: transaction.type == TransactionType.buy
                ? AppColors.buy
                : AppColors.sell,
            strokeColor: Colors.black,
            strokeWidth: 2,
          ),
        ),
      );
    }
    return spots;
  }

  List<FlSpot> _getMonthSpots(List<PriceData> priceHistory) {
    return priceHistory
        .map(
          (pd) => FlSpot(
            pd.timestamp.millisecondsSinceEpoch.toDouble(),
            pd.timestamp.month % 2,
          ),
        )
        .toList();
  }

  List<FlSpot> _getChartSpots(List<PriceData> priceHistory) {
    return priceHistory
        .map(
          (pd) =>
              FlSpot(pd.timestamp.millisecondsSinceEpoch.toDouble(), pd.price),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final paddingDelta = (_maxPrice - _minPrice) / 10;
    //final TextTheme textTheme = Theme.of(context).textTheme;

    if (viewModel.priceHistory.isEmpty) {
      return const SizedBox(
        height: 150,
        child: Center(child: Text("Ainda não há dados de preço.")),
      );
    }

    final firstDate = DateFormat(
      'dd/MM/yyyy',
    ).format(viewModel.priceHistory.first.timestamp);

    const styleLegenda = TextStyle(
      color: Colors.black,
      fontSize: 10,
      fontWeight: FontWeight.bold,
    );

    return AspectRatio(
      aspectRatio: 2.2,
      child: Stack(
        children: [
          LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              minX: _minTS,
              maxX: _maxTS,
              minY: 0,
              maxY: 1,
              lineBarsData: [
                LineChartBarData(
                  spots: _getMonthSpots(viewModel.priceHistory),
                  color: AppColors.textSecondary.withAlpha(100),
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          ),
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
              minY: _minPrice - paddingDelta,
              maxY: _maxPrice + paddingDelta,
              lineBarsData: [
                LineChartBarData(
                  spots: _getChartSpots(viewModel.priceHistory),
                  color: AppColors.primary,
                  barWidth: 3,
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
          ScatterChart(
            ScatterChartData(
              scatterSpots: _generateTransactionSpots(viewModel),
              minX: _minTS,
              maxX: _maxTS,
              minY: _minPrice - paddingDelta,
              maxY: _maxPrice + paddingDelta,
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
            ),
          ),
          Positioned(
            left: 8,
            bottom: 44,
            child: Text('Início: $firstDate', style: styleLegenda),
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

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '/viewmodels/wallet_viewmodel.dart';
import '/models/currency.dart';
import '/models/transaction_data.dart';
import '/models/price_data.dart';

class Grafico extends StatefulWidget {
  final WalletViewModel viewModel;

  const Grafico(this.viewModel, {super.key});

  @override
  GraficoState createState() => GraficoState();
}

class GraficoState extends State<Grafico> {
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

  List<FlSpot> _getChartSpots(List<PriceData> priceHistory) {
    final List<FlSpot> spots = [];
    for (int i = 0; i < priceHistory.length; i++) {
      spots.add(FlSpot(i.toDouble(), priceHistory[i].price));
    }
    return spots;
  }

  List<FlSpot> _getUsdChartSpots(WalletViewModel viewModel) {
    double minPrice = viewModel.priceHistory
        .map((e) => e.price)
        .reduce((a, b) => a < b ? a : b);
    double maxPrice = viewModel.priceHistory
        .map((e) => e.price)
        .reduce((a, b) => a > b ? a : b);

    if (minPrice == maxPrice) {
      minPrice = minPrice - 5;
      maxPrice = maxPrice + 5;
    }

    double range = maxPrice - minPrice;
    double usdBtcRatio =
        (minPrice + (range / 2)) / viewModel.currentUsdBrlPrice;

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

    double minPrice = viewModel.priceHistory
        .map((e) => e.price)
        .reduce((a, b) => a < b ? a : b);
    double maxPrice = viewModel.priceHistory
        .map((e) => e.price)
        .reduce((a, b) => a > b ? a : b);

    if (minPrice == maxPrice) {
      minPrice = minPrice - 5;
      maxPrice = maxPrice + 5;
    }

    double minUsdPrice = viewModel.priceHistory
        .map((e) => e.dollarPrice)
        .reduce((a, b) => a < b ? a : b);
    double maxUsdPrice = viewModel.priceHistory
        .map((e) => e.dollarPrice)
        .reduce((a, b) => a > b ? a : b);

    if (minUsdPrice == maxUsdPrice) {
      minUsdPrice = minUsdPrice - 0.1;
      maxUsdPrice = maxUsdPrice + 0.1;
    }

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
              minY: minPrice,
              maxY: maxPrice,
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
              ],
            ),
          ),
          ScatterChart(
            ScatterChartData(
              scatterSpots: _generateTransactionSpots(viewModel),
              minX: 0,
              maxX: (viewModel.priceHistory.length - 1).toDouble(),
              minY: minPrice,
              maxY: maxPrice,
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
            ),
          ),
          Positioned(
            left: 8,
            bottom: 8,
            child: Text(
              '\$${minPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Positioned(
            left: 8,
            top: 8,
            child: Text(
              '\$${maxPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: Text(
              'R\$${minUsdPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: Text(
              'R\$${maxUsdPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

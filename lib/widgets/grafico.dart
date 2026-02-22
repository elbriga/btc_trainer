import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '/viewmodels/wallet_viewmodel.dart';
import '/models/currency.dart';
import '/models/transaction_data.dart';
import '/models/price_data.dart';
import '/theme/colors.dart';

class Grafico extends StatefulWidget {
  final WalletViewModel viewModel;

  const Grafico(this.viewModel, {super.key});

  @override
  State<Grafico> createState() => _GraficoState();
}

class _GraficoState extends State<Grafico> {
  bool _is24h = false;

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

  void _toggle24h() {
    setState(() {
      _is24h = !_is24h;
    });
  }

  @override
  Widget build(BuildContext context) {
    DateTime? first;
    if (_is24h) {
      first = DateTime.now().subtract(const Duration(hours: 24));
    } else {
      for (var t in widget.viewModel.transactions) {
        if (t.to == Currency.btc) {
          first = t.timestamp;
          break;
        }
      }
      first ??= DateTime.now().subtract(const Duration(days: 3));
    }
    final minTS = first.millisecondsSinceEpoch.toDouble();
    final maxTS = DateTime.now().millisecondsSinceEpoch.toDouble();

    double minPrice = 0, maxPrice = 0;
    if (widget.viewModel.priceHistory.isNotEmpty) {
      minPrice = double.maxFinite;
      for (var pd in widget.viewModel.priceHistory) {
        if (pd.timestamp.isBefore(first)) {
          continue;
        }

        if (pd.price < minPrice) minPrice = pd.price;
        if (pd.price > maxPrice) maxPrice = pd.price;
      }
      if (minPrice == maxPrice) {
        minPrice = minPrice - 5;
        maxPrice = maxPrice + 5;
      }
    }

    final paddingDelta = (maxPrice - minPrice) / 10;
    //final TextTheme textTheme = Theme.of(context).textTheme;

    if (widget.viewModel.priceHistory.isEmpty) {
      return const SizedBox(
        height: 150,
        child: Center(child: Text("Ainda não há dados de preço.")),
      );
    }

    final firstDate = DateFormat(
      'dd/MM/yyyy',
    ).format(widget.viewModel.priceHistory.first.timestamp);

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
              minX: minTS,
              maxX: maxTS,
              minY: 0,
              maxY: 1,
              lineBarsData: [
                LineChartBarData(
                  spots: _getMonthSpots(widget.viewModel.priceHistory),
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
              minX: minTS,
              maxX: maxTS,
              minY: minPrice - paddingDelta,
              maxY: maxPrice + paddingDelta,
              lineBarsData: [
                LineChartBarData(
                  spots: _getChartSpots(widget.viewModel.priceHistory),
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
              scatterSpots: _generateTransactionSpots(widget.viewModel),
              minX: minTS,
              maxX: maxTS,
              minY: minPrice - paddingDelta,
              maxY: maxPrice + paddingDelta,
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
              'Min: ${CurrencyFormat.usd(minPrice)}',
              style: styleLegenda,
            ),
          ),
          Positioned(
            left: 8,
            top: 8,
            child: Text(
              'Máx: ${CurrencyFormat.usd(maxPrice)}',
              style: styleLegenda,
            ),
          ),
          if (_is24h)
            Positioned(
              right: 8,
              top: 8,
              child: Text('Últimas 24h', style: styleLegenda),
            ),
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggle24h,
              behavior: HitTestBehavior.translucent,
              child: Container(),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../viewmodels/wallet_viewmodel.dart';
import '../models/price_data.dart';
import '../widgets/buy_sell_dialog.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BTC Trainer'),
        centerTitle: true,
        backgroundColor: Colors.orangeAccent,
      ),
      body: Consumer<WalletViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (viewModel.errorMessage != null) {
            return Center(child: Text('Error: ${viewModel.errorMessage}'));
          }
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildBalanceDisplay(context, viewModel),
                const SizedBox(height: 24),
                _buildChart(context, viewModel),
                const SizedBox(height: 24),
                _buildActionButtons(context, viewModel),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalanceDisplay(BuildContext context, WalletViewModel viewModel) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Live BTC Price: \$${viewModel.currentBtcPrice.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBalanceItem(context, 'USD Balance', '\$${viewModel.usdBalance.toStringAsFixed(2)}'),
                _buildBalanceItem(context, 'BTC Balance', '${viewModel.btcBalance.toStringAsFixed(8)} BTC'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceItem(BuildContext context, String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.bodySmall),
        Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildChart(BuildContext context, WalletViewModel viewModel) {
    return AspectRatio(
      aspectRatio: 1.7,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: true, border: Border.all(color: const Color(0xff37434d), width: 1)),
          minX: 0,
          maxX: (viewModel.priceHistory.length - 1).toDouble(),
          minY: viewModel.priceHistory.map((e) => e.price).reduce((a, b) => a < b ? a : b) * 0.95,
          maxY: viewModel.priceHistory.map((e) => e.price).reduce((a, b) => a > b ? a : b) * 1.05,
          lineBarsData: [
            LineChartBarData(
              spots: _getChartSpots(viewModel.priceHistory),
              isCurved: true,
              color: Colors.orange,
              barWidth: 5,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: Colors.orange.withOpacity(0.3)),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _getChartSpots(List<PriceData> priceHistory) {
    final List<FlSpot> spots = [];
    for (int i = 0; i < priceHistory.length; i++) {
      spots.add(FlSpot(i.toDouble(), priceHistory[i].price));
    }
    return spots;
  }

  Widget _buildActionButtons(BuildContext context, WalletViewModel viewModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.arrow_upward),
          label: const Text('Buy'),
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => BuySellDialog(
                isBuy: true,
                onSubmit: (amount) => viewModel.buyBtc(amount),
                balance: viewModel.usdBalance,
                btcPrice: viewModel.currentBtcPrice,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          ),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.arrow_downward),
          label: const Text('Sell'),
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => BuySellDialog(
                isBuy: false,
                onSubmit: (amount) => viewModel.sellBtc(amount),
                balance: viewModel.btcBalance,
                btcPrice: viewModel.currentBtcPrice,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          ),
        ),
      ],
    );
  }
}

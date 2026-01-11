import 'package:btc_trainer/models/currency.dart';
import 'package:btc_trainer/widgets/buy_sell_usd_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import '../viewmodels/wallet_viewmodel.dart';
import '../models/price_data.dart';
import '../models/transaction_data.dart';
import '../widgets/buy_sell_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _brlBalanceTapCount = 0;
  DateTime? _lastBrlBalanceTap;

  @override
  void initState() {
    super.initState();
    _startBackgroundService();
  }

  void _startBackgroundService() async {
    final service = FlutterBackgroundService();
    var isRunning = await service.isRunning();
    if (!isRunning) {
      service.startService();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulador de BTC'),
        centerTitle: true,
        backgroundColor: Colors.orangeAccent,
      ),
      body: Consumer<WalletViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (viewModel.errorMessage != null) {
            return Center(child: Text('Erro: ${viewModel.errorMessage}'));
          }
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildBalanceDisplay(context, viewModel),
                const SizedBox(height: 24),
                _buildChart(context, viewModel),
                const SizedBox(height: 24),
                _buildTransactionHistory(context, viewModel),
                const SizedBox(height: 12),
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
              'Preço do BTC: \$${viewModel.currentBtcPrice.toStringAsFixed(2)}',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Preço do USD: R\$${viewModel.currentUsdBrlPrice.toStringAsFixed(2)}',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    final now = DateTime.now();
                    if (_lastBrlBalanceTap != null &&
                        now.difference(_lastBrlBalanceTap!) <
                            const Duration(seconds: 1)) {
                      _brlBalanceTapCount++;
                    } else {
                      _brlBalanceTapCount = 1;
                    }
                    _lastBrlBalanceTap = now;

                    if (_brlBalanceTapCount >= 7) {
                      viewModel.topUpBrlBalance();
                      _brlBalanceTapCount = 0;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Saldo BRL recarregado para R\$50,000.00!',
                          ),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: _buildBalanceItem(
                    context,
                    'Saldo em BRL',
                    'R\$${viewModel.brlBalance.toStringAsFixed(2)}',
                  ),
                ),
                _buildBalanceItem(
                  context,
                  'Saldo em USD',
                  '\$${viewModel.usdBalance.toStringAsFixed(2)}',
                  brlEquivalent:
                      (viewModel.usdBalance * viewModel.currentUsdBrlPrice),
                ),
                _buildBalanceItem(
                  context,
                  'Saldo em BTC',
                  '${viewModel.btcBalance.toStringAsFixed(8)} BTC',
                  usdEquivalent:
                      (viewModel.btcBalance * viewModel.currentBtcPrice),
                  brlEquivalent:
                      (viewModel.btcBalance * viewModel.currentBtcPrice) *
                      viewModel.currentUsdBrlPrice,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceItem(
    BuildContext context,
    String title,
    String value, {
    double? usdEquivalent,
    double? brlEquivalent,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.bodySmall),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (usdEquivalent != null && usdEquivalent > 0)
          Text(
            '(\$ ${usdEquivalent.toStringAsFixed(2)})',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
          ),
        if (brlEquivalent != null && brlEquivalent > 0)
          Text(
            '(R\$ ${brlEquivalent.toStringAsFixed(2)})',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
          ),
      ],
    );
  }

  Widget _buildChart(BuildContext context, WalletViewModel viewModel) {
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

    double dollarOffset = minPrice + ((maxPrice - minPrice) / 2);

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
                    color: Colors.orange.withOpacity(0.3),
                  ),
                ),
                LineChartBarData(
                  spots: _getUsdChartSpots(
                    viewModel.priceHistory,
                    dollarOffset,
                  ),
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

  List<FlSpot> _getUsdChartSpots(List<PriceData> priceHistory, double offSet) {
    final List<FlSpot> spots = [];
    for (int i = 0; i < priceHistory.length; i++) {
      double usdOfs = priceHistory[i].dollarPrice * 15;
      usdOfs = (usdOfs - (usdOfs / 2)) + offSet;
      spots.add(FlSpot(i.toDouble(), usdOfs));
    }
    return spots;
  }

  Widget _buildTransactionHistory(
    BuildContext context,
    WalletViewModel viewModel,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Histórico de Transações',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: viewModel.transactions.isEmpty
                ? const Center(child: Text('Nenhuma transação ainda.'))
                : ListView.builder(
                    itemCount: viewModel.transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = viewModel.transactions[index];
                      final isBuy = transaction.type == TransactionType.buy;
                      final String currencySymbol;
                      final String totalCurrencySymbol;
                      int decimal = 8;
                      if (transaction.to == Currency.btc) {
                        currencySymbol = 'BTC';
                        totalCurrencySymbol = '\$';
                      } else if (transaction.to == Currency.usd) {
                        currencySymbol = 'USD';
                        totalCurrencySymbol = '\$';
                        decimal = 2;
                      } else {
                        currencySymbol = 'BRL';
                        totalCurrencySymbol = 'R\$';
                        decimal = 2;
                      }
                      final title =
                          '${transaction.from == Currency.heaven
                              ? 'Ganhou'
                              : isBuy
                              ? 'Comprou'
                              : 'Vendeu'} ${transaction.amount.toStringAsFixed(decimal)} $currencySymbol';
                      final subtitle =
                          '@ $totalCurrencySymbol${transaction.price.toStringAsFixed(2)} / cada\n${DateFormat.yMd().add_jms().format(transaction.timestamp)}';
                      final total =
                          'Total: $totalCurrencySymbol${(transaction.amount * transaction.price).toStringAsFixed(2)}';

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: Icon(
                            transaction.from == Currency.heaven
                                ? Icons.cloud
                                : isBuy
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: isBuy ? Colors.green : Colors.red,
                          ),
                          title: Text(title),
                          subtitle: Text(subtitle),
                          trailing: Text(total),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WalletViewModel viewModel) {
    bool btcBuyEnable =
        viewModel.currentBtcPrice > 0 && viewModel.usdBalance > 0;
    bool btcSellEnable =
        viewModel.currentBtcPrice > 0 && viewModel.btcBalance > 0;
    bool usdBuyEnable =
        viewModel.currentUsdBrlPrice > 0 && viewModel.brlBalance > 0;
    bool usdSellEnable =
        viewModel.currentUsdBrlPrice > 0 && viewModel.usdBalance > 0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.arrow_upward),
              label: const Text('USD'),
              onPressed: () {
                if (!usdBuyEnable) return;
                showDialog(
                  context: context,
                  builder: (_) => BuySellUsdDialog(
                    isBuy: true,
                    onSubmit: (amount) => viewModel.buyUsd(amount),
                    balance: viewModel.brlBalance,
                    usdBrlPrice: viewModel.currentUsdBrlPrice,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: usdBuyEnable ? Colors.green : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 15,
                ),
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.arrow_downward),
              label: const Text('USD'),
              onPressed: () {
                if (!usdSellEnable) return;
                showDialog(
                  context: context,
                  builder: (_) => BuySellUsdDialog(
                    isBuy: false,
                    onSubmit: (amount) => viewModel.sellUsd(amount),
                    balance: viewModel.usdBalance,
                    usdBrlPrice: viewModel.currentUsdBrlPrice,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: usdSellEnable ? Colors.red : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 15,
                ),
              ),
            ),

            ElevatedButton.icon(
              icon: const Icon(Icons.arrow_upward),
              label: const Text('BTC'),
              onPressed: () {
                if (!btcBuyEnable) return;
                showDialog(
                  context: context,
                  builder: (_) => BuySellDialog(
                    isBuy: true,
                    onSubmit: (amount) => viewModel.buyBtc(amount),
                    balance: viewModel.usdBalance,
                    price: viewModel.currentBtcPrice,
                    from: Currency.usd,
                    to: Currency.btc,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: btcBuyEnable ? Colors.green : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 15,
                ),
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.arrow_downward),
              label: const Text('BTC'),
              onPressed: () {
                if (!btcSellEnable) return;
                showDialog(
                  context: context,
                  builder: (_) => BuySellDialog(
                    isBuy: false,
                    onSubmit: (amount) => viewModel.sellBtc(amount),
                    balance: viewModel.btcBalance,
                    price: viewModel.currentBtcPrice,
                    from: Currency.btc,
                    to: Currency.usd,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: btcSellEnable ? Colors.red : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 15,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

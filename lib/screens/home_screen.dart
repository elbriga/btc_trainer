import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/services/firebase_helper.dart';
import '/viewmodels/wallet_viewmodel.dart';
import '/widgets/online_display.dart';
import '/widgets/balance_display.dart';
import '/widgets/grafico.dart';
import '/widgets/transaction_list.dart';
import '/widgets/buy_sell_dialog.dart';
import '/widgets/buy_sell_usd_dialog.dart';
import '/models/currency.dart';
import '/screens/transaction_history_screen.dart';
import '/screens/settings_screen.dart';
import '/screens/graph_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(minutes: 1), (timer) {
      FirebaseHelper.instance.getLastPrices();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _gotoScreen(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulador de Bitcoin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Configurações',
            onPressed: () => _gotoScreen(SettingsScreen()),
          ),
        ],
        centerTitle: true,
        backgroundColor: Colors.orangeAccent,
      ),
      body: Consumer<WalletViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(
                top: 2,
                left: 6,
                right: 6,
                bottom: 4,
              ),
              child: Column(
                spacing: 10,
                children: [
                  OnlineDisplay(viewModel),
                  Grafico(
                    viewModel,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GraphScreen(viewModel),
                        ),
                      );
                    },
                  ),
                  BalanceDisplay(viewModel),
                  _buildActionButtons(context, viewModel),
                  SizedBox(
                    height: 500.0,
                    child: _buildTransactionHistory(context, viewModel),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionHistory(
    BuildContext context,
    WalletViewModel viewModel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    TransactionHistoryScreen(viewModel.transactions),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Histórico de Transações',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Icon(Icons.arrow_forward_ios, size: 18),
              ],
            ),
          ),
        ),
        Expanded(child: TransactionList(viewModel.transactions)),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, WalletViewModel viewModel) {
    if (!viewModel.isPriceUpdated()) {
      return Center(
        child: Row(
          spacing: 15,
          children: [
            Expanded(child: Text('Buscando Cotações...')),
            CircularProgressIndicator(),
          ],
        ),
      );
    }

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

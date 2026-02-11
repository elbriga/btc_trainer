import 'package:flutter/material.dart';

import '/theme/colors.dart';
import '/models/currency.dart';
import '/viewmodels/wallet_viewmodel.dart';

class OnlineDisplay extends StatelessWidget {
  final WalletViewModel viewModel;

  const OnlineDisplay(this.viewModel, {super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    final priceBtcBrl = double.tryParse(
      (viewModel.currentBtcPrice * viewModel.currentUsdBrlPrice)
          .toStringAsFixed(2),
    );

    double quantoVeioDoCeu = viewModel.transactions
        .map((t) => (t.from == Currency.heaven) ? t.amount : 0.0)
        .reduce((a, b) => a + b);

    double result =
        double.tryParse(
          ((viewModel.brlBalance +
                      (viewModel.usdBalance * viewModel.currentUsdBrlPrice) +
                      (viewModel.btcBalance * priceBtcBrl!)) -
                  quantoVeioDoCeu)
              .toStringAsFixed(2),
        ) ??
        0.0;

    Column buildVarBox(String title, double amount) {
      return Column(
        children: [
          Text(title, style: textTheme.displaySmall),
          Text(
            '${amount > 0 ? '+' : ''}${amount.toStringAsFixed(2)}%',
            style: (amount > 0.0)
                ? textTheme.bodyLarge?.copyWith(color: Colors.green)
                : textTheme.bodyLarge?.copyWith(color: Colors.red),
          ),
        ],
      );
    }

    return Card(
      elevation: 4,
      color: AppColors.bgPrices,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          spacing: 8,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Text('Resultado'),
                    Text(
                      CurrencyFormat.brl(result),
                      style: (result > 0.0)
                          ? textTheme.bodyLarge
                          : textTheme.headlineLarge,
                    ),
                  ],
                ),

                buildVarBox(
                  'var 60 min',
                  viewModel.getTrend(const Duration(hours: 1)),
                ),

                buildVarBox(
                  'var 24h',
                  viewModel.getTrend(const Duration(hours: 24)),
                ),
              ],
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Text('Preço do BTC', style: textTheme.displaySmall),
                    Text(
                      CurrencyFormat.usd(viewModel.currentBtcPrice),
                      style: textTheme.displayLarge,
                    ),
                    Text(
                      '(${CurrencyFormat.brl(priceBtcBrl)})',
                      style: textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),

                Column(
                  children: [
                    Text('Preço do USD', style: textTheme.displaySmall),
                    Text(
                      CurrencyFormat.brl(viewModel.currentUsdBrlPrice),
                      style: textTheme.displayMedium,
                    ),
                  ],
                ),

                buildVarBox(
                  'var 7 dias',
                  viewModel.getTrend(const Duration(days: 7)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

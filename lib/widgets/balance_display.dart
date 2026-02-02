import 'package:flutter/material.dart';

import '/viewmodels/wallet_viewmodel.dart';
import '/models/currency.dart';

class BalanceDisplay extends StatefulWidget {
  final WalletViewModel viewModel;

  const BalanceDisplay(this.viewModel, {super.key});

  @override
  BalanceDisplayState createState() => BalanceDisplayState();
}

class BalanceDisplayState extends State<BalanceDisplay> {
  Widget _buildBalanceItem(
    BuildContext context,
    String title,
    String value, {
    double? usdEquivalent,
    double? brlEquivalent,
  }) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: textTheme.bodySmall),
        Text(value, style: textTheme.bodyMedium),
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

  @override
  Widget build(BuildContext context) {
    final WalletViewModel viewModel = widget.viewModel;
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

    var magicCloud = GestureDetector(
      onDoubleTap: () {
        viewModel.topUpBrlBalance();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ganhou mais R\$50,000.00 do céu!'),
            duration: Duration(seconds: 3),
          ),
        );
      },
      child: Icon(Icons.cloud),
    );

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Preço do BTC: \$${viewModel.currentBtcPrice.toStringAsFixed(2)}',
              style: textTheme.displayLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Preço em BRL: R\$ ${priceBtcBrl.toStringAsFixed(2)}',
              style: textTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Preço do USD: R\$ ${viewModel.currentUsdBrlPrice.toStringAsFixed(2)}',
              style: textTheme.displayMedium,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBalanceItem(
                  context,
                  'Saldo em BRL',
                  'R\$${viewModel.brlBalance.toStringAsFixed(2)}',
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
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Text('Resultado'),
                    Text(
                      'R\$ ${result.toStringAsFixed(2)}',
                      style: (result > 0.0)
                          ? textTheme.bodyLarge
                          : textTheme.headlineLarge,
                    ),
                  ],
                ),
                Column(
                  children: [
                    magicCloud,
                    Text('R\$ ${quantoVeioDoCeu.toStringAsFixed(2)}'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

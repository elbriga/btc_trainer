import 'package:flutter/material.dart';

import '/theme/colors.dart';
import '/models/currency.dart';
import '/viewmodels/wallet_viewmodel.dart';

class BalanceDisplay extends StatelessWidget {
  final WalletViewModel viewModel;

  const BalanceDisplay(this.viewModel, {super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    double precoMedio = viewModel.getAverageBtcPrice();

    var magicCloud = GestureDetector(
      onTap: () async {
        final bool? confirm = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirmar Recarga'),
              content: const Text(
                'Deseja realmente adicionar R\$50.000,00 à sua carteira?',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false); // User canceled
                  },
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true); // User confirmed
                  },
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        );

        if (confirm == true) {
          var amount = await viewModel.getHeavenIntervention();

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Ganhou mais ${CurrencyFormat.brl(amount)} do céu!',
                ),
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      },
      child: Column(
        children: [
          Icon(Icons.cloud),
          Text(CurrencyFormat.brl(viewModel.quantoVeioDoCeu)),
        ],
      ),
    );

    var cardResultado = Card(
      elevation: 4,
      color: AppColors.bgResult,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                Text('Meu Preço Médio', style: textTheme.displaySmall),
                Text(
                  CurrencyFormat.usd(precoMedio),
                  style: textTheme.displayMedium,
                ),
              ],
            ),
            magicCloud,
          ],
        ),
      ),
    );

    var cardSaldo = Card(
      elevation: 4,
      color: AppColors.bgBalance,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildBalanceItem(
              context,
              'Saldo em BRL',
              CurrencyFormat.brl(viewModel.brlBalance),
            ),
            _buildBalanceItem(
              context,
              'Saldo em USD',
              CurrencyFormat.usd(viewModel.usdBalance),
              brlEquivalent:
                  (viewModel.usdBalance * viewModel.currentUsdBrlPrice),
            ),
            _buildBalanceItem(
              context,
              'Saldo em BTC',
              CurrencyFormat.btc(viewModel.btcBalance),
              usdEquivalent: (viewModel.btcBalance * viewModel.currentBtcPrice),
              brlEquivalent:
                  (viewModel.btcBalance * viewModel.currentBtcPrice) *
                  viewModel.currentUsdBrlPrice,
            ),
          ],
        ),
      ),
    );

    return Column(spacing: 1, children: [cardResultado, cardSaldo]);
  }

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
            '(${CurrencyFormat.usd(usdEquivalent)})',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
          ),
        if (brlEquivalent != null && brlEquivalent > 0)
          Text(
            '(${CurrencyFormat.brl(brlEquivalent)})',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '/theme/colors.dart';
import '/models/currency.dart';
import '/viewmodels/wallet_viewmodel.dart';

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

    double tendenciaHora = viewModel.getTrend(const Duration(hours: 1));
    double tendenciaDia = viewModel.getTrend(const Duration(hours: 24));
    double tendenciaSemana = viewModel.getTrend(const Duration(days: 7));

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
          Text(CurrencyFormat.brl(quantoVeioDoCeu)),
        ],
      ),
    );

    var cardPrecos = Card(
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
                    Text('Trend Hora', style: textTheme.displaySmall),
                    Text(
                      '${tendenciaHora > 0 ? '+' : ''}${tendenciaHora.toStringAsFixed(2)}%',
                      style: (tendenciaHora > 0.0)
                          ? textTheme.bodyLarge?.copyWith(color: Colors.green)
                          : textTheme.bodyLarge?.copyWith(color: Colors.red),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text('Trend 24h', style: textTheme.displaySmall),
                    Text(
                      '${tendenciaDia > 0 ? '+' : ''}${tendenciaDia.toStringAsFixed(2)}%',
                      style: (tendenciaDia > 0.0)
                          ? textTheme.bodyLarge?.copyWith(color: Colors.green)
                          : textTheme.bodyLarge?.copyWith(color: Colors.red),
                    ),
                  ],
                ),
              ],
            ),

            Row(
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

                Column(
                  children: [
                    Text('Trend 7 dias', style: textTheme.displaySmall),
                    Text(
                      '${tendenciaSemana > 0 ? '+' : ''}${tendenciaSemana.toStringAsFixed(2)}%',
                      style: (tendenciaSemana > 0.0)
                          ? textTheme.bodyLarge?.copyWith(color: Colors.green)
                          : textTheme.bodyLarge?.copyWith(color: Colors.red),
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
              ],
            ),
          ],
        ),
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
                Text('Resultado'),
                Text(
                  CurrencyFormat.brl(result),
                  style: (result > 0.0)
                      ? textTheme.bodyLarge
                      : textTheme.headlineLarge,
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

    return Column(spacing: 1, children: [cardPrecos, cardResultado, cardSaldo]);
  }
}

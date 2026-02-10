import 'package:flutter/material.dart';

import '/viewmodels/wallet_viewmodel.dart';
import '/widgets/grafico.dart';
import '/theme/colors.dart';

class GraphScreen extends StatelessWidget {
  final WalletViewModel viewModel;

  const GraphScreen(this.viewModel, {super.key});

  Widget _leg(Color cor, String nome) {
    return Row(
      spacing: 10,
      children: [
        Container(width: 20, height: 20, color: cor),
        Text(nome),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico'),
        centerTitle: true,
        backgroundColor: Colors.orangeAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          spacing: 10,
          children: [
            Grafico(viewModel),
            SizedBox(
              width: 200,
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 10,
                    children: [
                      _leg(AppColors.primary, 'Bitcoin'),
                      _leg(AppColors.secondary, 'US Dólar'),
                      _leg(AppColors.buy, 'Comprou BTC'),
                      _leg(AppColors.sell, 'Vendeu BTC'),
                    ],
                  ),
                ),
              ),
            ),
            //ElevatedButton(onPressed: () {}, child: Text('Voltar')),
          ],
        ),
      ),
    );
  }
}

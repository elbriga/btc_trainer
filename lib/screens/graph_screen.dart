import 'package:flutter/material.dart';

import '/viewmodels/wallet_viewmodel.dart';
import '/widgets/grafico.dart';
import '/widgets/grafico_pi_cycle.dart';
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
    final legenda1 = SizedBox(
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
    );
    final legenda2 = SizedBox(
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
              _leg(AppColors.secondary, '111 day MA'),
              _leg(AppColors.buy, '365 day MA x 2'),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico'),
        centerTitle: true,
        backgroundColor: Colors.orangeAccent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            spacing: 10,
            children: [
              Grafico(viewModel),
              legenda1,
              SizedBox(height: 12),
              Text('Pi Cycle Top Indicator'),
              GraficoPiCycle(),
              legenda2,
            ],
          ),
        ),
      ),
    );
  }
}

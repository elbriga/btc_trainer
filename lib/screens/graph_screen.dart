import 'package:flutter/material.dart';

import '/viewmodels/wallet_viewmodel.dart';
import '/widgets/grafico.dart';

class GraphScreen extends StatelessWidget {
  final WalletViewModel viewModel;

  const GraphScreen(this.viewModel, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico'),
        centerTitle: true,
        backgroundColor: Colors.orangeAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Column(
          spacing: 10,
          children: [
            Grafico(viewModel),
            Card(elevation: 4, child: Text('Legenda')),
          ],
        ),
      ),
    );
  }
}

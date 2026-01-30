import 'package:btc_trainer/widgets/transaction_list.dart';
import 'package:flutter/material.dart';

import '/models/transaction_data.dart';

class TransactionHistoryScreen extends StatelessWidget {
  final List<TransactionData> transactions;

  const TransactionHistoryScreen(this.transactions, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Transações'),
        centerTitle: true,
        backgroundColor: Colors.orangeAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TransactionList(transactions),
      ),
    );
  }
}

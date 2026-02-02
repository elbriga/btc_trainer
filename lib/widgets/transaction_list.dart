import 'package:flutter/material.dart';

import '/models/transaction_data.dart';
import '/widgets/transaction_card.dart';

class TransactionList extends StatelessWidget {
  final List<TransactionData> transactions;

  const TransactionList(this.transactions, {super.key});

  @override
  Widget build(BuildContext context) {
    return transactions.isEmpty
        ? const Center(child: Text('Nenhuma transação ainda.'))
        : ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              return TransactionCard(transactions[index]);
            },
          );
  }
}

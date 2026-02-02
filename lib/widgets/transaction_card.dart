import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '/models/currency.dart';
import '/models/transaction_data.dart';

class TransactionCard extends StatefulWidget {
  final TransactionData transaction;

  const TransactionCard(this.transaction, {super.key});

  @override
  TransactionCardState createState() => TransactionCardState();
}

class TransactionCardState extends State<TransactionCard> {
  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final transaction = widget.transaction;
    final isBuy = widget.transaction.type == TransactionType.buy;

    final String amount = CurrencyFormat.format(
      transaction.amount,
      transaction.to,
    );

    final String price = CurrencyFormat.format(
      transaction.price,
      transaction.from,
    );

    final String total = CurrencyFormat.format(
      transaction.amount * transaction.price,
      transaction.from,
    );

    final title = '${transaction.name} $amount';

    // TODO :: data em pt_BR
    final date = DateFormat.yMd().add_jms().format(transaction.timestamp);
    final subtitle = '@ $price / cada\n$date';

    final icon = Icon(
      transaction.from == Currency.heaven
          ? Icons.cloud
          : isBuy
          ? Icons.arrow_upward
          : Icons.arrow_downward,
      color: isBuy ? Colors.green : Colors.red,
    );

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: icon,
        title: Text(title, style: textTheme.displaySmall),
        subtitle: Text(subtitle),
        trailing: Text(total),
        isThreeLine: true,
      ),
    );
  }
}

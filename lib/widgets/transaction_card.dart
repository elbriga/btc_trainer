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

    final isBuy = widget.transaction.type == TransactionType.buy;
    final String currencySymbol;
    final String totalCurrencySymbol;

    int decimal = 8;
    if (widget.transaction.to == Currency.btc) {
      currencySymbol = 'BTC';
      totalCurrencySymbol = '\$';
    } else if (widget.transaction.to == Currency.usd) {
      currencySymbol = 'USD';
      totalCurrencySymbol = '\$';
      decimal = 2;
    } else {
      currencySymbol = 'BRL';
      totalCurrencySymbol = 'R\$';
      decimal = 2;
    }

    final type = widget.transaction.from == Currency.heaven
        ? 'Ganhou'
        : isBuy
        ? 'Comprou'
        : 'Vendeu';
    final amount = widget.transaction.amount.toStringAsFixed(decimal);
    final title = '$type $amount $currencySymbol';

    final price = widget.transaction.price.toStringAsFixed(2);
    final date = DateFormat.yMd().add_jms().format(
      widget.transaction.timestamp,
    );
    final subtitle = '@ $totalCurrencySymbol $price / cada\n$date';

    final totVal = (widget.transaction.amount * widget.transaction.price)
        .toStringAsFixed(2);
    final total = 'Total: $totalCurrencySymbol $totVal';

    final icon = Icon(
      widget.transaction.from == Currency.heaven
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

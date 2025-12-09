import 'package:flutter/material.dart';

class BuySellDialog extends StatefulWidget {
  final bool isBuy;
  final Function(double) onSubmit;
  final double balance;
  final double btcPrice;

  const BuySellDialog({
    super.key,
    required this.isBuy,
    required this.onSubmit,
    required this.balance,
    required this.btcPrice,
  });

  @override
  _BuySellDialogState createState() => _BuySellDialogState();
}

class _BuySellDialogState extends State<BuySellDialog> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final title = widget.isBuy ? 'Buy BTC' : 'Sell BTC';
    final balanceText = widget.isBuy
        ? 'USD Balance: \$${widget.balance.toStringAsFixed(2)}'
        : 'BTC Balance: ${widget.balance.toStringAsFixed(8)} BTC';
    final hintText = widget.isBuy ? 'Amount in USD' : 'Amount in BTC';

    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(balanceText),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: hintText,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          child: const Text('Confirm'),
          onPressed: () {
            final amount = double.tryParse(_controller.text);
            if (amount != null && amount > 0 && amount <= widget.balance) {
              widget.onSubmit(amount);
              Navigator.of(context).pop();
            } else {
              // Optional: Show an error message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invalid or insufficient amount')),
              );
            }
          },
        ),
      ],
    );
  }
}

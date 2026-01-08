import 'package:btc_trainer/models/currency.dart';
import 'package:flutter/material.dart';

class BuySellDialog extends StatefulWidget {
  final bool isBuy;
  final Function(double) onSubmit;
  final double balance;
  final double price;
  final Currency from;
  final Currency to;

  const BuySellDialog({
    super.key,
    required this.isBuy,
    required this.onSubmit,
    required this.balance,
    required this.price,
    required this.from,
    required this.to,
  });

  @override
  _BuySellDialogState createState() => _BuySellDialogState();
}

class _BuySellDialogState extends State<BuySellDialog> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final title = widget.isBuy
        ? 'Comprar ${widget.to.toString().split('.').last.toUpperCase()}'
        : 'Vender ${widget.from.toString().split('.').last.toUpperCase()}';
    final balanceText =
        'Saldo em ${widget.from.toString().split('.').last.toUpperCase()}: ${widget.balance.toStringAsFixed(widget.from == Currency.btc ? 8 : 2)}';
    final hintText =
        'Quantidade em ${widget.from.toString().split('.').last.toUpperCase()}';

    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(balanceText),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              TextButton(
                child: const Text('Total'),
                onPressed: () {
                  setState(() {
                    _controller.text = widget.balance.toString();
                    _controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: _controller.text.length),
                    );
                  });
                },
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          child: const Text('Cancelar'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          child: const Text('Confirmar'),
          onPressed: () {
            final amount = double.tryParse(_controller.text);
            if (amount != null && amount > 0 && amount <= widget.balance) {
              widget.onSubmit(amount);
              Navigator.of(context).pop();
            } else {
              // Optional: Show an error message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Valor inválido ou insuficiente')),
              );
            }
          },
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

class BuySellUsdDialog extends StatefulWidget {
  final bool isBuy;
  final Function(double) onSubmit;
  final double balance;
  final double usdBrlPrice;

  const BuySellUsdDialog({
    super.key,
    required this.isBuy,
    required this.onSubmit,
    required this.balance,
    required this.usdBrlPrice,
  });

  @override
  _BuySellUsdDialogState createState() => _BuySellUsdDialogState();
}

class _BuySellUsdDialogState extends State<BuySellUsdDialog> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final title = widget.isBuy ? 'Comprar USD' : 'Vender USD';
    final balanceText = widget.isBuy
        ? 'Saldo em BRL: R\$${widget.balance.toStringAsFixed(2)}'
        : 'Saldo em USD: \$${widget.balance.toStringAsFixed(2)}';
    final hintText =
        widget.isBuy ? 'Quantidade em BRL' : 'Quantidade em USD';

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
                    _controller.text = widget.balance.toStringAsFixed(2);
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Valor inválido ou insuficiente')),
              );
            }
          },
        ),
      ],
    );
  }
}

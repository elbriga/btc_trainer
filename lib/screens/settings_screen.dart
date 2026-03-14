import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/viewmodels/wallet_viewmodel.dart';
import '/services/firebase_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _processing = false;
  int _totTxs = 0;

  _SettingsScreenState() {
    _loadData();
  }

  Future _loadData() async {
    final user = FirebaseHelper.instance.currentUser;
    List txs = [];
    if (user != null) {
      txs = await FirebaseHelper.instance.getTransactions();
    } else {
      // TODO ::
    }

    setState(() {
      _totTxs = txs.length;
    });
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseHelper.instance.signOut();
    if (context.mounted) {
      final walletViewModel = Provider.of<WalletViewModel>(
        context,
        listen: false,
      );
      await walletViewModel.initialize();
      if (context.mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseHelper.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações da Conta')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: _processing
                ? CircularProgressIndicator()
                : Column(
                    spacing: 20,
                    children: [
                      if (user != null) ...[
                        Text('Logado como: ${user.email}'),
                        ElevatedButton(
                          onPressed: () => _signOut(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade100,
                          ),
                          child: const Text(
                            'Sair / Logout',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                        const Divider(),
                      ],
                      Text('Transações exibidas: $_totTxs'),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

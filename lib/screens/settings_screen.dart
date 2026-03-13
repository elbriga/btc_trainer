import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import '/viewmodels/wallet_viewmodel.dart';
import '/services/database_helper.dart';
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
    List txs;
    if (user != null) {
      txs = await FirebaseHelper.instance.getTransactions();
    } else {
      txs = await DatabaseHelper.instance.getTransactions();
    }

    setState(() {
      _totTxs = txs.length;
    });
  }

  Future _backup() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'btc_trainer.db');

    SharePlus.instance.share(ShareParams(files: [XFile(path)]));
  }

  Future _restore(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.single.path == null) {
      return;
    }

    setState(() {
      _processing = true;
    });

    try {
      final WalletViewModel? walletViewModel = context.mounted
          ? Provider.of<WalletViewModel>(context, listen: false)
          : null;

      await DatabaseHelper.instance.restore(
        result.files.single.path!,
        onRestored: walletViewModel?.initialize,
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Base restaurada!')));

      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() {
        _processing = false;
      });
    }
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseHelper.instance.signOut();
    if (context.mounted) {
      final walletViewModel = Provider.of<WalletViewModel>(context, listen: false);
      await walletViewModel.initialize();
      Navigator.pop(context);
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
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade100),
                          child: const Text('Sair / Logout', style: TextStyle(color: Colors.red)),
                        ),
                        const Divider(),
                      ],
                      ElevatedButton(
                        onPressed: _backup,
                        child: const Text('Download Local Database (Backup)'),
                      ),
                      ElevatedButton(
                        onPressed: () => _restore(context),
                        child: const Text('Restore Local Database'),
                      ),
                      Text('Transações exibidas: $_totTxs'),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

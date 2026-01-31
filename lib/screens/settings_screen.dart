import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import 'package:btc_trainer/services/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _processing = false;

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
      await DatabaseHelper.instance.restore(result.files.single.path!);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Base restaurada!')));
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

  @override
  Widget build(BuildContext context) {
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
                      ElevatedButton(
                        onPressed: _backup,
                        child: const Text('Download Database'),
                      ),
                      ElevatedButton(
                        onPressed: () => _restore(context),
                        child: const Text('Restore Database'),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
